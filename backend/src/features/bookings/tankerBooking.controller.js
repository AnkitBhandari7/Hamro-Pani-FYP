import prisma from "../../prisma.js";

/*
POST /bookings
*/
export async function createBooking(req, res) {
  const userIdRaw = req.auth?.sub;
  const userId = Number(userIdRaw);

  if (!userId || Number.isNaN(userId)) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { slotId } = req.body || {};
  const slotIdNum = Number(slotId);
  if (!slotIdNum) return res.status(400).json({ error: "slotId is required" });

  try {
    const result = await prisma.$transaction(async (tx) => {
      const slot = await tx.slot.findUnique({
        where: { id: slotIdNum },
        include: {
          route: {
            include: {
              ward: true,
              vendor: { include: { user: true } },
            },
          },
        },
      });

      if (!slot) throw new Error("SLOT_NOT_FOUND");

      const existing = await tx.booking.findFirst({
        where: {
          userId,
          slotId: slot.id,
          NOT: { status: "CANCELLED" },
        },
      });
      if (existing) throw new Error("ALREADY_BOOKED");

      if (slot.bookedCount >= slot.capacity) throw new Error("SLOT_FULL");

      await tx.slot.update({
        where: { id: slot.id },
        data: { bookedCount: { increment: 1 } },
      });

      const booking = await tx.booking.create({
        data: {
          userId,
          slotId: slot.id,
          status: "PENDING",
        },
        include: {
          user: { select: { id: true, name: true, phoneNumber: true } },
          slot: {
            include: {
              route: {
                include: {
                  ward: true,
                  vendor: { include: { user: true } },
                },
              },
            },
          },
        },
      });

      return booking;
    });

    return res.status(201).json(result);
  } catch (e) {
    if (e.message === "SLOT_FULL")
      return res.status(409).json({ error: "Slot is full" });
    if (e.message === "SLOT_NOT_FOUND")
      return res.status(404).json({ error: "Slot not found" });
    if (e.message === "ALREADY_BOOKED")
      return res.status(409).json({ error: "You already booked this slot" });

    console.error("createBooking error:", e);
    return res.status(500).json({ error: "Failed to create booking" });
  }
}

/*
GET /bookings/my
*/
export async function getMyBookings(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId || Number.isNaN(userId))
    return res.status(401).json({ error: "Unauthorized" });

  try {
    const bookings = await prisma.booking.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      include: {
        slot: {
          include: {
            route: {
              include: {
                ward: true,
                vendor: { include: { user: true } },
              },
            },
          },
        },
        payment: true,
      },
    });

    return res.json(bookings);
  } catch (e) {
    console.error("getMyBookings error:", e);
    return res.status(500).json({ error: "Failed to load bookings" });
  }
}

/*
GET /bookings/vendor/list?status=CONFIRMED
Vendor can view bookings belonging to them.
*/
export async function getVendorBookings(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId || Number.isNaN(userId))
    return res.status(401).json({ error: "Unauthorized" });

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    if (me?.role !== "VENDOR") {
      return res.status(403).json({ error: "Forbidden" });
    }

    const vendor = await prisma.vendor.findUnique({ where: { userId } });
    if (!vendor) return res.status(403).json({ error: "Vendor profile not found" });

    const status = (req.query.status ?? "").toString().toUpperCase().trim();
    const statusFilter = status ? { status } : {};

    const bookings = await prisma.booking.findMany({
      where: {
        ...statusFilter,
        slot: {
          route: { vendorId: vendor.id },
        },
      },
      orderBy: { createdAt: "desc" },
      include: {
        user: { select: { id: true, name: true, phoneNumber: true } },
        slot: {
          include: {
            route: { include: { ward: true, vendor: { include: { user: true } } } },
          },
        },
        payment: true,
      },
    });

    return res.json(bookings);
  } catch (e) {
    console.error("getVendorBookings error:", e);
    return res.status(500).json({ error: "Failed to load vendor bookings" });
  }
}

