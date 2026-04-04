import prisma from "../../../prisma.js";

function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

function startOfToday() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function addDays(dt, days) {
  const d = new Date(dt);
  d.setDate(d.getDate() + days);
  return d;
}

function formatTime(dt) {
  const d = new Date(dt);
  let h = d.getHours();
  const m = String(d.getMinutes()).padStart(2, "0");
  const ampm = h >= 12 ? "PM" : "AM";
  h = h % 12;
  if (h === 0) h = 12;
  return `${h}:${m} ${ampm}`;
}

function normalizeFilter(f) {
  const x = String(f || "all").toLowerCase().trim();
  if (["all", "available_now", "busy", "low_stock"].includes(x)) return x;
  return "all";
}


// GET /tankers/nearby
export async function getNearbyTankers(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const search = String(req.query.search || "").trim().toLowerCase();
  const filter = normalizeFilter(req.query.filter);

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { wardId: true, role: true },
    });

    if (!me) return res.status(401).json({ error: "Unauthorized" });
    if (!me.wardId) return res.json([]);

    const from = startOfToday();
    const to = addDays(from, 7);
    const now = new Date();

    //  Pull SLOTS directly, newest first
    const slots = await prisma.slot.findMany({
      where: {
        route: {
          wardId: me.wardId,
          routeDate: { gte: from, lte: to },
        },
        endTime: { gte: now },
      },
      include: {
        route: {
          include: {
            ward: true,
            vendor: { include: { user: { select: { id: true, name: true } } } },
          },
        },
      },
      orderBy: { createdAt: "desc" }, //  latest opened slot first
      take: 500,
    });

    const byVendor = new Map();

    for (const s of slots) {
      const r = s.route;
      const vendorId = r.vendorId;

      const vendorName = r.vendor?.user?.name || `Vendor ${vendorId}`;
      const location = r.location ?? (r.ward?.wardName ?? "");

      // search filter
      if (search) {
        const hay1 = vendorName.toLowerCase();
        const hay2 = String(location).toLowerCase();
        if (!hay1.includes(search) && !hay2.includes(search)) continue;
      }

      const used = s.bookedCount ?? 0;
      const total = s.capacity ?? 0;

      let status = "BUSY";
      if (total > 0 && used < total) status = "AVAILABLE";
      if (status === "AVAILABLE" && total > 0) {
        const remaining = total - used;
        if (remaining / total <= 0.2) status = "LOW_STOCK";
      }

      // API filter
      if (filter === "available_now" && status !== "AVAILABLE") continue;
      if (filter === "busy" && status !== "BUSY") continue;
      if (filter === "low_stock" && status !== "LOW_STOCK") continue;

      // keep first slot per vendor (because slots are newest-first)
      if (byVendor.has(vendorId)) continue;

      byVendor.set(vendorId, {
        vendorId,
        name: vendorName,
        status,
        location,
        distance: "—",

        // real fields from Slot
        nextSlotId: s.id,
        nextTime: formatTime(s.startTime),
        nextSlotStartTime: s.startTime,

        slotsUsed: used,
        slotsTotal: total,

        price: s.price ?? null,
        tankerCapacityLiters: s.tankerCapacityLiters ?? 12000,
      });
    }

    return res.json(Array.from(byVendor.values()));
  } catch (e) {
    console.error("getNearbyTankers error:", e);
    return res.status(500).json({ error: "Failed to load nearby tankers" });
  }
}


