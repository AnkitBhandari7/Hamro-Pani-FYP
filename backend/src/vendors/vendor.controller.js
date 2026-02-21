import prisma from "../prisma.js";
import fcmService from "../notifications/fcmservice.js";
import fs from "fs";
import path from "path";

const APP_TIMEZONE = process.env.APP_TIMEZONE || "Asia/Kathmandu";

function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

/**
 * STRICT datetime parser:
 * - requires timezone in the string
 * - prevents Node from interpreting "2026-02-19T21:00:00" as server-local and shifting
 */
function parseClientDateTimeOrThrow(raw, fieldName = "dateTime") {
  const s = String(raw || "").trim();
  if (!s) {
    const err = new Error(`${fieldName} is required`);
    err.statusCode = 400;
    throw err;
  }

  const hasTz = /([zZ]|[+\-]\d{2}:\d{2})$/.test(s);
  if (!hasTz) {
    const err = new Error(
      `${fieldName} must include timezone. Send UTC from Flutter using toUtc().toIso8601String(). Received: ${s}`
    );
    err.statusCode = 400;
    throw err;
  }

  const d = new Date(s);
  if (Number.isNaN(d.getTime())) {
    const err = new Error(`Invalid ${fieldName}: ${s}`);
    err.statusCode = 400;
    throw err;
  }
  return d;
}

// For routeDate (yyyy-MM-dd) avoid JS Date UTC parsing issues:
function parseDateOnlyOrDefault(raw) {
  if (!raw) return new Date();
  const s = String(raw).trim();
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
  if (!m) return new Date(raw);
  const y = Number(m[1]);
  const mo = Number(m[2]) - 1;
  const d = Number(m[3]);
  return new Date(y, mo, d); // local midnight
}

function startOfToday() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function isActiveRoute(routeDate) {
  const d = new Date(routeDate);
  const t = startOfToday();
  const tomorrow = new Date(t.getTime() + 24 * 60 * 60 * 1000);
  return d >= t && d < tomorrow;
}

function toTimeLabel(dt) {
  if (!dt) return null;
  const d = new Date(dt);
  let h = d.getHours();
  const m = String(d.getMinutes()).padStart(2, "0");
  const ampm = h >= 12 ? "PM" : "AM";
  h = h % 12;
  if (h === 0) h = 12;
  return `${h}:${m} ${ampm}`;
}

function formatTimeInTz(date, timeZone = APP_TIMEZONE) {
  try {
    return new Intl.DateTimeFormat("en-US", {
      timeZone,
      hour: "2-digit",
      minute: "2-digit",
      hour12: true,
    }).format(date);
  } catch (_) {
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  }
}

async function getVendorByUserId(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, role: true },
  });

  if (!user) return { error: { status: 401, message: "User not found" } };
  if (String(user.role).toUpperCase() !== "VENDOR") {
    return { error: { status: 403, message: "Only vendor can access" } };
  }

  const vendor = await prisma.vendor.findUnique({
    where: { userId },
  });

  if (!vendor) {
    return { error: { status: 403, message: "Vendor profile not found" } };
  }

  return { vendor };
}

// Dashboard sorting helpers
function parseDateTime(raw) {
  if (!raw) return null;
  const d = new Date(raw);
  return Number.isNaN(d.getTime()) ? null : d;
}

