import prisma from "../../prisma.js";
import config from "../../config/config.js";
import fcmService from "../notifications/fcmservice.js";
import fs from "fs/promises";
import path from "path";

function normalizeRole(role) {
  return String(role || "").trim().toUpperCase().replace(/[\s-]+/g, "_");
}

async function getCurrentUser(req) {
  const userId = Number(req.auth?.sub);
  if (!userId) return null;
  return prisma.user.findUnique({ where: { id: userId } });
}

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

function parseBool(v, def = true) {
  if (v == null) return def;
  const s = String(v).trim().toLowerCase();
  if (["true", "1", "yes", "y"].includes(s)) return true;
  if (["false", "0", "no", "n"].includes(s)) return false;
  return def;
}

// notification helpers

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

/**
 * Build a URL that works on emulator + real phone.
 * Prefer PUBLIC_BASE_URL from env (config.publicBaseUrl).
 *
 *
 *   PUBLIC_BASE_URL=http://192.168.1.10:3000
 *   relativePath=/uploads/schedules/x.pdf
 *   => http://192.168.1.10:3000/uploads/schedules/x.pdf
 */
function buildAbsoluteUrl(req, relativePath) {
  const rel = String(relativePath || "");
  const cleanRel = rel.startsWith("/") ? rel : `/${rel}`;

  // Prefer env PUBLIC_BASE_URL
  if (config.publicBaseUrl) {
    return `${config.publicBaseUrl}${cleanRel}`;
  }

  // fallback (can break across devices)
  const host = req.get("host");
  const proto = req.headers["x-forwarded-proto"] || req.protocol || "http";
  return `${proto}://${host}${cleanRel}`;
}

async function saveUploadedFileToDisk(file) {
  const uploadDir = path.join(process.cwd(), "uploads", "schedules");
  await fs.mkdir(uploadDir, { recursive: true });

  const safeName = String(file.originalname || "upload")
    .replace(/[^\w.\-]+/g, "_")
    .slice(0, 200);

  const finalName = `${Date.now()}_${safeName}`;
  const fullPath = path.join(uploadDir, finalName);

  await fs.writeFile(fullPath, file.buffer);

  const fileUrl = `/uploads/schedules/${finalName}`;
  return { fullPath, fileUrl, finalName };
}

// CSV parser

