import prisma from "../../prisma.js";
import fcmService from "../notifications/fcmservice.js";

function normalizeRole(role) {
  return String(role || "").trim().toUpperCase().replace(/[\s-]+/g, "_");
}

// authenticateFirebase sets req.auth.sub = DB user id
async function getCurrentUser(req) {
  const userId = Number(req.auth?.sub);
  if (!userId) return null;
  return prisma.user.findUnique({ where: { id: userId } });
}

// wardName comes from Flutter like "Kathmandu Ward 4"
async function getOrCreateWardByName(wardName) {
  const name = String(wardName || "").trim();
  if (!name) return null;

  let ward = await prisma.ward.findFirst({ where: { wardName: name } });
  if (!ward) ward = await prisma.ward.create({ data: { wardName: name } });
  return ward;
}

// supplyDate = "YYYY-MM-DD", time = "HH:mm" (24h)
function combineDateAndTime(supplyDate, timeStr) {
  const base = new Date(supplyDate);
  if (isNaN(base.getTime())) return null;

  const parts = String(timeStr || "").trim().split(":");
  if (parts.length < 2) return null;

  const h = Number(parts[0]);
  const m = Number(parts[1]);
  const s = parts.length >= 3 ? Number(parts[2]) : 0;

  if (![h, m, s].every(Number.isFinite)) return null;

  base.setHours(h, m, s, 0);
  return base;
}

// helpers for notification page (in-app recipients)
async function getLatestTokenOrCreateInAppToken(userId) {
  const existing = await prisma.fcmToken.findFirst({
    where: { userId },
    orderBy: { updatedAt: "desc" },
    select: { id: true, userId: true },
  });
  if (existing) return existing;

  const dummyToken = `inapp_user_${userId}`;

  const tok = await prisma.fcmToken.upsert({
    where: { token: dummyToken },
    update: { userId, deviceInfo: "inapp" },
    create: { userId, token: dummyToken, deviceInfo: "inapp" },
    select: { id: true, userId: true },
  });

  return tok;
}

async function createRecipientsForUsers(notificationId, userIds) {
  const deliveredAt = new Date();
  const rows = [];

  for (const uid of userIds) {
    const tok = await getLatestTokenOrCreateInAppToken(uid);
    rows.push({
      notificationId,
      recipientId: tok.id,
      userId: uid,
      deliveredAt,
      isRead: false,
    });
  }

  if (rows.length === 0) return 0;

  const result = await prisma.notificationRecipient.createMany({
    data: rows,
    skipDuplicates: true,
  });

  return result.count;
}

