import prisma from "../prisma.js";

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
          route: { include: { ward: true, vendor: { include: { user: true } } } },
        },
      });

      if (!slot) throw new Error("SLOT_NOT_FOUND");

      //  prevent duplicate booking for same user + same slot (if not cancelled)
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
    if (e.message === "SLOT_FULL") return res.status(409).json({ error: "Slot is full" });
    if (e.message === "SLOT_NOT_FOUND") return res.status(404).json({ error: "Slot not found" });
    if (e.message === "ALREADY_BOOKED") return res.status(409).json({ error: "You already booked this slot" });

    console.error("createBooking error:", e);
    return res.status(500).json({ error: "Failed to create booking" });
  }
}

/*
GET /bookings/my
*/
export async function getMyBookings(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId || Number.isNaN(userId)) return res.status(401).json({ error: "Unauthorized" });

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
      },
    });

    return res.json(bookings);
  } catch (e) {
    console.error("getMyBookings error:", e);
    return res.status(500).json({ error: "Failed to load bookings" });
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

  const allowed = ["CONFIRMED", "CANCELLED", "COMPLETED"];
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

    // permissions
    if (myRole === "RESIDENT") {
      if (booking.userId !== userId) return res.status(403).json({ error: "Not allowed" });
      if (status !== "CANCELLED") return res.status(403).json({ error: "Residents can only cancel" });
    }

    if (myRole === "VENDOR") {
      const vendor = await prisma.vendor.findUnique({ where: { userId } });
      if (!vendor) return res.status(403).json({ error: "Vendor profile not found" });

      if (booking.slot.route.vendorId !== vendor.id) {
        return res.status(403).json({ error: "Booking does not belong to you" });
      }
    }

    const updated = await prisma.$transaction(async (tx) => {
      // if cancelled, free one slot (only if it wasn't cancelled already)
      if (status === "CANCELLED" && booking.status !== "CANCELLED") {
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
          newStatus: status,
        },
      });

      return tx.booking.update({
        where: { id: bookingId },
        data: { status },
      });
    });

    return res.json(updated);
  } catch (e) {
    console.error("updateBookingStatus error:", e);
    return res.status(500).json({ error: "Failed to update booking status" });
  }
}