// POST /tankers/book { slotId, paymentMethod }
export async function bookTankerSlot(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const slotId = Number(req.body?.slotId);
  if (!Number.isFinite(slotId)) {
    return res.status(400).json({ error: "slotId must be a number" });
  }

  const pmRaw = String(req.body?.paymentMethod || "CASH").trim().toUpperCase();
  const allowedPm = new Set(["CASH", "ESEWA"]);
  if (!allowedPm.has(pmRaw)) {
    return res.status(400).json({ error: "paymentMethod must be CASH or ESEWA" });
  }

  try {
    const result = await prisma.$transaction(async (tx) => {
      const slot = await tx.slot.findUnique({
        where: { id: slotId },
        select: {
          id: true,
          capacity: true,
          bookedCount: true,
          price: true,
        },
      });

      if (!slot) {
        const err = new Error("Slot not found");
        err.statusCode = 404;
        throw err;
      }

      // Prevent duplicate booking for same user + same slot
      const existing = await tx.booking.findFirst({
        where: {
          userId,
          slotId: slot.id,
          NOT: { status: "CANCELLED" },
        },
        select: { id: true },
      });
      if (existing) {
        const err = new Error("You already booked this slot");
        err.statusCode = 409;
        throw err;
      }

      const used = slot.bookedCount ?? 0;
      const total = slot.capacity ?? 0;

      if (total <= 0) {
        const err = new Error("Slot capacity is invalid");
        err.statusCode = 400;
        throw err;
      }

      if (used >= total) {
        const err = new Error("Slot is full");
        err.statusCode = 409;
        throw err;
      }

      // Create booking
      const booking = await tx.booking.create({
        data: {
          userId,
          slotId: slot.id,
          status: "PENDING",
        },
        select: { id: true, status: true, createdAt: true },
      });

      //  Increment bookedCount
      await tx.slot.update({
        where: { id: slot.id },
        data: { bookedCount: used + 1 },
      });

      // Create payment row
      const amountNum = Number(slot.price ?? 0);
      const amount = Number.isFinite(amountNum) ? amountNum.toFixed(2) : "0.00";

      const payment = await tx.payment.create({
        data: {
          bookingId: booking.id,
          method: pmRaw,      // "CASH" | "ESEWA"
          amount: amount,     // Decimal as string is safe
          status: "PENDING",  // keep pending until vendor confirms/delivery/esewa callback
        },
        select: { id: true, status: true, method: true, amount: true },
      });

      return { booking, payment };
    });

    return res.status(201).json({ success: true, ...result });
  } catch (e) {
    const code = e?.statusCode || 500;
    return res.status(code).json({ error: e.message || "Failed to book slot" });
  }
}

// GET /tankers/slots/:slotId/details
export async function getSlotDetails(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const slotId = Number(req.params.slotId);
  if (!Number.isFinite(slotId)) return res.status(400).json({ error: "Invalid slotId" });

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { wardId: true, role: true },
    });

    const slot = await prisma.slot.findUnique({
      where: { id: slotId },
      include: {
        route: {
          include: {
            ward: true,
            vendor: { include: { user: { select: { id: true, name: true } } } },
          },
        },
      },
    });

    if (!slot) return res.status(404).json({ error: "Slot not found" });

    //  Residents can only view slots of their ward
    if (String(me?.role || "").toUpperCase() === "RESIDENT") {
      if (!me?.wardId || slot.route?.wardId !== me.wardId) {
        return res.status(403).json({ error: "Forbidden" });
      }
    }

    const used = slot.bookedCount ?? 0;
    const total = slot.capacity ?? 0;

    let status = "BUSY";
    if (total > 0 && used < total) status = "AVAILABLE";
    if (status === "AVAILABLE" && total > 0) {
      const remaining = total - used;
      if (remaining / total <= 0.2) status = "LOW_STOCK";
    }

    return res.json({
      slotId: slot.id,
      startTime: slot.startTime,
      endTime: slot.endTime,

      bookingSlotsUsed: used,
      bookingSlotsTotal: total,

      price: slot.price ?? null,
      tankerCapacityLiters: slot.tankerCapacityLiters ?? 12000,

      status,

      vendor: {
        vendorId: slot.route.vendorId,
        name: slot.route.vendor?.user?.name ?? "Vendor",
      },
      route: {
        routeId: slot.routeId,
        location: slot.route.location ?? "",
        wardName: slot.route.ward?.wardName ?? "",
        routeDate: slot.route.routeDate,
      },
    });
  } catch (e) {
    console.error("getSlotDetails error:", e);
    return res.status(500).json({ error: "Failed to load slot details" });
  }
}