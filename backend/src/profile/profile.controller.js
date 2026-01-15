import prisma from "../prisma.js";

export async function meDetails(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const user = await prisma.user.findUnique({
    where: { id: Number(userId) },
    select: {
      id: true,
      email: true,
      name: true,
      phone: true,
      role: true,
      ward: true,
      savedLocations: { orderBy: [{ isDefault: "desc" }, { updatedAt: "desc" }] },
      residentBookings: {
        orderBy: { createdAt: "desc" },
        take: 10,
        select: { id: true, status: true, liters: true, price: true, createdAt: true },
      },
      issues: {
        orderBy: { createdAt: "desc" },
        take: 10,
        select: { id: true, title: true, status: true, createdAt: true },
      },
    },
  });

  if (!user) return res.status(404).json({ error: "User not found" });

  return res.json({
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      role: user.role,
      ward: user.ward,
    },
    locations: user.savedLocations,
    bookings: user.residentBookings,
    issues: user.issues,
  });
}

export async function createLocation(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { title, address } = req.body || {};
  if (!title || !address) return res.status(400).json({ error: "title and address are required" });

  const count = await prisma.savedLocation.count({ where: { userId: Number(userId) } });

  const location = await prisma.savedLocation.create({
    data: {
      userId: Number(userId),
      title: title.trim(),
      address: address.trim(),
      isDefault: count === 0,
    },
  });

  return res.status(201).json(location);
}

export async function updateLocation(req, res) {
  const userId = req.auth?.sub;
  const { id } = req.params;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { title, address } = req.body || {};

  const existing = await prisma.savedLocation.findFirst({
    where: { id: Number(id), userId: Number(userId) },
  });

  if (!existing) return res.status(404).json({ error: "Location not found" });

  const updated = await prisma.savedLocation.update({
    where: { id: Number(id) },
    data: {
      ...(typeof title === "string" && title.trim() ? { title: title.trim() } : {}),
      ...(typeof address === "string" && address.trim() ? { address: address.trim() } : {}),
    },
  });

  return res.json(updated);
}

export async function deleteLocation(req, res) {
  const userId = req.auth?.sub;
  const { id } = req.params;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const existing = await prisma.savedLocation.findFirst({
    where: { id: Number(id), userId: Number(userId) },
  });

  if (!existing) return res.status(404).json({ error: "Location not found" });

  await prisma.savedLocation.delete({ where: { id: Number(id) } });

  const remaining = await prisma.savedLocation.findMany({
    where: { userId: Number(userId) },
    orderBy: { updatedAt: "desc" },
  });

  if (remaining.length > 0 && !remaining.some((l) => l.isDefault)) {
    await prisma.savedLocation.update({
      where: { id: remaining[0].id },
      data: { isDefault: true },
    });
  }

  return res.json({ message: "Deleted" });
}

export async function setDefaultLocation(req, res) {
  const userId = req.auth?.sub;
  const { id } = req.params;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const existing = await prisma.savedLocation.findFirst({
    where: { id: Number(id), userId: Number(userId) },
  });

  if (!existing) return res.status(404).json({ error: "Location not found" });

  await prisma.$transaction([
    prisma.savedLocation.updateMany({
      where: { userId: Number(userId) },
      data: { isDefault: false },
    }),
    prisma.savedLocation.update({
      where: { id: Number(id) },
      data: { isDefault: true },
    }),
  ]);

  return res.json({ message: "Default updated" });
}