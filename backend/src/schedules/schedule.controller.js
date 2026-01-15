// backend/schedules/schedule.controller.js
// Water schedule APIs (and notifications)

import prisma from "../prisma.js";
import fcmService from "../notifications/fcmservice.js";

// POST /schedules
export async function createSchedule(req, res) {
  const { ward, affectedAreas, startTime, endTime, notifyResidents, supplyDate } = req.body || {};
  const userId = req.auth?.sub;

  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const user = await prisma.user.findUnique({ where: { id: Number(userId) } });
  if (!user) return res.status(401).json({ error: "Unauthorized" });

  if (!["Ward Admin", "ward_admin", "WardAdmin"].includes(user.role)) {
    return res.status(403).json({ error: "Only Ward Admin can create schedules" });
  }

  if (!ward || !startTime || !endTime || !supplyDate) {
    return res.status(400).json({ error: "Ward, supplyDate, startTime, and endTime are required" });
  }

  try {
    const schedule = await prisma.waterSchedule.create({
      data: {
        ward,
        affectedAreas: affectedAreas || "",
        supplyDate: new Date(supplyDate),
        startTime,
        endTime,
        notifyResidents: !!notifyResidents,
        createdBy: Number(userId),
      },
    });

    const notificationResults = { push: { residents: null, vendors: null }, inApp: null };

    // If admin checked "notify residents", send push + save in-app
    if (notifyResidents) {
      const title = "Water Supply Schedule";
      const body = affectedAreas
        ? `Water supply scheduled for ${ward} (${affectedAreas}) on ${new Date(supplyDate).toLocaleDateString()} from ${startTime} to ${endTime}`
        : `Water supply scheduled for ${ward} on ${new Date(supplyDate).toLocaleDateString()} from ${startTime} to ${endTime}`;

      const data = {
        screen: "schedule",
        scheduleId: String(schedule.id),
        ward,
        affectedAreas: affectedAreas || "",
        date: String(supplyDate),
        startTime,
        endTime,
      };

      // Residents of that ward only
      const wardTopic = fcmService.wardToTopic(ward);
      const residentPush = await fcmService.sendToTopic(wardTopic, title, body, data);

      // All vendors
      const vendorPush = await fcmService.sendToTopic("all_vendors", title, body, data);

      notificationResults.push = { residents: residentPush, vendors: vendorPush };

      // In-app notification stored in DB (ward-specific)
      const inApp = await prisma.notification.create({
        data: { ward, title, message: body },
      });

      notificationResults.inApp = inApp;
    }

    return res.status(201).json({
      message: "Schedule created successfully",
      schedule,
      notifications: notificationResults,
    });
  } catch (e) {
    console.error("Schedule creation error:", e);
    return res.status(500).json({ error: "Failed to create schedule" });
  }
}

// GET /schedules
export async function getSchedules(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const user = await prisma.user.findUnique({
      where: { id: Number(userId) },
      select: { role: true, ward: true },
    });

    if (!user) return res.status(401).json({ error: "User not found" });

    if (["Ward Admin", "ward_admin", "WardAdmin"].includes(user.role)) {
      const schedules = await prisma.waterSchedule.findMany({
        where: { createdBy: Number(userId) },
        orderBy: { supplyDate: "desc" },
      });
      return res.json(schedules);
    }

    if (["Vendor", "vendor"].includes(user.role)) {
      const schedules = await prisma.waterSchedule.findMany({
        orderBy: { supplyDate: "desc" },
      });
      return res.json(schedules);
    }

    // Resident
    if (!user.ward) return res.json([]);
    const schedules = await prisma.waterSchedule.findMany({
      where: { ward: user.ward },
      orderBy: { supplyDate: "desc" },
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
    const schedule = await prisma.waterSchedule.findUnique({ where: { id: Number(id) } });
    if (!schedule) return res.status(404).json({ error: "Schedule not found" });
    return res.json(schedule);
  } catch (e) {
    console.error("Get schedule error:", e);
    return res.status(500).json({ error: "Failed to get schedule" });
  }
}

// DELETE /schedules/:id
export async function deleteSchedule(req, res) {
  const userId = req.auth?.sub;
  const { id } = req.params;

  const user = await prisma.user.findUnique({ where: { id: Number(userId) } });
  if (!user || !["Ward Admin", "ward_admin", "WardAdmin"].includes(user.role)) {
    return res.status(403).json({ error: "Only Ward Admin can delete schedules" });
  }

  try {
    const schedule = await prisma.waterSchedule.findUnique({ where: { id: Number(id) } });
    if (!schedule) return res.status(404).json({ error: "Schedule not found" });

    if (schedule.createdBy !== Number(userId)) {
      return res.status(403).json({ error: "You can only delete your own schedules" });
    }

    await prisma.waterSchedule.delete({ where: { id: Number(id) } });
    return res.json({ message: "Schedule deleted successfully" });
  } catch (e) {
    console.error("Delete schedule error:", e);
    return res.status(500).json({ error: "Failed to delete schedule" });
  }
}