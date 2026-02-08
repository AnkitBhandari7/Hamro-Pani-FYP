import prisma from "../prisma.js";

/*
 GET /vendors/dashboard

 */
export async function getVendorDashboard(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const user = await prisma.user.findUnique({
    where: { id: Number(userId) },
    select: { role: true },
  });

  if (!user) return res.status(401).json({ error: "User not found" });
  if (String(user.role).toLowerCase() !== "vendor") {
    return res.status(403).json({
      error: "Only Vendor can access vendor dashboard",
    });
  }

  const vendorBookings = await prisma.booking.findMany({
    where: { vendorId: Number(userId) },
    orderBy: { createdAt: "desc" },
    include: {
      resident: { select: { name: true, phone: true } },
    },
  });

  const routesMap = new Map();

  for (const b of vendorBookings) {
    const ward = b.ward || "Unknown Ward";

    if (!routesMap.has(ward)) {
      routesMap.set(ward, {
        ward,
        title: `${ward} Route`,
        tankerInfo: "Tanker route",
        status: "Scheduled",
        stops: 0,
        bookings: 0,
        start: "Start not set",
        end: "End not set",
      });
    }

    const r = routesMap.get(ward);
    r.bookings += 1;
    r.stops += 1;

    if (
      ["CONFIRMED", "DELIVERING", "IN_PROGRESS"].includes(
        String(b.status).toUpperCase()
      )
    ) {
      r.status = "Active";
    }
  }

  const routes = Array.from(routesMap.values());

  const requests = vendorBookings
    .filter(
      (b) => String(b.status).toUpperCase() === "PENDING"
    )
    .slice(0, 10)
    .map((b) => ({
      id: b.id,
      residentName: b.resident?.name ?? "Resident",
      location: b.ward ?? "Unknown location",
      liters: b.liters,
      status: b.status,
      createdAt: b.createdAt,
    }));

  return res.json({
    routes,
    requests,
  });
}

/**
 * POST /vendors/routes
 * Create a tanker route for this vendor (name + ward)
 * Body: { wardId?, ward?, name, description? }
 */
export async function createTankerRoute(req, res) {
  const auth = req.auth;
  if (!auth) return res.status(401).json({ error: "Unauthorized" });

  const userId = Number(auth.sub);
  const role = String(auth.role || "").toLowerCase();

  if (role !== "vendor") {
    return res
      .status(403)
      .json({ error: "Only vendors can create routes" });
  }

  const { wardId, ward, name, description } = req.body || {};

  const routeWard =
    typeof ward === "string" && ward.trim()
      ? ward.trim()
      : wardId != null
      ? String(wardId)
      : null;

  if (!routeWard || !name) {
    return res
      .status(400)
      .json({ error: "ward/wardId and name are required" });
  }

  try {
    const route = await prisma.tankerRoute.create({
      data: {
        vendorId: userId,
        ward: routeWard,
        name,
        description: description || null,
      },
    });

    return res.status(201).json(route);
  } catch (error) {
    console.error("createTankerRoute error:", error);
    return res.status(500).json({ error: "Could not create route" });
  }
}

/**
 * GET /vendors/routes/my
 * Get all tanker routes + slots for this vendor
 */
export async function getMyTankerRoutes(req, res) {
  const auth = req.auth;
  if (!auth) return res.status(401).json({ error: "Unauthorized" });

  const userId = Number(auth.sub);
  const role = String(auth.role || "").toLowerCase();

  if (role !== "vendor") {
    return res
      .status(403)
      .json({ error: "Only vendors can view their routes" });
  }

  try {
    const routes = await prisma.tankerRoute.findMany({
      where: { vendorId: userId },
      include: {
        slots: {
          orderBy: { startTime: "asc" },
        },
      },
    });

    return res.json(routes);
  } catch (error) {
    console.error("getMyTankerRoutes error:", error);
    return res.status(500).json({ error: "Could not fetch routes" });
  }
}

/**
 * POST /vendors/routes/:routeId/slots
 * Body: { date, startTime, endTime, capacity }
 */
export async function createTankerSlot(req, res) {
  const auth = req.auth;
  if (!auth) return res.status(401).json({ error: "Unauthorized" });

  const userId = Number(auth.sub);
  const role = String(auth.role || "").toLowerCase();

  if (role !== "vendor") {
    return res
      .status(403)
      .json({ error: "Only vendors can create slots" });
  }

  const routeId = Number(req.params.routeId);
  const { date, startTime, endTime, capacity } = req.body || {};

  if (!date || !startTime || !endTime || !capacity) {
    return res.status(400).json({
      error: "date, startTime, endTime, capacity are required",
    });
  }

  try {
    const route = await prisma.tankerRoute.findFirst({
      where: {
        id: routeId,
        vendorId: userId,
      },
    });

    if (!route) {
      return res.status(404).json({
        error: "Route not found or not owned by current vendor",
      });
    }

    const slot = await prisma.tankerSlot.create({
      data: {
        routeId,
        date: new Date(date),
        startTime: new Date(startTime),
        endTime: new Date(endTime),
        capacityLiters: Number(capacity),
      },
    });

    return res.status(201).json(slot);
  } catch (error) {
    console.error("createTankerSlot error:", error);
    return res.status(500).json({ error: "Could not create slot" });
  }
}

/**
 * GET /vendors/slots/ward/:ward
 * Query: ?date=YYYY-MM-DD (optional)
 * Residents browse open slots by ward
 */
export async function listSlotsByWardAndDate(req, res) {
  const wardParam = req.params.ward; // string
  const { date } = req.query;

  try {
    const where = {
      route: { ward: wardParam },
      status: "OPEN",
    };

    if (date) {
      const start = new Date(`${date}T00:00:00.000Z`);
      const end = new Date(`${date}T23:59:59.999Z`);
      where.date = { gte: start, lte: end };
    }

    const slots = await prisma.tankerSlot.findMany({
      where,
      include: {
        route: {
          include: {
            vendor: true,
          },
        },
      },
      orderBy: { startTime: "asc" },
    });

    return res.json(slots);
  } catch (error) {
    console.error("listSlotsByWardAndDate error:", error);
    return res.status(500).json({ error: "Could not fetch slots" });
  }
}