// src/vendors/vendor.controller.js
// Student note: Vendor logic for routes, slots, dashboard, and confirm/decline booking.

import prisma from "../prisma.js";

function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

function startOfToday() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function isActiveRoute(routeDate) {
  // Student note: simple rule = route is Active if routeDate is today
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

/*
  GET /vendors/dashboard
  Student note:
  - returns vendor routes in UI-friendly format (Active/Scheduled + progress)
  - returns last 10 bookings (requests) for this vendor
*/
export async function getVendorDashboard(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  try {
    const vendorUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { name: true },
    });

    // -------------------------
    // Routes (with slot progress)
    // -------------------------
    const rawRoutes = await prisma.route.findMany({
      where: { vendorId: vendor.id },
      orderBy: { routeDate: "desc" },
      take: 10,
      include: {
        ward: true,
        slots: { orderBy: { startTime: "asc" } },
      },
    });

    const routes = rawRoutes.map((r) => {
      const slotsTotal = r.slots.reduce((sum, s) => sum + (s.capacity ?? 0), 0);
      const slotsUsed = r.slots.reduce((sum, s) => sum + (s.bookedCount ?? 0), 0);

      const percentBooked = slotsTotal > 0 ? Math.round((slotsUsed / slotsTotal) * 100) : 0;

      const first = r.slots.length > 0 ? r.slots[0] : null;
      const last = r.slots.length > 0 ? r.slots[r.slots.length - 1] : null;

      return {
        routeId: r.id,
        wardName: r.ward?.wardName ?? "-",
        location: r.location ?? "-",
        routeDate: r.routeDate,

        // Student note: status for UI chip
        status: isActiveRoute(r.routeDate) ? "Active" : "Scheduled",

        // Student note: start/end for UI
        startTime: first?.startTime ?? null,
        endTime: last?.endTime ?? null,
        startTimeLabel: toTimeLabel(first?.startTime),
        endTimeLabel: toTimeLabel(last?.endTime),

        // Student note: progress bar
        slotsTotal,
        slotsUsed,
        percentBooked,
      };
    });

    // -------------------------
    // Requests (real bookings)
    // -------------------------
    const rawBookings = await prisma.booking.findMany({
      where: {
        slot: {
          route: { vendorId: vendor.id },
        },
        // Student note: show both pending and confirmed in recent list (exclude cancelled if you want)
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

    // -------------------------
    // Stats
    // -------------------------
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
        name: vendorUser?.name ?? "Vendor",
      },
      stats: {
        todaysJobs,
        successPercent: 0, // Student note: calculate later if you want
        rating: 0,         // Student note: rating not in DB now
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
      if (!wardRow) {
        wardRow = await prisma.ward.create({ data: { wardName: ward.trim() } });
      }
    }

    if (!wardRow) {
      return res.status(400).json({ error: "wardId or ward name is required" });
    }

    const d = routeDate ? new Date(routeDate) : new Date();
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
      include: {
        ward: true,
        slots: { orderBy: { startTime: "asc" } },
      },
    });

    return res.json(routes);
  } catch (e) {
    console.error("getMyRoutes error:", e);
    return res.status(500).json({ error: "Could not fetch routes" });
  }
}

/*
  POST /vendors/routes/:routeId/slots
*/
export async function createSlot(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const routeId = Number(req.params.routeId);
  const { startTime, endTime, capacity } = req.body || {};

  if (!routeId || !startTime || !endTime || capacity == null) {
    return res.status(400).json({ error: "startTime, endTime, capacity are required" });
  }

  try {
    const route = await prisma.route.findFirst({
      where: { id: routeId, vendorId: vendor.id },
    });

    if (!route) {
      return res.status(404).json({ error: "Route not found or not owned by vendor" });
    }

    const slot = await prisma.slot.create({
      data: {
        routeId,
        startTime: new Date(startTime),
        endTime: new Date(endTime),
        capacity: Number(capacity),
      },
    });

    return res.status(201).json(slot);
  } catch (e) {
    console.error("createSlot error:", e);
    return res.status(500).json({ error: "Could not create slot" });
  }
}

/*
  GET /vendors/slots/ward/:ward
  (Kept, but your main "Nearby vendors" should use /tankers/nearby)
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
      const start = new Date(`${date}T00:00:00.000Z`);
      const end = new Date(`${date}T23:59:59.999Z`);
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
  ✅ PATCH /vendors/requests/:bookingId
  Body: { status: "CONFIRMED" | "CANCELLED" }
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
        include: {
          slot: { include: { route: true } },
        },
      });

      if (!booking) {
        const err = new Error("Booking not found");
        err.statusCode = 404;
        throw err;
      }

      // Student note: security check (booking must belong to this vendor)
      if (booking.slot?.route?.vendorId !== vendor.id) {
        const err = new Error("Forbidden (not your booking)");
        err.statusCode = 403;
        throw err;
      }

      // Student note: only allow changes from PENDING or CONFIRMED (simple rule)
      if (booking.status === "CANCELLED") {
        const err = new Error("Booking already cancelled");
        err.statusCode = 409;
        throw err;
      }

      // If cancelling, free slot capacity (decrement bookedCount)
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