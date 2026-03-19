import prisma from "../prisma.js";

function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

async function ensureVendor(userId) {
  const user = await prisma.user.findUnique({ where: { id: userId }, select: { role: true } });
  if (!user) return { error: { status: 401, message: "Unauthorized" } };
  if (String(user.role).toUpperCase() !== "VENDOR") return { error: { status: 403, message: "Only vendor can access" } };

  const vendor = await prisma.vendor.findUnique({ where: { userId }, select: { id: true } });
  if (!vendor) return { error: { status: 403, message: "Vendor profile not found" } };

  return { vendor };
}

/**
 * GET /vendors/bookings/:bookingId/destination
 * Student: vendor sees resident destination (default saved location)
 */
export async function getBookingDestination(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { error, vendor } = await ensureVendor(userId);
  if (error) return res.status(error.status).json({ error: error.message });

  const bookingId = Number(req.params.bookingId);
  if (!Number.isFinite(bookingId)) return res.status(400).json({ error: "Invalid bookingId" });

  try {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            locations: { orderBy: [{ isDefault: "desc" }, { updatedAt: "desc" }], take: 1 },
          },
        },
        slot: {
          include: {
            route: { select: { vendorId: true } },
          },
        },
      },
    });

    if (!booking) return res.status(404).json({ error: "Booking not found" });

    // Ensure booking belongs to this vendor
    const bookingVendorId = booking.slot?.route?.vendorId;
    if (!bookingVendorId || bookingVendorId !== vendor.id) {
      return res.status(403).json({ error: "Forbidden (not your booking)" });
    }

    const loc = booking.user?.locations?.[0];
    if (!loc) return res.status(404).json({ error: "Resident has no saved location" });

    return res.json({
      bookingId: booking.id,
      resident: {
        id: booking.user.id,
        name: booking.user.name ?? "Resident",
      },
      destination: {
        label: loc.label,
        address: loc.address,
        lat: loc.lat,
        lng: loc.lng,
      },
    });
  } catch (e) {
    console.error("getBookingDestination error:", e);
    return res.status(500).json({ error: "Failed to load destination" });
  }
}