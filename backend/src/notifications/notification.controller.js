import prisma from "../prisma.js";
import fcmService from "./fcmservice.js";

const GLOBAL_WARD = "ALL";
const VENDOR_BUCKET = "ALL_VENDORS";

export async function getNotifications(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const user = await prisma.user.findUnique({
    where: { id: Number(userId) },
    select: { role: true, ward: true },
  });
  if (!user) return res.status(401).json({ error: "User not found" });

  const role = String(user.role || "").toLowerCase().trim();
  let where = {};


  if (role === "resident") {
    if (user.ward && user.ward.trim()) {
      where = { ward: { in: [user.ward.trim(), GLOBAL_WARD] } };
    } else {
      where = { ward: GLOBAL_WARD };
    }
  }
  // Vendor see everything
  else if (role === "vendor") {
    where = {};
  }
  // Ward Admin  see everything
  else if (["ward admin", "ward_admin", "wardadmin"].includes(role)) {
    where = {};
  }

  const notifications = await prisma.notification.findMany({
    where,
    orderBy: { createdAt: "desc" },
  });

  return res.json(notifications);
}

export async function createNotification(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const user = await prisma.user.findUnique({
    where: { id: Number(userId) },
    select: { role: true },
  });
  if (!user) return res.status(401).json({ error: "User not found" });

  const role = String(user.role || "").toLowerCase().trim();
  if (!["ward admin", "ward_admin", "wardadmin"].includes(role)) {
    return res.status(403).json({ error: "Only Ward Admin can create notifications" });
  }

  const {
    ward = GLOBAL_WARD,      // Flutter can send ALL
    title,
    message,
    recipient = "resident",
    push = true,
    highPriority = false,
    type = "general",
  } = req.body || {};

  if (!title || !message) {
    return res.status(400).json({ error: "title and message are required" });
  }

  const normalizedWard = String(ward).trim() || GLOBAL_WARD;
  const normalizedRecipient = String(recipient).toLowerCase().trim();

  // SAVE ONLY ONE DB ROW

  const wardForDb = normalizedRecipient === "vendor" ? VENDOR_BUCKET : normalizedWard;

  const notif = await prisma.notification.create({
    data: { ward: wardForDb, title, message },
  });

  //  vendors should receive everything

  let pushResult = { success: false, message: "push disabled" };

  if (push) {
    try {
      const data = {
        screen: "notifications",
        ward: wardForDb,
        type: String(type),
        highPriority: String(!!highPriority),
        notificationId: String(notif.id),
      };

      const tasks = [];

      // Residents push only if recipient is resident or both
      if (normalizedRecipient === "resident" || normalizedRecipient === "both") {
        if (normalizedWard === GLOBAL_WARD) {
          tasks.push(fcmService.sendToTopic("all_residents", title, message, data));
        } else {
          tasks.push(fcmService.sendToTopic(fcmService.wardToTopic(normalizedWard), title, message, data));
        }
      }

      //  Vendors ALWAYS get it even resident-only
      tasks.push(fcmService.sendToTopic("all_vendors", title, message, data));

      const results = await Promise.all(tasks);
      pushResult = { success: true, results };
    } catch (e) {
      pushResult = { success: false, error: e.message };
    }
  }

  return res.status(201).json({
    message: "Notice created",
    saved: notif,
    push: pushResult,
  });
}