function sortRoutesForDashboardUi(list) {
  const statusRank = (s) =>
    String(s || "").toLowerCase().trim() === "active" ? 0 : 1;

  return [...list].sort((a, b) => {
    // Active first
    const sr = statusRank(a.status) - statusRank(b.status);
    if (sr !== 0) return sr;

    // Latest endTime first
    const aEnd = parseDateTime(a.endTime);
    const bEnd = parseDateTime(b.endTime);
    if (aEnd && !bEnd) return -1;
    if (!aEnd && bEnd) return 1;
    if (aEnd && bEnd) {
      const c = bEnd.getTime() - aEnd.getTime();
      if (c !== 0) return c;
    }

    // Latest startTime first
    const aStart = parseDateTime(a.startTime);
    const bStart = parseDateTime(b.startTime);
    if (aStart && !bStart) return -1;
    if (!aStart && bStart) return 1;
    if (aStart && bStart) {
      const c = bStart.getTime() - aStart.getTime();
      if (c !== 0) return c;
    }

    // Latest routeDate first
    const aDate = parseDateTime(a.routeDate);
    const bDate = parseDateTime(b.routeDate);
    if (aDate && !bDate) return -1;
    if (!aDate && bDate) return 1;
    if (aDate && bDate) {
      const c = bDate.getTime() - aDate.getTime();
      if (c !== 0) return c;
    }

    return 0;
  });
}

/**
 *
 * Touch route so it moves to top of dashboard when slot changes.

 */
async function touchRoute(routeId, tx = prisma) {
  await tx.route.update({
    where: { id: routeId },
    data: { updatedAt: new Date() },
    select: { id: true },
  });
}

/*
  GET /vendors/dashboard
   only routes with slots
  orderBy updatedAt desc so recently-changed route comes first
*/
export async function getVendorDashboard(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  try {
    const vendorUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { name: true, profileImageUrl: true },
    });

    const rawRoutes = await prisma.route.findMany({
      where: {
        vendorId: vendor.id,
        slots: { some: {} },
      },
      include: {
        ward: true,
        slots: { orderBy: { startTime: "asc" } },
      },
      take: 50,
      orderBy: { updatedAt: "desc" },
    });

    const mappedRoutes = rawRoutes.map((r) => {
      const slotsTotal = r.slots.reduce((sum, s) => sum + (s.capacity ?? 0), 0);
      const slotsUsed = r.slots.reduce((sum, s) => sum + (s.bookedCount ?? 0), 0);
      const percentBooked = slotsTotal > 0 ? Math.round((slotsUsed / slotsTotal) * 100) : 0;

      const latest = r.slots.length > 0 ? r.slots[r.slots.length - 1] : null;

      return {
        routeId: r.id,
        wardName: r.ward?.wardName ?? "-",
        location: r.location ?? "-",
        routeDate: r.routeDate,
        status: isActiveRoute(r.routeDate) ? "Active" : "Scheduled",

        // Use latest slot's time range
        startTime: latest?.startTime ?? null,
        endTime: latest?.endTime ?? null,
        startTimeLabel: toTimeLabel(latest?.startTime),
        endTimeLabel: toTimeLabel(latest?.endTime),

        slotsTotal,
        slotsUsed,
        percentBooked,
      };
    });

    const routes = sortRoutesForDashboardUi(mappedRoutes).slice(0, 10);

    const rawBookings = await prisma.booking.findMany({
      where: {
        slot: { route: { vendorId: vendor.id } },
        NOT: { status: "CANCELLED" },
      },
      orderBy: { createdAt: "desc" },
      take: 10,
      include: {
        user: { select: { id: true, name: true, phoneNumber: true } },
        slot: {
          include: {
            route: { include: { ward: true } },
          },
        },
      },
    });

    const requests = rawBookings.map((b) => ({
      bookingId: b.id,
      status: b.status,
      createdAt: b.createdAt,
      residentName: b.user?.name ?? "Resident",
      residentPhone: b.user?.phoneNumber ?? "",
      wardName: b.slot?.route?.ward?.wardName ?? "-",
      location: b.slot?.route?.location ?? "-",
      slotStartTime: b.slot?.startTime ?? null,
      slotEndTime: b.slot?.endTime ?? null,
    }));

    const today = startOfToday();
    const todaysJobs = await prisma.booking.count({
      where: {
        createdAt: { gte: today },
        slot: { route: { vendorId: vendor.id } },
        NOT: { status: "CANCELLED" },
      },
    });

    return res.json({
      vendor: {
        id: vendor.id,
        companyName: vendor.companyName ?? "",
        contactName: vendorUser?.name ?? "",
        logoUrl: vendorUser?.profileImageUrl
          ? toAbsoluteUrl(req, vendorUser.profileImageUrl)
          : "",
      },
      stats: {
        todaysJobs,
        successPercent: 0,
        rating: 0,
      },
      routes,
      requests,
    });
  } catch (e) {
    console.error("getVendorDashboard error:", e);
    return res.status(500).json({ error: "Failed to load vendor dashboard" });
  }
}

