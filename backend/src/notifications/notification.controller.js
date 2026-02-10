// src/notifications/notification.controller.js
import prisma from "../prisma.js";
import fcmService from "./fcmservice.js";

/*
  GET /notifications
  - ERD way: load notifications that were delivered to current user (via NotificationRecipient)
*/
export async function getNotifications(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const rows = await prisma.notificationRecipient.findMany({
      where: { userId },
      orderBy: { notification: { createdAt: "desc" } },
      include: {
        notification: {
          include: {
            sender: { select: { id: true, name: true, role: true } },
          },
        },
      },
    });

    // Student comment: return in simple format for flutter
    const result = rows.map((r) => ({
      isRead: r.isRead,
      deliveredAt: r.deliveredAt,
      notification: r.notification,
    }));

    return res.json(result);
  } catch (e) {
    console.error("getNotifications error:", e);
    return res.status(500).json({ error: "Failed to fetch notifications" });
  }
}

/*
  POST /notifications
  - Only ward admin can create
  - ERD way: create Notification + NotificationRecipient rows
  - We still use topic push (easy) but DB records are per token (recipientId = token_id)
*/
export async function createNotification(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const me = await prisma.user.findUnique({
    where: { id: userId },
    select: { role: true, wardId: true },
  });

  if (!me) return res.status(401).json({ error: "User not found" });
  if (me.role !== "WARD_ADMIN") {
    return res.status(403).json({ error: "Only Ward Admin can create notifications" });
  }

  const {
    title,
    message,
    recipient = "resident",   // resident | vendor | both
    wardId,                   // optional: ward id
    push = true,
    type = "GENERAL",
  } = req.body || {};

  if (!title || !message) {
    return res.status(400).json({ error: "title and message are required" });
  }

  try {
    // Student comment: create notification row
    const notif = await prisma.notification.create({
      data: {
        senderId: userId,
        senderRole: me.role,
        title,
        message,
        type: String(type).toUpperCase(),
      },
    });

    // Student comment: choose target users
    const targetWardId = wardId != null ? Number(wardId) : me.wardId;

    const recipientLower = String(recipient).toLowerCase().trim();
    const roleFilter = [];

    if (recipientLower === "resident") roleFilter.push("RESIDENT");
    else if (recipientLower === "vendor") roleFilter.push("VENDOR");
    else if (recipientLower === "both") roleFilter.push("RESIDENT", "VENDOR");
    else roleFilter.push("RESIDENT");

    // Student comment: find users to receive notice
    const users = await prisma.user.findMany({
      where: {
        role: { in: roleFilter },
        ...(targetWardId ? { wardId: targetWardId } : {}),
      },
      select: { id: true },
    });

    // Student comment: get all fcm tokens for those users
    const userIds = users.map((u) => u.id);

    const tokens = await prisma.fcmToken.findMany({
      where: { userId: { in: userIds } },
      select: { id: true, userId: true, token: true },
    });

    // Student comment: create recipient rows (notification_id + token_id)
    // (If user has no token, they won't get a recipient row. In your app login saves token so OK.)
    if (tokens.length > 0) {
      await prisma.notificationRecipient.createMany({
        data: tokens.map((t) => ({
          notificationId: notif.id,
          recipientId: t.id,  // token_id
          userId: t.userId,
          deliveredAt: push ? new Date() : null,
          isRead: false,
        })),
        skipDuplicates: true,
      });
    }

    // Student comment: send push notification (simple: topic)
    // You can improve later by sending directly to tokens list.
    let pushResult = { success: false, message: "push disabled" };

    if (push) {
      try {
        const data = {
          screen: "notifications",
          notificationId: String(notif.id),
          type: String(type),
        };

        const tasks = [];

        if (roleFilter.includes("RESIDENT")) {
          tasks.push(fcmService.sendToTopic("all_residents", title, message, data));
        }
        if (roleFilter.includes("VENDOR")) {
          tasks.push(fcmService.sendToTopic("all_vendors", title, message, data));
        }

        const results = await Promise.all(tasks);
        pushResult = { success: true, results };
      } catch (e) {
        pushResult = { success: false, error: e.message };
      }
    }

    return res.status(201).json({
      message: "Notification created",
      saved: notif,
      push: pushResult,
    });
  } catch (e) {
    console.error("createNotification error:", e);
    return res.status(500).json({ error: "Failed to create notification" });
  }
}