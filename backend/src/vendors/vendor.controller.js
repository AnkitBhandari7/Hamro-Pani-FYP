import prisma from "../prisma.js";

// GET /vendors/dashboard
export async function getVendorDashboard(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const user = await prisma.user.findUnique({
    where: { id: Number(userId) },
    select: { role: true },
  });

  if (!user) return res.status(401).json({ error: "User not found" });
  if (String(user.role).toLowerCase() !== "vendor") {
    return res.status(403).json({ error: "Only Vendor can access vendor dashboard" });
  }

  // Vendor bookings (assigned to this vendor)
  const vendorBookings = await prisma.booking.findMany({
    where: { vendorId: Number(userId) },
    orderBy: { createdAt: "desc" },
    include: {
      resident: { select: { name: true, phone: true } },
    },
  });

  // ROUTES: derived from bookings (group by ward)
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

    // If any booking is CONFIRMED/DELIVERING, consider route active
    if (["CONFIRMED", "DELIVERING", "IN_PROGRESS"].includes(String(b.status).toUpperCase())) {
      r.status = "Active";
    }
  }

  const routes = Array.from(routesMap.values());

  //  only PENDING assigned to vendor
  const requests = vendorBookings
    .filter((b) => String(b.status).toUpperCase() === "PENDING")
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