/*
  POST /vendors/routes
*/
export async function createRoute(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const { wardId, ward, routeDate, location } = req.body || {};

  try {
    let wardRow = null;

    if (wardId != null) {
      wardRow = await prisma.ward.findUnique({ where: { id: Number(wardId) } });
    } else if (typeof ward === "string" && ward.trim()) {
      wardRow = await prisma.ward.findFirst({ where: { wardName: ward.trim() } });
      if (!wardRow) wardRow = await prisma.ward.create({ data: { wardName: ward.trim() } });
    }

    if (!wardRow) return res.status(400).json({ error: "wardId or ward name is required" });

    const d = routeDate ? parseDateOnlyOrDefault(routeDate) : new Date();
    const routeDateOnly = new Date(d.getFullYear(), d.getMonth(), d.getDate());

    const created = await prisma.route.create({
      data: {
        vendorId: vendor.id,
        wardId: wardRow.id,
        routeDate: routeDateOnly,
        location: typeof location === "string" && location.trim() ? location.trim() : null,
      },
      include: { ward: true },
    });

    return res.status(201).json(created);
  } catch (e) {
    console.error("createRoute error:", e);
    return res.status(500).json({ error: "Could not create route" });
  }
}

/*
  GET /vendors/routes/my
*/
export async function getMyRoutes(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  try {
    const routes = await prisma.route.findMany({
      where: { vendorId: vendor.id },
      orderBy: { createdAt: "desc" },
      include: { ward: true, slots: { orderBy: { startTime: "asc" } } },
    });

    return res.json(routes);
  } catch (e) {
    console.error("getMyRoutes error:", e);
    return res.status(500).json({ error: "Could not fetch routes" });
  }
}

