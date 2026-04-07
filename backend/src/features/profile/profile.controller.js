import prisma from "../../prisma.js";
import fs from "fs";
import path from "path";

function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

function toAbsoluteUrl(req, storedPath) {
  if (!storedPath) return "";
  const s = String(storedPath);
  if (s.startsWith("http://") || s.startsWith("https://")) return s;

  const base = `${req.protocol}://${req.get("host")}`;
  const p = s.startsWith("/") ? s : `/${s}`;
  return `${base}${p}`;
}

function getUploadAbsolutePathFromStoredUrl(stored) {
  if (!stored) return null;
  const s = String(stored);
  const idx = s.indexOf("/uploads/");
  if (idx === -1) return null;

  const publicPath = s.substring(idx);
  return path.resolve(publicPath.replace(/^\//, ""));
}

function tryDeleteOldUpload(stored) {
  const abs = getUploadAbsolutePathFromStoredUrl(stored);
  if (!abs) return;
  try {
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
  } catch (e) {
    console.warn("Failed to delete old profile image:", e.message);
  }
}

/*
  GET /profile/me
*/
export async function meDetails(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        ward: true,
        locations: { orderBy: [{ isDefault: "desc" }, { updatedAt: "desc" }] },
      },
    });

    if (!user) return res.status(404).json({ error: "User not found" });

    const bookings = await prisma.booking.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 50,
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

    const complaints = await prisma.complaint.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      take: 50,
      select: { id: true, message: true, status: true, createdAt: true },
    });

    return res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phoneNumber,
        role: user.role,
        ward: user.ward ? user.ward.wardName : null,
        language: user.language,
        profileImageUrl: user.profileImageUrl ? toAbsoluteUrl(req, user.profileImageUrl) : "",
      },

      locations: user.locations.map((l) => ({
        id: l.id,
        label: l.label,
        lat: l.lat,
          lng: l.lng,
        address: l.address,
        isDefault: l.isDefault,
        createdAt: l.createdAt,
        updatedAt: l.updatedAt,
      })),

      bookings: bookings.map((b) => ({
        id: b.id,
        status: b.status,
        createdAt: b.createdAt,
        slotId: b.slotId,
        slotStartTime: b.slot?.startTime,
        slotEndTime: b.slot?.endTime,
        routeLocation: b.slot?.route?.location ?? null,
        ward: b.slot?.route?.ward?.wardName ?? null,
        vendorName: b.slot?.route?.vendor?.user?.name ?? null,
      })),

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
  POST /profile/locations
*/
export async function createLocation(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { label, address, isDefault, lat, lng } = req.body || {};

  const latNum = Number(lat);
  const lngNum = Number(lng);

  if (!Number.isFinite(latNum) || !Number.isFinite(lngNum)) {
    return res.status(400).json({ error: "lat and lng are required and must be numbers" });
  }
  if (typeof label !== "string" || !label.trim()) {
    return res.status(400).json({ error: "label is required" });
  }
  if (typeof address !== "string" || !address.trim()) {
    return res.status(400).json({ error: "address is required" });
  }

  try {
    const created = await prisma.$transaction(async (tx) => {
      const makeDefault = isDefault === true;

      if (makeDefault) {
        await tx.savedLocation.updateMany({
          where: { userId },
          data: { isDefault: false },
        });
      }

      return tx.savedLocation.create({
        data: {
          userId,
          label: label.trim(),
          address: address.trim(),
          lat: latNum,
          lng: lngNum,
          isDefault: makeDefault,
        },
      });
    });

    return res.status(201).json({
      id: created.id,
      label: created.label,
      address: created.address,
      lat: created.lat,
      lng: created.lng,
      isDefault: created.isDefault,
      createdAt: created.createdAt,
      updatedAt: created.updatedAt,
    });
  } catch (e) {
    console.error("createLocation error:", e);
    return res.status(500).json({ error: "Failed to create location" });
  }
}

/*
  PATCH /profile/locations/:id
*/
export async function updateLocation(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ error: "Invalid id" });

  const { label, address, lat, lng } = req.body || {};

  if (label == null && address == null && lat == null && lng == null) {
    return res.status(400).json({ error: "Nothing to update" });
  }

  let latUpdate = undefined;
  let lngUpdate = undefined;

  if (lat !== undefined) {
    const n = Number(lat);
    if (!Number.isFinite(n)) return res.status(400).json({ error: "lat must be a number" });
    latUpdate = n;
  }
  if (lng !== undefined) {
    const n = Number(lng);
    if (!Number.isFinite(n)) return res.status(400).json({ error: "lng must be a number" });
    lngUpdate = n;
  }

  try {
    const existing = await prisma.savedLocation.findFirst({ where: { id, userId } });
    if (!existing) return res.status(404).json({ error: "Location not found" });

    const updated = await prisma.savedLocation.update({
      where: { id },
      data: {
        label: typeof label === "string" && label.trim() ? label.trim() : undefined,
        address: typeof address === "string" && address.trim() ? address.trim() : undefined,
        lat: latUpdate,
        lng: lngUpdate,
      },
    });

    return res.json(updated);
  } catch (e) {
    console.error("updateLocation error:", e);
    return res.status(500).json({ error: "Failed to update location" });
  }
}

