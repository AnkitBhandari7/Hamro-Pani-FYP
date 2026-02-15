
import prisma from "../prisma.js";
import fs from "fs";
import path from "path";

// only ward admin/admin can access these endpoints
function isWardAdminOrAdmin(role) {
  return role === "WARD_ADMIN" || role === "ADMIN";
}

// safely read user id from firebase middleware
function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

// build absolute URL for Flutter
function toAbsoluteUrl(req, publicPath) {
  if (!publicPath) return "";
  // if already absolute
  if (String(publicPath).startsWith("http://") || String(publicPath).startsWith("https://")) {
    return String(publicPath);
  }
  const base = `${req.protocol}://${req.get("host")}`;
  const p = String(publicPath).startsWith("/") ? String(publicPath) : `/${publicPath}`;
  return `${base}${p}`;
}

// publicPath can be stored as:
//   "/uploads/profile/abc.png"
//   "http://host/uploads/profile/abc.png"
function getUploadAbsolutePathFromStoredUrl(stored) {
  if (!stored) return null;

  let p = String(stored);

  // remove domain if present
  const idx = p.indexOf("/uploads/");
  if (idx === -1) return null;

  // "/uploads/profile/abc.png"
  const publicPath = p.substring(idx);

  // convert to local file system path: "<project>/uploads/profile/abc.png"
  return path.resolve(publicPath.replace(/^\//, ""));
}

function tryDeleteOldUpload(storedUrlOrPath) {
  const abs = getUploadAbsolutePathFromStoredUrl(storedUrlOrPath);
  if (!abs) return;

  try {
    if (fs.existsSync(abs)) fs.unlinkSync(abs);
  } catch (e) {
    console.warn("Failed to delete old upload:", abs, e.message);
  }
}

// GET /admin/profile/me
export async function getWardAdminProfile(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { ward: true },
    });

    if (!user) return res.status(404).json({ error: "User not found" });
    if (!isWardAdminOrAdmin(user.role)) {
      return res.status(403).json({ error: "Forbidden (Ward Admin only)" });
    }

    return res.json({
      id: user.id,
      name: user.name ?? "",
      email: user.email ?? "",
      phone: user.phoneNumber ?? "",
      role: user.role,

      // ward admin normally has no ward => will be null
      ward: user.ward ? { id: user.ward.id, name: user.ward.wardName } : null,

      //  return absolute URL to Flutter, but store relative in DB
      profileImageUrl: user.profileImageUrl ? toAbsoluteUrl(req, user.profileImageUrl) : "",
    });
  } catch (e) {
    console.error("getWardAdminProfile error:", e);
    return res.status(500).json({ error: "Failed to load ward admin profile" });
  }
}

// PATCH /admin/profile/me
export async function updateWardAdminProfile(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { name, phone } = req.body || {};

  try {
    const me = await prisma.user.findUnique({ where: { id: userId } });
    if (!me) return res.status(404).json({ error: "User not found" });
    if (!isWardAdminOrAdmin(me.role)) {
      return res.status(403).json({ error: "Forbidden (Ward Admin only)" });
    }

    // Ward admin should not have wardId -> always null
    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        name: typeof name === "string" && name.trim() ? name.trim() : undefined,
        phoneNumber: typeof phone === "string" && phone.trim() ? phone.trim() : undefined,
        wardId: null,
      },
      include: { ward: true },
    });

    return res.json({
      message: "Ward admin profile updated",
      user: {
        id: updated.id,
        name: updated.name ?? "",
        email: updated.email ?? "",
        phone: updated.phoneNumber ?? "",
        role: updated.role,
        ward: updated.ward ? { id: updated.ward.id, name: updated.ward.wardName } : null,
        profileImageUrl: updated.profileImageUrl ? toAbsoluteUrl(req, updated.profileImageUrl) : "",
      },
    });
  } catch (e) {
    console.error("updateWardAdminProfile error:", e);
    return res.status(500).json({ error: "Failed to update ward admin profile" });
  }
}

// POST /admin/profile/me/photo
export async function uploadWardAdminPhoto(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!req.file) return res.status(400).json({ error: "photo file is required" });

  try {
    const me = await prisma.user.findUnique({ where: { id: userId } });
    if (!me) return res.status(404).json({ error: "User not found" });
    if (!isWardAdminOrAdmin(me.role)) {
      return res.status(403).json({ error: "Forbidden (Ward Admin only)" });
    }

    // delete old photo if any
    tryDeleteOldUpload(me.profileImageUrl);

    //  PUBLIC path
    const publicPath = `/uploads/profile/${req.file.filename}`;

    const updated = await prisma.user.update({
      where: { id: userId },
      data: { profileImageUrl: publicPath },
    });

    return res.json({
      message: "Photo uploaded",
      // return absolute URL so Flutter Image.network works directly
      profileImageUrl: toAbsoluteUrl(req, updated.profileImageUrl),
    });
  } catch (e) {
    console.error("uploadWardAdminPhoto error:", e);
    return res.status(500).json({ error: "Failed to upload photo" });
  }
}

// DELETE /admin/profile/me/photo
export async function deleteWardAdminPhoto(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const me = await prisma.user.findUnique({ where: { id: userId } });
    if (!me) return res.status(404).json({ error: "User not found" });
    if (!isWardAdminOrAdmin(me.role)) {
      return res.status(403).json({ error: "Forbidden (Ward Admin only)" });
    }

    tryDeleteOldUpload(me.profileImageUrl);

    await prisma.user.update({
      where: { id: userId },
      data: { profileImageUrl: null },
    });

    return res.json({ message: "Photo deleted" });
  } catch (e) {
    console.error("deleteWardAdminPhoto error:", e);
    return res.status(500).json({ error: "Failed to delete photo" });
  }
}

// GET /admin/profile/me/export
export async function exportWardAdminProfile(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { ward: true },
    });

    if (!user) return res.status(404).json({ error: "User not found" });
    if (!isWardAdminOrAdmin(user.role)) {
      return res.status(403).json({ error: "Forbidden (Ward Admin only)" });
    }

    const payload = {
      id: user.id,
      firebaseUid: user.firebaseUid,
      name: user.name,
      email: user.email,
      phone: user.phoneNumber,
      role: user.role,
      ward: user.ward ? { id: user.ward.id, name: user.ward.wardName } : null,
      profileImageUrl: user.profileImageUrl ? toAbsoluteUrl(req, user.profileImageUrl) : "",
      exportedAt: new Date().toISOString(),
    };

    res.setHeader("Content-Type", "application/json");
    res.setHeader("Content-Disposition", `attachment; filename="ward_admin_profile_${user.id}.json"`);
    return res.send(JSON.stringify(payload, null, 2));
  } catch (e) {
    console.error("exportWardAdminProfile error:", e);
    return res.status(500).json({ error: "Failed to export profile" });
  }
}