/*
  POST /vendors/routes/:routeId/slots
  touch route after create so it appears in dashboard immediately
*/
export async function createSlot(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const routeId = Number(req.params.routeId);
  const { startTime, endTime, capacity, price, tankerCapacityLiters, notifyResidents } = req.body || {};

  if (!routeId || !startTime || !endTime || capacity == null || price == null) {
    return res.status(400).json({ error: "startTime, endTime, capacity, price are required" });
  }

  const capNum = Number(capacity);
  const priceNum = Number(price);

  if (!Number.isFinite(capNum) || capNum <= 0) {
    return res.status(400).json({ error: "capacity must be a positive number" });
  }
  if (!Number.isFinite(priceNum) || priceNum <= 0) {
    return res.status(400).json({ error: "price must be a positive number" });
  }

  const litersNum = tankerCapacityLiters == null ? 12000 : Number(tankerCapacityLiters);
  if (!Number.isFinite(litersNum) || litersNum <= 0) {
    return res.status(400).json({ error: "tankerCapacityLiters must be a positive number" });
  }

  try {
    const route = await prisma.route.findFirst({
      where: { id: routeId, vendorId: vendor.id },
      include: { ward: true, vendor: { include: { user: true } } },
    });

    if (!route) return res.status(404).json({ error: "Route not found or not owned by vendor" });

    const startDt = parseClientDateTimeOrThrow(startTime, "startTime");
    const endDt = parseClientDateTimeOrThrow(endTime, "endTime");
    if (endDt <= startDt) return res.status(400).json({ error: "endTime must be after startTime" });

    const slot = await prisma.slot.create({
      data: {
        routeId,
        startTime: startDt,
        endTime: endDt,
        capacity: capNum,
        price: priceNum,
        tankerCapacityLiters: litersNum,
      },
    });

    // TOUCH route so /vendors/dashboard sees it first
    await touchRoute(routeId);

    // Notification (optional)
    const shouldNotify = notifyResidents !== false;
    let notificationResult = null;

    if (shouldNotify) {
      const wardName = route.ward?.wardName ?? "Ward";
      const vendorName = route.vendor?.user?.name || (route.vendor?.companyName ?? "Vendor");
      const title = "New Tanker Slot Available";

      const startLabel = formatTimeInTz(startDt, APP_TIMEZONE);
      const endLabel = formatTimeInTz(endDt, APP_TIMEZONE);

      const msg =
        `${vendorName} opened a new tanker slot for ${wardName} ` +
        `(${startLabel} - ${endLabel}) • ${litersNum}L.`;

      const notif = await prisma.notification.create({
        data: {
          senderId: userId,
          senderRole: "VENDOR",
          title,
          message: msg,
          type: "BOOKING",
        },
      });

      const residentUsers = await prisma.user.findMany({
        where: { role: "RESIDENT", wardId: route.wardId },
        select: { id: true },
      });

      const deliveredAt = new Date();

      async function getLatestTokenOrCreateInAppToken(uid) {
        const existing = await prisma.fcmToken.findFirst({
          where: { userId: uid },
          orderBy: { updatedAt: "desc" },
          select: { id: true },
        });
        if (existing) return existing;

        const dummyToken = `inapp_user_${uid}`;
        return prisma.fcmToken.upsert({
          where: { token: dummyToken },
          update: { userId: uid, deviceInfo: "inapp" },
          create: { userId: uid, token: dummyToken, deviceInfo: "inapp" },
          select: { id: true },
        });
      }

      const rows = [];
      for (const u of residentUsers) {
        const tok = await getLatestTokenOrCreateInAppToken(u.id);
        rows.push({
          notificationId: notif.id,
          recipientId: tok.id,
          userId: u.id,
          deliveredAt,
          isRead: false,
        });
      }

      if (rows.length > 0) {
        await prisma.notificationRecipient.createMany({
          data: rows,
          skipDuplicates: true,
        });
      }

      const wardTopic = fcmService.wardToTopic(wardName);
      const data = {
        screen: "booking",
        slotId: String(slot.id),
        routeId: String(route.id),
        wardId: String(route.wardId),
        wardName: wardName,
      };

      const pushResult = await fcmService.sendToTopic(wardTopic, title, msg, data);
      notificationResult = {
        inAppNotificationId: notif.id,
        recipients: rows.length,
        push: pushResult,
        topic: wardTopic,
      };
    }

    return res.status(201).json({ success: true, slot, notify: notificationResult });
  } catch (e) {
    const code = e?.statusCode || 500;
    console.error("createSlot error:", e);
    return res.status(code).json({ error: e.message || "Could not create slot" });
  }
}

