// src/vendors/vendor.controller.js
import prisma from "../prisma.js";

/*
  Small helper:
  - get current logged-in user id from req.auth.sub
  - in your project, authenticateFirebase is setting req.auth.sub = DB userId
*/
function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

/*
  Small helper:
  - check current user is VENDOR
  - also load vendor profile row
*/
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
  - show vendor routes summary + last pending bookings
*/
export async function getVendorDashboard(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  try {
    // Load routes with ward + slots and booking counts
    const routes = await prisma.route.findMany({
      where: { vendorId: vendor.id },
      orderBy: { createdAt: "desc" },
      include: {
        ward: true,
        slots: {
          orderBy: { startTime: "asc" },
          include: {
            _count: { select: { bookings: true } },
          },
        },
      },
    });

    // Load last 10 pending bookings for this vendor
    const requests = await prisma.booking.findMany({
      where: {
        slot: {
          route: { vendorId: vendor.id },
        },
        status: "PENDING",
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

    return res.json({ routes, requests });
  } catch (e) {
    console.error("getVendorDashboard error:", e);
    return res.status(500).json({ error: "Failed to load vendor dashboard" });
  }
}

/*
  POST /vendors/routes
  ERD Route fields: { vendorId, wardId, routeDate, location }
  Flutter might send: wardId OR ward (string), routeDate?, location?
*/
export async function createRoute(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { vendor, error } = await getVendorByUserId(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const { wardId, ward, routeDate, location } = req.body || {};

  try {
    // 1) Find ward (by wardId OR by ward name)
    let wardRow = null;

    if (wardId != null) {
      wardRow = await prisma.ward.findUnique({ where: { id: Number(wardId) } });
    } else if (typeof ward === "string" && ward.trim()) {
      // find by name, if not exists create (simple approach)
      wardRow = await prisma.ward.findFirst({ where: { wardName: ward.trim() } });
      if (!wardRow) {
        wardRow = await prisma.ward.create({
          data: { wardName: ward.trim() },
        });
      }
    }

    if (!wardRow) {
      return res.status(400).json({ error: "wardId or ward name is required" });
    }

    // 2) routeDate default = today (00:00)
    const d = routeDate ? new Date(routeDate) : new Date();
    const routeDateOnly = new Date(d.getFullYear(), d.getMonth(), d.getDate());

    // 3) create route
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
  - vendor can see their routes + slots
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
  Body: { startTime, endTime, capacity }
  - ERD Slot has startTime/endTime, capacity, bookedCount
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
    // make sure route belongs to current vendor
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
  Residents browse slots by ward name or ward id
  Query: ?date=YYYY-MM-DD (optional)
*/
export async function listSlotsByWardAndDate(req, res) {
  const wardParam = String(req.params.ward || "").trim();
  const { date } = req.query;

  try {
    // wardParam can be "5" or "Ward 5"
    const wardIdMaybe = Number(wardParam);
    const wardRow = Number.isFinite(wardIdMaybe)
      ? await prisma.ward.findUnique({ where: { id: wardIdMaybe } })
      : await prisma.ward.findFirst({ where: { wardName: wardParam } });

    if (!wardRow) return res.json([]);

    // date filter uses Route.routeDate in ERD
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

    // In ERD there is no "status", so we treat slot as available if bookedCount < capacity
    const openSlots = slots.filter((s) => s.bookedCount < s.capacity);

    return res.json(openSlots);
  } catch (e) {
    console.error("listSlotsByWardAndDate error:", e);
    return res.status(500).json({ error: "Could not fetch slots" });
  }
}