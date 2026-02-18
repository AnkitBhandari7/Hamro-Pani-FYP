
import prisma from "../prisma.js";
import fs from "fs";
import path from "path";

// helper to safely read user id from token middleware
function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

// convert stored path (/uploads/...) to absolute URL for Flutter
function toAbsoluteUrl(req, storedPath) {
  if (!storedPath) return "";
  const s = String(storedPath);

  // already absolute
  if (s.startsWith("http://") || s.startsWith("https://")) return s;

  const base = `${req.protocol}://${req.get("host")}`;
  const p = s.startsWith("/") ? s : `/${s}`;
  return `${base}${p}`;
}

// handle deleting old photo whether stored as absolute URL or /uploads/...
function getUploadAbsolutePathFromStoredUrl(stored) {
  if (!stored) return null;

  const s = String(stored);
  const idx = s.indexOf("/uploads/");
  if (idx === -1) return null;

  const publicPath = s.substring(idx); // "/uploads/profile/..."
  return path.resolve(publicPath.replace(/^\//, "")); // "uploads/profile/..."
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
  - returns bookings + complaints (issues)
  - now also returns profileImageUrl (absolute)
*/
export async function meDetails(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    // load basic user with ward relation
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { ward: true },
    });

    if (!user) return res.status(404).json({ error: "User not found" });

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

    return res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phoneNumber,
        role: user.role,
        ward: user.ward ? user.ward.wardName : null,


        profileImageUrl: user.profileImageUrl ? toAbsoluteUrl(req, user.profileImageUrl) : "",
      },

      locations: [],

      bookings: bookings.map((b) => ({
        id: b.id,
        status: b.status,
        liters: null,
        price: null,
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

// POST /profile/me/photo
export async function uploadMyPhoto(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!req.file) return res.status(400).json({ error: "photo file is required" });

  try {
    const me = await prisma.user.findUnique({ where: { id: userId } });
    if (!me) return res.status(404).json({ error: "User not found" });

    // optional: only resident uses this endpoint
    if (me.role !== "RESIDENT") {
      return res.status(403).json({ error: "Only RESIDENT can upload photo here" });
    }

    // delete old photo if any
    tryDeleteOldUpload(me.profileImageUrl);

    // store PUBLIC path in DB (not /Users/... path)
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

// DELETE /profile/me/photo
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