/*
  PATCH /vendors/slots/:slotId
  touch route after update so dashboard order is correct
*/
export async function updateSlot(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const slotId = Number(req.params.slotId);
  const { startTime, endTime, capacity, price, tankerCapacityLiters } = req.body || {};

  if (!Number.isFinite(slotId)) return res.status(400).json({ error: "Invalid slotId" });

  try {
    const slot = await prisma.slot.findUnique({
      where: { id: slotId },
      include: { route: true },
    });

    if (!slot || slot.route.vendorId !== vendor.id) {
      return res.status(404).json({ error: "Slot not found" });
    }

    const capNum = capacity == null ? null : Number(capacity);
    if (capNum != null && (!Number.isFinite(capNum) || capNum <= 0)) {
      return res.status(400).json({ error: "Invalid capacity" });
    }
    if (capNum != null && capNum < slot.bookedCount) {
      return res.status(400).json({ error: "Capacity cannot be less than bookedCount" });
    }

    const priceNum = price == null ? null : Number(price);
    if (priceNum != null && (!Number.isFinite(priceNum) || priceNum <= 0)) {
      return res.status(400).json({ error: "Invalid price" });
    }

    const litersNum = tankerCapacityLiters == null ? null : Number(tankerCapacityLiters);
    if (litersNum != null && (!Number.isFinite(litersNum) || litersNum <= 0)) {
      return res.status(400).json({ error: "Invalid tankerCapacityLiters" });
    }

    const updated = await prisma.slot.update({
      where: { id: slotId },
      data: {
        startTime: startTime ? parseClientDateTimeOrThrow(startTime, "startTime") : undefined,
        endTime: endTime ? parseClientDateTimeOrThrow(endTime, "endTime") : undefined,
        capacity: capNum == null ? undefined : capNum,
        price: priceNum == null ? undefined : priceNum,
        tankerCapacityLiters: litersNum == null ? undefined : litersNum,
      },
    });

    // TOUCH parent route
    await touchRoute(slot.routeId);

    return res.json({ success: true, slot: updated });
  } catch (e) {
    const code = e?.statusCode || 500;
    console.error("updateSlot error:", e);
    return res.status(code).json({ error: e.message || "Failed to update slot" });
  }
}

/*
  PATCH /vendors/slots/:slotId/mark-full
   touch route after mark-full
*/
export async function markSlotFull(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const slotId = Number(req.params.slotId);
  if (!Number.isFinite(slotId)) return res.status(400).json({ error: "Invalid slotId" });

  try {
    const slot = await prisma.slot.findUnique({
      where: { id: slotId },
      include: { route: true },
    });

    if (!slot || slot.route.vendorId !== vendor.id) {
      return res.status(404).json({ error: "Slot not found" });
    }

    const updated = await prisma.slot.update({
      where: { id: slotId },
      data: { bookedCount: slot.capacity },
    });

    // TOUCH parent route
    await touchRoute(slot.routeId);

    return res.json({ success: true, slot: updated });
  } catch (e) {
    console.error("markSlotFull error:", e);
    return res.status(500).json({ error: "Failed to mark slot full" });
  }
}

/*
  DELETE /vendors/slots/:slotId
    touch route if route still exists after deleting a slot
*/
export async function deleteSlot(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const slotId = Number(req.params.slotId);
  if (!Number.isFinite(slotId)) return res.status(400).json({ error: "Invalid slotId" });

  try {
    await prisma.$transaction(async (tx) => {
      const slot = await tx.slot.findUnique({
        where: { id: slotId },
        include: {
          route: true,
          _count: { select: { bookings: true } },
        },
      });

      if (!slot || slot.route.vendorId !== vendor.id) {
        const err = new Error("Slot not found");
        err.statusCode = 404;
        throw err;
      }

      if ((slot._count.bookings ?? 0) > 0) {
        const err = new Error("Cannot delete slot with bookings");
        err.statusCode = 409;
        throw err;
      }

      const routeId = slot.routeId;

      await tx.slot.delete({ where: { id: slotId } });

      const remaining = await tx.slot.count({ where: { routeId } });
      if (remaining === 0) {
        await tx.route.delete({ where: { id: routeId } });
      } else {
        // TOUCH route so dashboard ordering refreshes
        await touchRoute(routeId, tx);
      }
    });

    return res.json({ success: true });
  } catch (e) {
    const code = e?.statusCode || 500;
    console.error("deleteSlot error:", e);
    return res.status(code).json({ error: e.message || "Failed to delete slot" });
  }
}

