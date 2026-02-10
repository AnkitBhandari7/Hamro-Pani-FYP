// src/profile/profile.controller.js
import prisma from "../prisma.js";

// Student note: helper to safely read user id from token middleware
function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

/*
  GET /profile/me
  Student note:
  - In ERD, user has phoneNumber and ward relation (not string ward)
  - ERD does not have SavedLocation and Issue, so we return empty locations
    and we map Complaint as issues.
*/
export async function meDetails(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    // Student note: load basic user with ward relation
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { ward: true },
    });

    if (!user) return res.status(404).json({ error: "User not found" });

    // Student note: last 10 bookings (ERD Booking has no liters/price)
    const bookings = await prisma.booking.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 10,
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

    // Student note: ERD uses Complaint instead of Issue
    const complaints = await prisma.complaint.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 10,
      select: {
        id: true,
        message: true,
        status: true,
        createdAt: true,
      },
    });

    // Student note: Return same structure old Flutter expects
    return res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,

        // old flutter expects "phone", ERD field is phoneNumber
        phone: user.phoneNumber,

        role: user.role,

        // old flutter expects ward string
        ward: user.ward ? user.ward.wardName : null,
      },

      // ERD does not have SavedLocation -> return empty list so Flutter doesn't crash
      locations: [],

      // old flutter expects liters/price -> not in ERD, so return null
      bookings: bookings.map((b) => ({
        id: b.id,
        status: b.status,
        liters: null,
        price: null,
        createdAt: b.createdAt,

        // extra useful info for UI
        slotId: b.slotId,
        slotStartTime: b.slot?.startTime,
        slotEndTime: b.slot?.endTime,
        routeLocation: b.slot?.route?.location ?? null,
        ward: b.slot?.route?.ward?.wardName ?? null,
        vendorName: b.slot?.route?.vendor?.user?.name ?? null,
      })),

      // map complaints into "issues" so existing UI can show something
      issues: complaints.map((c) => ({
        id: c.id,
        title: "Complaint",
        status: c.status,
        createdAt: c.createdAt,
        message: c.message,
      })),
    });
  } catch (e) {
    console.error("meDetails error:", e);
    return res.status(500).json({ error: "Failed to load profile" });
  }
}

/*
  The following location endpoints existed in your old schema (SavedLocation).
  ERD schema does not contain SavedLocation, so we return 501 (Not implemented).

  Student note:
  - This prevents backend crash
  - You should remove/disable these calls in Flutter OR add SavedLocation to schema if you need it.
*/

export async function createLocation(_req, res) {
  return res.status(501).json({ error: "Saved locations are not available in ERD schema" });
}

export async function updateLocation(_req, res) {
  return res.status(501).json({ error: "Saved locations are not available in ERD schema" });
}

export async function deleteLocation(_req, res) {
  return res.status(501).json({ error: "Saved locations are not available in ERD schema" });
}

export async function setDefaultLocation(_req, res) {
  return res.status(501).json({ error: "Saved locations are not available in ERD schema" });
}