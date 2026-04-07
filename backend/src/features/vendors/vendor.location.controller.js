import prisma from "../../prisma.js";

/**
 * POST /vendors/location
 * Vendor-only. Saves current GPS to DB every ~15s during active delivery.
 * Body: { lat: number, lng: number }
 */
export async function updateVendorLocation(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId || Number.isNaN(userId)) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const lat = Number(req.body?.lat);
  const lng = Number(req.body?.lng);

  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return res.status(400).json({ error: "lat and lng must be valid numbers" });
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return res.status(400).json({ error: "lat/lng out of valid range" });
  }

  try {
    const vendor = await prisma.vendor.findUnique({
      where: { userId },
      select: { id: true },
    });

    if (!vendor) {
      return res.status(403).json({ error: "Vendor profile not found" });
    }

    await prisma.vendor.update({
      where: { id: vendor.id },
      data: {
        currentLat: lat,
        currentLng: lng,
        lastLocationUpdatedAt: new Date(),
      },
    });

    return res.json({ ok: true });
  } catch (e) {
    console.error("updateVendorLocation error:", e);
    return res.status(500).json({ error: "Failed to save vendor location" });
  }
}

/**
 * GET /bookings/:id/tracking
 * Resident-only. Returns vendor's current live location + resident destination.
 * Used as fallback poll when socket is disconnected (every 10s on client).
 */
export async function getBookingTracking(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId || Number.isNaN(userId)) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const bookingId = Number(req.params.id);
  if (!Number.isFinite(bookingId)) {
    return res.status(400).json({ error: "Invalid booking id" });
  }

  try {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        user: {
          select: {
            id: true,
            locations: {
              orderBy: [{ isDefault: "desc" }, { updatedAt: "desc" }],
              take: 1,
            },
          },
        },
        slot: {
          include: {
            route: {
              include: {
                vendor: {
                  include: {
                    user: {
                      select: {
                        id: true,
                        name: true,
                        phoneNumber: true,
                        profileImageUrl: true,
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!booking) return res.status(404).json({ error: "Booking not found" });

    // Only the booking owner (resident) can poll tracking
    if (booking.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const vendor = booking.slot?.route?.vendor;
    const vendorUser = vendor?.user;

    // Resident destination — use default saved location
    const destLoc = booking.user?.locations?.[0];

    // Build vendor image URL — pass through Firebase HTTPS URLs unchanged,
    // convert old /uploads/ paths to absolute server URL
    let vendorImageUrl = "";
    if (vendorUser?.profileImageUrl) {
      const raw = vendorUser.profileImageUrl;
      if (raw.startsWith("http://") || raw.startsWith("https://")) {
        vendorImageUrl = raw.replace(/^http:\/\//, "https://");
      } else {
        vendorImageUrl = `https://${req.get("host")}${raw.startsWith("/") ? raw : "/" + raw}`;
      }
    }

    return res.json({
      bookingId: booking.id,
      status: booking.status,

      vendor: {
        name: vendorUser?.name ?? "Vendor",
        phone: vendorUser?.phoneNumber ?? "",
        imageUrl: vendorImageUrl,
        // Live location — null if vendor hasn't broadcast yet
        currentLat: vendor?.currentLat ?? null,
        currentLng: vendor?.currentLng ?? null,
        lastUpdatedAt: vendor?.lastLocationUpdatedAt ?? null,
      },

      destination: destLoc
        ? {
            label: destLoc.label,
            address: destLoc.address,
            lat: destLoc.lat,
            lng: destLoc.lng,
          }
        : null,
    });
  } catch (e) {
    console.error("getBookingTracking error:", e);
    return res.status(500).json({ error: "Failed to load tracking data" });
  }
}