/*
  GET /vendors/slots/ward/:ward
*/
export async function listSlotsByWardAndDate(req, res) {
  const wardParam = String(req.params.ward || "").trim();
  const { date } = req.query;

  try {
    const wardIdMaybe = Number(wardParam);
    const wardRow = Number.isFinite(wardIdMaybe)
      ? await prisma.ward.findUnique({ where: { id: wardIdMaybe } })
      : await prisma.ward.findFirst({ where: { wardName: wardParam } });

    if (!wardRow) return res.json([]);

    let routeDateFilter = {};
    if (date) {
      const base = parseDateOnlyOrDefault(date);
      const start = new Date(base.getFullYear(), base.getMonth(), base.getDate(), 0, 0, 0, 0);
      const end = new Date(base.getFullYear(), base.getMonth(), base.getDate(), 23, 59, 59, 999);
      routeDateFilter = { gte: start, lte: end };
    }

    const slots = await prisma.slot.findMany({
      where: {
        route: {
          wardId: wardRow.id,
          ...(date ? { routeDate: routeDateFilter } : {}),
        },
      },
      include: {
        route: {
          include: {
            ward: true,
            vendor: { include: { user: true } },
          },
        },
      },
      orderBy: { startTime: "asc" },
    });

    return res.json(slots);
  } catch (e) {
    console.error("listSlotsByWardAndDate error:", e);
    return res.status(500).json({ error: "Could not fetch slots" });
  }
}

/*
  PATCH /vendors/requests/:bookingId
*/
export async function updateBookingStatus(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const bookingId = Number(req.params.bookingId);
  const statusRaw = String(req.body?.status || "").trim().toUpperCase();

  if (!Number.isFinite(bookingId)) {
    return res.status(400).json({ error: "bookingId must be a number" });
  }

  if (!["CONFIRMED", "CANCELLED"].includes(statusRaw)) {
    return res.status(400).json({ error: "status must be CONFIRMED or CANCELLED" });
  }

  try {
    const updated = await prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: { slot: { include: { route: true } } },
      });

      if (!booking) {
        const err = new Error("Booking not found");
        err.statusCode = 404;
        throw err;
      }

      if (booking.slot?.route?.vendorId !== vendor.id) {
        const err = new Error("Forbidden (not your booking)");
        err.statusCode = 403;
        throw err;
      }

      if (booking.status === "CANCELLED") {
        const err = new Error("Booking already cancelled");
        err.statusCode = 409;
        throw err;
      }

      if (statusRaw === "CANCELLED" && booking.slotId) {
        const slot = await tx.slot.findUnique({ where: { id: booking.slotId } });
        if (slot) {
          const newCount = Math.max(0, (slot.bookedCount ?? 0) - 1);
          await tx.slot.update({
            where: { id: slot.id },
            data: { bookedCount: newCount },
          });
        }
      }

      const b2 = await tx.booking.update({
        where: { id: bookingId },
        data: { status: statusRaw },
        include: {
          user: { select: { id: true, name: true, phoneNumber: true } },
          slot: { include: { route: { include: { ward: true } } } },
        },
      });

      return b2;
    });

    return res.json({
      success: true,
      booking: {
        bookingId: updated.id,
        status: updated.status,
        createdAt: updated.createdAt,
        residentName: updated.user?.name ?? "Resident",
        residentPhone: updated.user?.phoneNumber ?? "",
        wardName: updated.slot?.route?.ward?.wardName ?? "-",
        location: updated.slot?.route?.location ?? "-",
        slotStartTime: updated.slot?.startTime ?? null,
        slotEndTime: updated.slot?.endTime ?? null,
      },
    });
  } catch (e) {
    const code = e?.statusCode || 500;
    return res.status(code).json({ error: e.message || "Failed to update booking" });
  }
}

// Convert stored "/uploads/..." to full URL for Flutter
function toAbsoluteUrl(req, storedPath) {
  if (!storedPath) return "";
  const s = String(storedPath);
  if (s.startsWith("http://") || s.startsWith("https://")) return s;
  const base = `${req.protocol}://${req.get("host")}`;
  const p = s.startsWith("/") ? s : `/${s}`;
  return `${base}${p}`;
}