/*
PATCH /bookings/:id/status
*/
export async function updateBookingStatus(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId || Number.isNaN(userId)) return res.status(401).json({ error: "Unauthorized" });

  const bookingId = Number(req.params.id);
  const { status } = req.body || {};

  const allowed = ["CONFIRMED", "DELIVERED", "CANCELLED", "COMPLETED"];
  if (!allowed.includes(status)) return res.status(400).json({ error: "Invalid status" });

  try {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        user: true,
        slot: { include: { route: { include: { vendor: true } } } },
      },
    });

    if (!booking) return res.status(404).json({ error: "Booking not found" });

    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    const myRole = String(me?.role || "");

    // residents: only cancel own booking
    if (myRole === "RESIDENT") {
      if (booking.userId !== userId) return res.status(403).json({ error: "Not allowed" });
      if (status !== "CANCELLED") return res.status(403).json({ error: "Residents can only cancel" });
    }

    // I will write this to DB
    let finalStatus = status;

    // vendor permissions + flow
    if (myRole === "VENDOR") {
      const vendor = await prisma.vendor.findUnique({ where: { userId } });
      if (!vendor) return res.status(403).json({ error: "Vendor profile not found" });

      if (booking.slot.route.vendorId !== vendor.id) {
        return res.status(403).json({ error: "Booking does not belong to you" });
      }

      const current = String(booking.status || "").toUpperCase();

      if (status === "CONFIRMED") {
        if (current !== "PENDING") {
          return res.status(409).json({ error: "Cannot confirm from current status" });
        }
      }


      // vendor sets DELIVERED -> server sets COMPLETED
      if (status === "DELIVERED") {
        if (current !== "CONFIRMED") {
          return res.status(409).json({ error: "Cannot mark delivered from current status" });
        }
        finalStatus = "COMPLETED";
      }

      // block vendor from setting COMPLETED directly via API
      if (status === "COMPLETED") {
        return res.status(403).json({ error: "Use DELIVERED. System will mark COMPLETED." });
      }
    }

    const updated = await prisma.$transaction(async (tx) => {
      // if cancelled, free one slot (only if it wasn't cancelled already)
      if (finalStatus === "CANCELLED" && booking.status !== "CANCELLED") {
        const slot = await tx.slot.findUnique({ where: { id: booking.slotId } });
        if (slot) {
          const newCount = Math.max(0, (slot.bookedCount ?? 0) - 1);
          await tx.slot.update({
            where: { id: booking.slotId },
            data: { bookedCount: newCount },
          });
        }
      }

      await tx.statusHistory.create({
        data: {
          bookingId,
          oldStatus: booking.status,
          newStatus: finalStatus,
        },
      });

      return tx.booking.update({
        where: { id: bookingId },
        data: { status: finalStatus },
      });
    });

    return res.json(updated);
  } catch (e) {
    console.error("updateBookingStatus error:", e);
    return res.status(500).json({ error: "Failed to update booking status" });
  }
}

/*
POST /bookings/:id/confirm-delivery
*/
export async function confirmDeliveryAndRate(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId || Number.isNaN(userId)) return res.status(401).json({ error: "Unauthorized" });

  const bookingId = Number(req.params.id);
  if (!Number.isFinite(bookingId)) return res.status(400).json({ error: "Invalid booking id" });

  const { rating, comment } = req.body || {};
  const ratingNum = Number(rating);

  if (!Number.isFinite(ratingNum) || ratingNum < 1 || ratingNum > 5) {
    return res.status(400).json({ error: "rating must be between 1 and 5" });
  }

  try {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        slot: { include: { route: true } },
      },
    });

    if (!booking) return res.status(404).json({ error: "Booking not found" });

    // Resident can only rate own booking
    if (booking.userId !== userId) return res.status(403).json({ error: "Forbidden" });

    // booking may already be COMPLETED
    const st = String(booking.status || "").toUpperCase();
    if (!["DELIVERED", "COMPLETED"].includes(st)) {
      return res.status(409).json({ error: "You can rate only after delivery" });
    }

    const vendorId = booking.slot?.route?.vendorId;
    if (!vendorId) return res.status(500).json({ error: "Vendor not found for booking" });

    const result = await prisma.$transaction(async (tx) => {
      const existing = await tx.vendorRating.findUnique({
        where: { bookingId },
      });
      if (existing) throw new Error("ALREADY_RATED");

      const createdRating = await tx.vendorRating.create({
        data: {
          bookingId,
          vendorId,
          residentId: userId,
          rating: ratingNum,
          comment: typeof comment === "string" ? comment.trim() : null,
        },
      });

      //Update vendor aggregates
      const agg = await tx.vendorRating.aggregate({
        where: { vendorId },
        _avg: { rating: true },
        _count: { rating: true },
      });

      await tx.vendor.update({
        where: { id: vendorId },
        data: {
          ratingAverage: agg._avg.rating ?? 0,
          ratingCount: agg._count.rating ?? 0,
        },
      });

      return { createdRating };
    });

    return res.json({
      ok: true,
      rating: result.createdRating,
    });
  } catch (e) {
    if (e.message === "ALREADY_RATED") {
      return res.status(409).json({ error: "You already rated this booking" });
    }
    console.error("confirmDeliveryAndRate error:", e);
    return res.status(500).json({ error: "Failed to submit rating" });
  }
}

/*
GET /bookings/:id  (Resident-only detail)
*/
export async function getBookingDetail(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId || Number.isNaN(userId))
    return res.status(401).json({ error: "Unauthorized" });

  const bookingId = Number(req.params.id);
  if (!Number.isFinite(bookingId))
    return res.status(400).json({ error: "Invalid booking id" });

  try {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        payment: true,
        statusHistory: { orderBy: { changedAt: "asc" } },
        slot: {
          include: {
            route: {
              include: {
                ward: true,
                vendor: { include: { user: true } },
              },
            },
          },
        },
      },
    });

    if (!booking) return res.status(404).json({ error: "Booking not found" });
    if (booking.userId !== userId) return res.status(403).json({ error: "Forbidden" });

    const myRating = await prisma.vendorRating.findUnique({
      where: { bookingId },
      select: { id: true, rating: true, comment: true, createdAt: true },
    });

    return res.json({ ...booking, myRating });
  } catch (e) {
    console.error("getBookingDetail error:", e);
    return res.status(500).json({ error: "Failed to load booking detail" });
  }
}