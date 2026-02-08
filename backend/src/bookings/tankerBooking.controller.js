// backend/bookings/booking.controller.js
import prisma from "../prisma.js";

/**
 * POST /bookings
 * Body: { slotId, liters, price? }
 */
export async function createBooking(req, res) {
  const auth = req.auth;
  if (!auth) return res.status(401).json({ error: "Unauthorized" });

  const userId = Number(auth.sub);
  const { slotId, liters, price } = req.body || {};

  if (!slotId || !liters) {
    return res
      .status(400)
      .json({ error: "slotId and liters are required" });
  }

  try {
    const result = await prisma.$transaction(async (tx) => {
      const slot = await tx.tankerSlot.findUnique({
        where: { id: Number(slotId) },
        include: {
          route: true,
        },
      });

      if (!slot || slot.status !== "OPEN") {
        throw new Error("SLOT_FULL_OR_CLOSED");
      }

      const litersInt = Number(liters);
      if (
        slot.bookedLiters + litersInt >
        slot.capacityLiters
      ) {
        throw new Error("SLOT_FULL_OR_CLOSED");
      }

      await tx.tankerSlot.update({
        where: { id: slot.id },
        data: {
          bookedLiters: {
            increment: litersInt,
          },
        },
      });

      const booking = await tx.booking.create({
        data: {
          residentId: userId,
          vendorId: slot.route.vendorId,
          ward: slot.route.ward,
          liters: litersInt,
          price: price != null ? Number(price) : null,
          status: "PENDING",
          slotId: slot.id,
        },
        include: {
          resident: { select: { name: true, phone: true } },
          vendor: { select: { name: true, phone: true } },
          slot: {
            include: {
              route: true,
            },
          },
        },
      });

      return booking;
    });

    return res.status(201).json(result);
  } catch (error) {
    if (error.message === "SLOT_FULL_OR_CLOSED") {
      return res
        .status(409)
        .json({ error: "Slot is full or not open" });
    }
    console.error("createBooking error:", error);
    return res
      .status(500)
      .json({ error: "Failed to create booking" });
  }
}

/**
 * GET /bookings/my
 * Current user's bookings
 */
export async function getMyBookings(req, res) {
  const auth = req.auth;
  if (!auth) return res.status(401).json({ error: "Unauthorized" });

  const userId = Number(auth.sub);

  try {
    const bookings = await prisma.booking.findMany({
      where: { residentId: userId },
      orderBy: { createdAt: "desc" },
      include: {
        vendor: { select: { name: true, phone: true } },
        slot: {
          include: {
            route: true,
          },
        },
      },
    });

    return res.json(bookings);
  } catch (error) {
    console.error("getMyBookings error:", error);
    return res
      .status(500)
      .json({ error: "Failed to load bookings" });
  }
}

/**
 * PATCH /bookings/:id/status
 * Body: { status: "CONFIRMED" | "CANCELLED" | "COMPLETED" }
 * - Resident can cancel own booking
 * - Vendor can confirm/complete/cancel for their own bookings
 */
export async function updateBookingStatus(req, res) {
  const auth = req.auth;
  if (!auth) return res.status(401).json({ error: "Unauthorized" });

  const userId = Number(auth.sub);
  const role = String(auth.role || "").toLowerCase();
  const bookingId = Number(req.params.id);
  const { status } = req.body || {};

  const allowed = ["CONFIRMED", "CANCELLED", "COMPLETED"];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: "Invalid status" });
  }

  try {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        slot: true,
      },
    });

    if (!booking) {
      return res.status(404).json({ error: "Booking not found" });
    }

    // permission checks
    if (role === "resident") {
      if (booking.residentId !== userId) {
        return res.status(403).json({ error: "Not allowed" });
      }
      if (status !== "CANCELLED") {
        return res
          .status(403)
          .json({ error: "Residents can only cancel" });
      }
    } else if (role === "vendor") {
      if (booking.vendorId !== userId) {
        return res
          .status(403)
          .json({ error: "Booking does not belong to you" });
      }
    } else {
      return res.status(403).json({ error: "Not allowed" });
    }

    const updated = await prisma.$transaction(async (tx) => {
      if (
        status === "CANCELLED" &&
        booking.status !== "CANCELLED" &&
        booking.slotId
      ) {
        await tx.tankerSlot.update({
          where: { id: booking.slotId },
          data: {
            bookedLiters: {
              decrement: booking.liters ?? 0,
            },
          },
        });
      }

      const updatedBooking = await tx.booking.update({
        where: { id: bookingId },
        data: { status },
      });

      return updatedBooking;
    });

    return res.json(updated);
  } catch (error) {
    console.error("updateBookingStatus error:", error);
    return res
      .status(500)
      .json({ error: "Failed to update booking status" });
  }
}