// POST /schedules
export async function createSchedule(req, res) {
  const body = req.body || {};

  try {
    const userId = Number(req.auth?.sub);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const me = await prisma.user.findUnique({ where: { id: userId } });
    if (!me) return res.status(401).json({ error: "Unauthorized" });

    // only Ward Admin can post schedules
    if (me.role !== "WARD_ADMIN") {
      return res.status(403).json({ error: "Only Ward Admin can create schedules" });
    }

    const { wardName, ward, supplyDate, startTime, endTime, notifyResidents, affectedAreas } = body;

    if (!wardName && !ward) {
      return res.status(400).json({ error: "wardName (or ward) is required (e.g. Kathmandu Ward 4)" });
    }
    if (!supplyDate || !startTime || !endTime) {
      return res.status(400).json({ error: "supplyDate, startTime, endTime are required" });
    }

    const wardRow = await getOrCreateWardByName(wardName ?? ward);
    if (!wardRow) return res.status(400).json({ error: "Invalid wardName" });

    const scheduleDate = new Date(supplyDate);
    if (isNaN(scheduleDate.getTime())) {
      return res.status(400).json({ error: "Invalid supplyDate. Use YYYY-MM-DD." });
    }

    const startDT = combineDateAndTime(supplyDate, startTime);
    const endDT = combineDateAndTime(supplyDate, endTime);

    if (!startDT || !endDT) {
      return res.status(400).json({ error: "Invalid startTime/endTime. Use HH:mm (24-hour)." });
    }

    // save which ward admin created it
    const schedule = await prisma.schedule.create({
      data: {
        wardId: wardRow.id,
        createdById: me.id,
        scheduleDate,
        startTime: startDT,
        endTime: endDT,
      },
      include: {
        ward: true,
        createdBy: { select: { id: true, name: true, email: true, role: true } },
      },
    });

    const notificationResults = { push: { residents: null, vendors: null }, inApp: null, recipients: null };

    if (notifyResidents) {
      const title = "Water Supply Schedule";
      const dateStr = scheduleDate.toLocaleDateString();

      const msg = affectedAreas
        ? `Water supply scheduled for ${wardRow.wardName} (${affectedAreas}) on ${dateStr} from ${startTime} to ${endTime}`
        : `Water supply scheduled for ${wardRow.wardName} on ${dateStr} from ${startTime} to ${endTime}`;

      //  Save in DB
      const notif = await prisma.notification.create({
        data: {
          senderId: me.id,
          senderRole: me.role,
          title,
          message: msg,
          type: "SCHEDULE",
        },
      });
      notificationResults.inApp = notif;

      // Create recipients for in-app screen
      const residentUsers = await prisma.user.findMany({
        where: { role: "RESIDENT", wardId: wardRow.id },
        select: { id: true },
      });
      const vendorUsers = await prisma.user.findMany({
        where: { role: "VENDOR" },
        select: { id: true },
      });

      const rCount = await createRecipientsForUsers(notif.id, residentUsers.map((u) => u.id));
      const vCount = await createRecipientsForUsers(notif.id, vendorUsers.map((u) => u.id));

      notificationResults.recipients = { residents: rCount, vendors: vCount };

      // Push topic
      const data = {
        screen: "schedule",
        scheduleId: String(schedule.id),
        wardId: String(wardRow.id),
        wardName: String(wardRow.wardName),
      };

      const wardTopic = fcmService.wardToTopic(wardRow.wardName);
      console.log("[Schedule] wardTopic =", wardTopic);

      notificationResults.push.residents = await fcmService.sendToTopic(wardTopic, title, msg, data);
      notificationResults.push.vendors = await fcmService.sendToTopic("all_vendors", title, msg, data);
    }

    return res.status(201).json({
      message: "Schedule created successfully",
      schedule,
      ward: { id: wardRow.id, name: wardRow.wardName },
      notifications: notificationResults,
    });
  } catch (e) {
    console.error("Schedule creation error:", e);
    return res.status(500).json({ error: "Failed to create schedule" });
  }
}

// GET /schedules
export async function getSchedules(req, res) {
  try {
    const schedules = await prisma.schedule.findMany({
      orderBy: { scheduleDate: "desc" },
      include: {
        ward: true,
        createdBy: { select: { id: true, name: true, email: true, role: true } }, // IMPORTANT
      },
    });
    return res.json(schedules);
  } catch (e) {
    console.error("Get schedules error:", e);
    return res.status(500).json({ error: "Failed to get schedules" });
  }
}

// GET /schedules/:id
export async function getSchedule(req, res) {
  const { id } = req.params;
  try {
    const schedule = await prisma.schedule.findUnique({
      where: { id: Number(id) },
      include: {
        ward: true,
        createdBy: { select: { id: true, name: true, email: true, role: true } }, // IMPORTANT
      },
    });
    if (!schedule) return res.status(404).json({ error: "Schedule not found" });
    return res.json(schedule);
  } catch (e) {
    console.error("Get schedule error:", e);
    return res.status(500).json({ error: "Failed to get schedule" });
  }
}

// DELETE /schedules/:id
export async function deleteSchedule(req, res) {
  const { id } = req.params;

  try {
    const user = await getCurrentUser(req);
    if (!user) return res.status(401).json({ error: "Unauthorized" });

    if (normalizeRole(user.role) !== "WARD_ADMIN") {
      return res.status(403).json({ error: "Only Ward Admin can delete schedules" });
    }

    await prisma.schedule.delete({ where: { id: Number(id) } });
    return res.json({ message: "Schedule deleted successfully" });
  } catch (e) {
    console.error("Delete schedule error:", e);
    return res.status(500).json({ error: "Failed to delete schedule" });
  }
}