/*
  DELETE /profile/locations/:id
*/
export async function deleteLocation(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ error: "Invalid id" });

  try {
    const existing = await prisma.savedLocation.findFirst({ where: { id, userId } });
    if (!existing) return res.status(404).json({ error: "Location not found" });

    await prisma.savedLocation.delete({ where: { id } });

    if (existing.isDefault) {
      const latest = await prisma.savedLocation.findFirst({
        where: { userId },
        orderBy: { updatedAt: "desc" },
      });
      if (latest) {
        await prisma.savedLocation.update({ where: { id: latest.id }, data: { isDefault: true } });
      }
    }

    return res.json({ success: true });
  } catch (e) {
    console.error("deleteLocation error:", e);
    return res.status(500).json({ error: "Failed to delete location" });
  }
}

/*
  PATCH /profile/locations/:id/default
*/
export async function setDefaultLocation(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const id = Number(req.params.id);
  if (!Number.isFinite(id)) return res.status(400).json({ error: "Invalid id" });

  try {
    const existing = await prisma.savedLocation.findFirst({ where: { id, userId } });
    if (!existing) return res.status(404).json({ error: "Location not found" });

    await prisma.$transaction(async (tx) => {
      await tx.savedLocation.updateMany({ where: { userId }, data: { isDefault: false } });
      await tx.savedLocation.update({ where: { id }, data: { isDefault: true } });
    });

    return res.json({ success: true });
  } catch (e) {
    console.error("setDefaultLocation error:", e);
    return res.status(500).json({ error: "Failed to set default location" });
  }
}


export async function uploadMyPhoto(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!req.file) return res.status(400).json({ error: "photo file is required" });

  try {
    const me = await prisma.user.findUnique({ where: { id: userId } });
    if (!me) return res.status(404).json({ error: "User not found" });

    if (me.role !== "RESIDENT") {
      return res.status(403).json({ error: "Only RESIDENT can upload photo here" });
    }

    tryDeleteOldUpload(me.profileImageUrl);

    const publicPath = `/uploads/profile/${req.file.filename}`;

    const updated = await prisma.user.update({
      where: { id: userId },
      data: { profileImageUrl: publicPath },
      select: { profileImageUrl: true },
    });

    return res.json({
      message: "Photo uploaded",
      profileImageUrl: toAbsoluteUrl(req, updated.profileImageUrl),
    });
  } catch (e) {
    console.error("uploadMyPhoto error:", e);
    return res.status(500).json({ error: "Failed to upload photo" });
  }
}

export async function deleteMyPhoto(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const me = await prisma.user.findUnique({ where: { id: userId } });
    if (!me) return res.status(404).json({ error: "User not found" });

    if (me.role !== "RESIDENT") {
      return res.status(403).json({ error: "Only RESIDENT can delete photo here" });
    }

    tryDeleteOldUpload(me.profileImageUrl);

    await prisma.user.update({
      where: { id: userId },
      data: { profileImageUrl: null },
    });

    return res.json({ message: "Photo deleted" });
  } catch (e) {
    console.error("deleteMyPhoto error:", e);
    return res.status(500).json({ error: "Failed to delete photo" });
  }
}

/*
  PATCH /profile/me/photo-url
  Accepts a Firebase Storage HTTPS URL and persists it to the database.
  Replaces the old multer file-upload flow (Render ephemeral storage → 404s).
*/
export async function updateMyPhotoUrl(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { photoUrl } = req.body || {};
  if (typeof photoUrl !== "string" || !photoUrl.startsWith("https://")) {
    return res.status(400).json({ error: "photoUrl must be an HTTPS URL" });
  }

  try {
    const me = await prisma.user.findUnique({ where: { id: userId } });
    if (!me) return res.status(404).json({ error: "User not found" });

    await prisma.user.update({
      where: { id: userId },
      data: { profileImageUrl: photoUrl },
    });

    return res.json({ success: true, profileImageUrl: photoUrl });
  } catch (e) {
    console.error("updateMyPhotoUrl error:", e);
    return res.status(500).json({ error: "Failed to save photo URL" });
  }
}