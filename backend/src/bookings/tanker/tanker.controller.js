import prisma from "../../prisma.js";

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

    // Resident must have ward to find tankers for that ward
    if (!me.wardId) return res.json([]);

    const from = startOfToday();
    const to = addDays(from, 7);
    const now = new Date();

    const routes = await prisma.route.findMany({
      where: {
        wardId: me.wardId,
        routeDate: { gte: from, lte: to },
      },
      orderBy: [{ routeDate: "asc" }],
      include: {
        ward: true,
        vendor: { include: { user: { select: { id: true, name: true } } } },
        slots: { orderBy: [{ startTime: "asc" }] },
      },
    });

    // reduce routes -> unique vendor list with next slot
    const byVendor = new Map();

    for (const r of routes) {
      const vendorId = r.vendorId;
      const vendorName = r.vendor?.user?.name || `Vendor ${vendorId}`;
      const location = r.location ?? (r.ward?.wardName ?? "");

      if (search) {
        const hay1 = vendorName.toLowerCase();
        const hay2 = String(location).toLowerCase();
        if (!hay1.includes(search) && !hay2.includes(search)) continue;
      }

      const nextSlot = r.slots.find((s) => new Date(s.startTime) >= now) || r.slots[0];
      if (!nextSlot) continue;

      const used = nextSlot.bookedCount ?? 0;
      const total = nextSlot.capacity ?? 0;

      let status = "BUSY";
      if (total > 0 && used < total) status = "AVAILABLE";

      if (status === "AVAILABLE" && total > 0) {
        const remaining = total - used;
        if (remaining / total <= 0.2) status = "LOW_STOCK";
      }

      if (filter === "available_now" && status !== "AVAILABLE") continue;
      if (filter === "busy" && status !== "BUSY") continue;
      if (filter === "low_stock" && status !== "LOW_STOCK") continue;

      const candidate = {
        vendorId,
        name: vendorName,
        status,
        location,
        distance: "—", // no geo yet
        capacity: 12000, // mock; add DB field later if needed
        nextTime: formatTime(nextSlot.startTime),
        nextSlotId: nextSlot.id,
        nextSlotStartTime: nextSlot.startTime,
        slotsUsed: used,
        slotsTotal: total,
        price: 2500, // mock; add DB field later if needed
      };

      const existing = byVendor.get(vendorId);
      if (!existing) {
        byVendor.set(vendorId, candidate);
      } else {
        // keep earlier slot
        const t1 = new Date(existing.nextSlotStartTime);
        const t2 = new Date(candidate.nextSlotStartTime);
        if (t2 < t1) byVendor.set(vendorId, candidate);
      }
    }

    return res.json(Array.from(byVendor.values()));
  } catch (e) {
    console.error("getNearbyTankers error:", e);
    return res.status(500).json({ error: "Failed to load nearby tankers" });
  }
}

// POST /tankers/book { slotId }
export async function bookTankerSlot(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const slotId = Number(req.body?.slotId);
  if (!Number.isFinite(slotId)) {
    return res.status(400).json({ error: "slotId must be a number" });
  }

  try {
    const booking = await prisma.$transaction(async (tx) => {
      const slot = await tx.slot.findUnique({
        where: { id: slotId },
        select: { id: true, capacity: true, bookedCount: true },
      });

      if (!slot) {
        const err = new Error("Slot not found");
        err.statusCode = 404;
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

      const b = await tx.booking.create({
        data: {
          userId,
          slotId,
          status: "PENDING",
        },
      });

      await tx.slot.update({
        where: { id: slotId },
        data: { bookedCount: used + 1 },
      });

      return b;
    });

    return res.status(201).json({ success: true, booking });
  } catch (e) {
    const code = e?.statusCode || 500;
    return res.status(code).json({ error: e.message || "Failed to book slot" });
  }
}