function parseCsvToObjects(csvText) {
  const text = String(csvText || "")
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n")
    .trim();
  if (!text) return [];

  const lines = text.split("\n").filter((l) => l.trim() !== "");
  if (lines.length === 0) return [];

  const splitLine = (line) => {
    const out = [];
    let cur = "";
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const ch = line[i];

      if (ch === '"') {
        if (inQuotes && line[i + 1] === '"') {
          cur += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (ch === "," && !inQuotes) {
        out.push(cur.trim());
        cur = "";
        continue;
      }

      cur += ch;
    }
    out.push(cur.trim());
    return out;
  };

  const headers = splitLine(lines[0]).map((h) => h.replace(/^"|"$/g, "").trim());
  const rows = [];

  for (let i = 1; i < lines.length; i++) {
    const cols = splitLine(lines[i]);
    const obj = {};
    for (let j = 0; j < headers.length; j++) {
      const key = headers[j];
      obj[key] = (cols[j] ?? "").replace(/^"|"$/g, "").trim();
    }
    rows.push(obj);
  }

  return rows;
}



// POST /schedules
export async function createSchedule(req, res) {
  const body = req.body || {};

  try {
    const userId = Number(req.auth?.sub);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const me = await prisma.user.findUnique({ where: { id: userId } });
    if (!me) return res.status(401).json({ error: "Unauthorized" });

    if (normalizeRole(me.role) !== "WARD_ADMIN") {
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

    let notifications = null;

    if (parseBool(notifyResidents, true)) {
      const title = "Water Supply Schedule";
      const dateStr = scheduleDate.toLocaleDateString();

      const msg = affectedAreas
        ? `Water supply scheduled for ${wardRow.wardName} (${affectedAreas}) on ${dateStr} from ${startTime} to ${endTime}`
        : `Water supply scheduled for ${wardRow.wardName} on ${dateStr} from ${startTime} to ${endTime}`;

      const notif = await prisma.notification.create({
        data: {
          senderId: me.id,
          senderRole: me.role,
          title,
          message: msg,
          type: "SCHEDULE",
        },
      });

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

      const data = {
        screen: "schedule",
        scheduleId: String(schedule.id),
        wardId: String(wardRow.id),
        wardName: String(wardRow.wardName),
      };

      const wardTopic = fcmService.wardToTopic(wardRow.wardName);

      const pushResidents = await fcmService.sendToTopic(wardTopic, title, msg, data);
      const pushVendors = await fcmService.sendToTopic("all_vendors", title, msg, data);

      notifications = {
        inAppNotificationId: notif.id,
        recipients: { residents: rCount, vendors: vCount },
        push: { residents: pushResidents, vendors: pushVendors },
      };
    }

    return res.status(201).json({
      message: "Schedule created successfully",
      schedule,
      ward: { id: wardRow.id, name: wardRow.wardName },
      notifications,
    });
  } catch (e) {
    console.error("Schedule creation error:", e);
    return res.status(500).json({ error: "Failed to create schedule" });
  }
}

//  POST /schedules/upload
export async function uploadScheduleFile(req, res) {
  try {
    const me = await getCurrentUser(req);
    if (!me) return res.status(401).json({ error: "Unauthorized" });

    if (normalizeRole(me.role) !== "WARD_ADMIN") {
      return res.status(403).json({ error: "Only Ward Admin can upload schedules" });
    }

    const notifyResidents = parseBool(req.body?.notifyResidents, true);

    if (!req.file) {
      return res.status(400).json({
        error: "No file uploaded (field name must be 'file' in multipart/form-data).",
      });
    }

    const saved = await saveUploadedFileToDisk(req.file);
    const original = req.file.originalname || "";
    const lower = original.toLowerCase();

    // uses PUBLIC_BASE_URL if set
    const publicUrl = buildAbsoluteUrl(req, saved.fileUrl);

    const wardNameFromBody = req.body?.wardName || req.body?.ward;
    let wardRow = null;

    if (wardNameFromBody) {
      wardRow = await getOrCreateWardByName(wardNameFromBody);
    } else if (me.wardId) {
      wardRow = await prisma.ward.findUnique({ where: { id: me.wardId } });
    }

    // PDF: create notification with file link
    if (lower.endsWith(".pdf") || req.file.mimetype === "application/pdf") {
      let notifications = null;

      if (notifyResidents) {
        const title = "Water Supply Schedule File";
        const wardLabel = wardRow?.wardName ? ` for ${wardRow.wardName}` : "";
        const msg = `New schedule PDF uploaded${wardLabel}. Download: ${publicUrl}`;

        const notif = await prisma.notification.create({
          data: {
            senderId: me.id,
            senderRole: me.role,
            title,
            message: msg,
            type: "SCHEDULE",
          },
        });

        const residentUsers = await prisma.user.findMany({
          where: wardRow ? { role: "RESIDENT", wardId: wardRow.id } : { role: "RESIDENT" },
          select: { id: true },
        });

        const vendorUsers = await prisma.user.findMany({
          where: { role: "VENDOR" },
          select: { id: true },
        });

        const rCount = await createRecipientsForUsers(notif.id, residentUsers.map((u) => u.id));
        const vCount = await createRecipientsForUsers(notif.id, vendorUsers.map((u) => u.id));

        const data = {
          screen: "schedule",
          fileUrl: publicUrl,
          wardId: wardRow ? String(wardRow.id) : "",
          wardName: wardRow ? String(wardRow.wardName) : "",
        };

        const pushResidents = wardRow
          ? await fcmService.sendToTopic(fcmService.wardToTopic(wardRow.wardName), title, msg, data)
          : null;

        const pushVendors = await fcmService.sendToTopic("all_vendors", title, msg, data);

        notifications = {
          inAppNotificationId: notif.id,
          recipients: { residents: rCount, vendors: vCount },
          push: { residents: pushResidents, vendors: pushVendors },
        };
      }

      return res.status(201).json({
        message: "PDF uploaded successfully",
        file: {
          name: original,
          mime: req.file.mimetype,
          size: req.file.size,
          url: saved.fileUrl,
          publicUrl,
        },
        ward: wardRow ? { id: wardRow.id, name: wardRow.wardName } : null,
        notifyResidents,
        notifications,
      });
    }

    // CSV: parse and create schedules
    const csvText = req.file.buffer?.toString("utf8") ?? "";
    const rows = parseCsvToObjects(csvText);

    if (rows.length === 0) {
      return res.status(400).json({
        error: "CSV is empty/invalid. Required columns: wardName,supplyDate,startTime,endTime (optional: affectedAreas).",
        file: { name: original, publicUrl },
      });
    }

    const created = [];
    const errors = [];

    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];

      const wardName = r.wardName || r.ward;
      const supplyDate = r.supplyDate || r.date;
      const startTime = r.startTime || r.start;
      const endTime = r.endTime || r.end;
      const affectedAreas = r.affectedAreas || r.areas || "";

      try {
        if (!wardName || !supplyDate || !startTime || !endTime) {
          throw new Error("Missing required columns (wardName, supplyDate, startTime, endTime)");
        }

        const w = await getOrCreateWardByName(wardName);
        if (!w) throw new Error("Invalid wardName");

        const scheduleDate = new Date(supplyDate);
        if (isNaN(scheduleDate.getTime())) throw new Error("Invalid supplyDate (use YYYY-MM-DD)");

        const startDT = combineDateAndTime(supplyDate, startTime);
        const endDT = combineDateAndTime(supplyDate, endTime);
        if (!startDT || !endDT) throw new Error("Invalid startTime/endTime (use HH:mm)");

        const schedule = await prisma.schedule.create({
          data: {
            wardId: w.id,
            createdById: me.id,
            scheduleDate,
            startTime: startDT,
            endTime: endDT,
          },
        });

        if (notifyResidents) {
          const title = "Water Supply Schedule";
          const dateStr = scheduleDate.toLocaleDateString();
          const msg = affectedAreas
            ? `Water supply scheduled for ${w.wardName} (${affectedAreas}) on ${dateStr} from ${startTime} to ${endTime}`
            : `Water supply scheduled for ${w.wardName} on ${dateStr} from ${startTime} to ${endTime}`;

          const notif = await prisma.notification.create({
            data: {
              senderId: me.id,
              senderRole: me.role,
              title,
              message: msg,
              type: "SCHEDULE",
            },
          });

          const residentUsers = await prisma.user.findMany({
            where: { role: "RESIDENT", wardId: w.id },
            select: { id: true },
          });
          const vendorUsers = await prisma.user.findMany({
            where: { role: "VENDOR" },
            select: { id: true },
          });

          await createRecipientsForUsers(notif.id, residentUsers.map((u) => u.id));
          await createRecipientsForUsers(notif.id, vendorUsers.map((u) => u.id));

          const data = {
            screen: "schedule",
            scheduleId: String(schedule.id),
            wardId: String(w.id),
            wardName: String(w.wardName),
          };

          await fcmService.sendToTopic(fcmService.wardToTopic(w.wardName), title, msg, data);
          await fcmService.sendToTopic("all_vendors", title, msg, data);
        }

        created.push({ row: i + 1, scheduleId: schedule.id, wardName: w.wardName });
      } catch (err) {
        errors.push({
          row: i + 1,
          error: err?.message || String(err),
          data: r,
        });
      }
    }

    return res.status(201).json({
      message: "CSV upload processed",
      file: { name: original, publicUrl },
      notifyResidents,
      createdCount: created.length,
      errorCount: errors.length,
      created,
      errors,
    });
  } catch (e) {
    console.error("Schedule upload error:", e);
    return res.status(500).json({ error: "Failed to upload schedule file" });
  }
}

// GET /schedules
export async function getSchedules(req, res) {
  try {
    const schedules = await prisma.schedule.findMany({
      orderBy: { scheduleDate: "desc" },
      include: {
        ward: true,
        createdBy: { select: { id: true, name: true, email: true, role: true } },
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
        createdBy: { select: { id: true, name: true, email: true, role: true } },
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