// Delete old image file if it is under /uploads/
function getUploadAbsolutePathFromStoredUrl(stored) {
  if (!stored) return null;
  const s = String(stored);
  const idx = s.indexOf("/uploads/");
  if (idx === -1) return null;
  const publicPath = s.substring(idx);
  return path.resolve(publicPath.replace(/^\//, ""));
}

function tryDeleteOldUpload(stored) {
  const abs = getUploadAbsolutePathFromStoredUrl(stored);
  if (!abs) return;
  try {
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
  } catch (_) {}
}

/*
  GET /vendors/profile/me
*/
export async function getVendorProfileMe(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        phoneNumber: true,
        profileImageUrl: true,
      },
    });

    const v = await prisma.vendor.findUnique({
      where: { id: vendor.id },
      select: {
        id: true,
        companyName: true,
        phone: true,
        address: true,
        tankerCount: true,
      },
    });

    const deliveries = await prisma.booking.count({
      where: {
        status: "COMPLETED",
        slot: { route: { vendorId: vendor.id } },
      },
    });

    return res.json({
      vendor: {
        vendorId: v.id,
        contactName: user?.name ?? "",
        companyName: v.companyName ?? "",
        email: user?.email ?? "",
        phone: user?.phoneNumber ?? v.phone ?? "",
        address: v.address ?? "",
        tankerCount: v.tankerCount ?? 0,
        deliveries,
        logoUrl: user?.profileImageUrl ? toAbsoluteUrl(req, user.profileImageUrl) : "",
      },
    });
  } catch (e) {
    console.error("getVendorProfileMe error:", e);
    return res.status(500).json({ error: "Failed to load vendor profile" });
  }
}

/*
  PATCH /vendors/profile/me
*/
export async function updateVendorProfileMe(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const { contactName, companyName, phone, address, tankerCount } = req.body || {};

  try {
    await prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: {
          name: typeof contactName === "string" && contactName.trim() ? contactName.trim() : undefined,
          phoneNumber: typeof phone === "string" && phone.trim() ? phone.trim() : undefined,
        },
      });

      await tx.vendor.update({
        where: { id: vendor.id },
        data: {
          companyName: typeof companyName === "string" && companyName.trim() ? companyName.trim() : undefined,
          phone: typeof phone === "string" && phone.trim() ? phone.trim() : undefined,
          address: typeof address === "string" ? address.trim() : undefined,
          tankerCount: tankerCount == null ? undefined : Number(tankerCount),
        },
      });
    });

    return res.json({ success: true });
  } catch (e) {
    console.error("updateVendorProfileMe error:", e);
    return res.status(500).json({ error: "Failed to update vendor profile" });
  }
}

/*
  POST /vendors/profile/me/photo
*/
export async function uploadVendorPhotoMe(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!req.file) return res.status(400).json({ error: "photo file is required" });

  const { error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { profileImageUrl: true },
    });

    tryDeleteOldUpload(me?.profileImageUrl);

    const publicPath = `/uploads/profile/${req.file.filename}`;

    const updated = await prisma.user.update({
      where: { id: userId },
      data: { profileImageUrl: publicPath },
      select: { profileImageUrl: true },
    });

    return res.json({
      success: true,
      logoUrl: toAbsoluteUrl(req, updated.profileImageUrl),
    });
  } catch (e) {
    console.error("uploadVendorPhotoMe error:", e);
    return res.status(500).json({ error: "Failed to upload vendor photo" });
  }
}

/*
  DELETE /vendors/profile/me/photo
*/
export async function deleteVendorPhotoMe(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { profileImageUrl: true },
    });

    tryDeleteOldUpload(me?.profileImageUrl);

    await prisma.user.update({
      where: { id: userId },
      data: { profileImageUrl: null },
    });

    return res.json({ success: true });
  } catch (e) {
    console.error("deleteVendorPhotoMe error:", e);
    return res.status(500).json({ error: "Failed to delete vendor photo" });
  }
}