// src/auth/auth.controller.js
import prisma from "../prisma.js";
import { admin } from "../firebaseAdmin.js";

// Student note: convert role string from Flutter into enum used in ERD schema
function normalizeRole(role) {
  const r = String(role || "").toLowerCase().trim();

  if (r === "vendor") return "VENDOR";
  if (r === "resident") return "RESIDENT";
  if (r === "ward admin" || r === "ward_admin" || r === "wardadmin") return "WARD_ADMIN";
  if (r === "admin") return "ADMIN";

  return "RESIDENT";
}

// Student note: Flutter sometimes sends ward name, but ERD uses wardId.
// This helper finds ward by name, and creates it if not exists.
async function getOrCreateWardByName(wardName) {
  const name = String(wardName || "").trim();
  if (!name) return null;

  let ward = await prisma.ward.findFirst({ where: { wardName: name } });
  if (!ward) {
    ward = await prisma.ward.create({ data: { wardName: name } });
  }
  return ward;
}

export async function register(req, res) {
  const authHeader = req.headers.authorization;

  // Student note: Flutter must send Authorization: Bearer <firebaseIdToken>
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No authorization header" });
  }

  const idToken = authHeader.split("Bearer ")[1];

  // Student note: extra fields from Flutter UI
  const { phone, name, role, ward, wardId, companyName } = req.body || {};

  try {
    // Student note: verify firebase token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;
    const email = decodedToken.email || null;

    const roleEnum = normalizeRole(role);

    // Student note: ward can be wardId or ward name
    let finalWardId = null;
    if (wardId != null) {
      finalWardId = Number(wardId);
    } else if (ward) {
      const w = await getOrCreateWardByName(ward);
      finalWardId = w?.id ?? null;
    }

    // IMPORTANT: This requires User.firebaseUid in schema
    let user = await prisma.user.findUnique({
      where: { firebaseUid: uid },
    });

    if (!user) {
      // Student note: create new user record
      user = await prisma.user.create({
        data: {
          firebaseUid: uid,
          email,
          phoneNumber: typeof phone === "string" && phone.trim() ? phone.trim() : null,
          name: typeof name === "string" && name.trim() ? name.trim() : null,
          role: roleEnum,
          wardId: finalWardId,
        },
      });
    } else {
      // Student note: update basic fields (don’t overwrite with empty)
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          email: user.email ?? email,
          phoneNumber: typeof phone === "string" && phone.trim() ? phone.trim() : user.phoneNumber,
          name: typeof name === "string" && name.trim() ? name.trim() : user.name,
          role: roleEnum,
          wardId: finalWardId ?? user.wardId,
        },
      });
    }

    // Student note: if role is VENDOR we must ensure vendor profile row exists
    if (user.role === "VENDOR") {
      const vendor = await prisma.vendor.findUnique({ where: { userId: user.id } });
      if (!vendor) {
        await prisma.vendor.create({
          data: {
            userId: user.id,
            companyName: typeof companyName === "string" && companyName.trim() ? companyName.trim() : null,
            phone: user.phoneNumber ?? null,
          },
        });
      }
    }

    // Student note: return user with ward + vendor info
    const userWithWard = await prisma.user.findUnique({
      where: { id: user.id },
      include: { ward: true, vendorProfile: true },
    });

    return res.json({
      success: true,
      user: {
        id: userWithWard.id,
        firebaseUid: userWithWard.firebaseUid,
        email: userWithWard.email,
        name: userWithWard.name,
        phone: userWithWard.phoneNumber,
        role: userWithWard.role,
        ward: userWithWard.ward
          ? { id: userWithWard.ward.id, name: userWithWard.ward.wardName }
          : null,
        vendor: userWithWard.vendorProfile ? { id: userWithWard.vendorProfile.id } : null,
      },
    });
  } catch (e) {
    console.error("register error:", e);

    // Student note: If token invalid, verifyIdToken throws (401).
    // If prisma errors happen, that is server error (500).
    const msg = String(e?.message || "");

    if (msg.toLowerCase().includes("firebase") || msg.toLowerCase().includes("id token")) {
      return res.status(401).json({ error: "Invalid Firebase token" });
    }

    return res.status(500).json({ error: "Failed to register user" });
  }
}

export async function me(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { ward: true, vendorProfile: true },
    });

    if (!user) return res.status(404).json({ error: "User not found" });

    return res.json({
      id: user.id,
      firebaseUid: user.firebaseUid,
      email: user.email,
      name: user.name,
      phone: user.phoneNumber,
      role: user.role,
      ward: user.ward ? { id: user.ward.id, name: user.ward.wardName } : null,
      vendor: user.vendorProfile ? { id: user.vendorProfile.id } : null,
    });
  } catch (e) {
    console.error("me error:", e);
    return res.status(500).json({ error: "Failed to fetch user profile" });
  }
}

export async function updateProfile(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { name, phone, ward, wardId } = req.body || {};

  try {
    let finalWardId;

    if (wardId != null) finalWardId = Number(wardId);
    else if (ward) {
      const w = await getOrCreateWardByName(ward);
      finalWardId = w?.id;
    }

    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        name: typeof name === "string" && name.trim() ? name.trim() : undefined,
        phoneNumber: typeof phone === "string" && phone.trim() ? phone.trim() : undefined,
        wardId: finalWardId ?? undefined,
      },
      include: { ward: true },
    });

    return res.json({
      message: "Profile updated successfully",
      user: {
        id: updated.id,
        firebaseUid: updated.firebaseUid,
        email: updated.email,
        name: updated.name,
        phone: updated.phoneNumber,
        role: updated.role,
        ward: updated.ward ? { id: updated.ward.id, name: updated.ward.wardName } : null,
      },
    });
  } catch (e) {
    console.error("updateProfile error:", e);
    return res.status(500).json({ error: "Failed to update profile" });
  }
}

// Student note: keep this endpoint for old Flutter calls
export async function updateWard(req, res) {
  return updateProfile(req, res);
}

export async function saveFcmToken(req, res) {
  const userId = Number(req.auth?.sub);
  const { fcmToken, deviceInfo } = req.body || {};

  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!fcmToken || typeof fcmToken !== "string") {
    return res.status(400).json({ error: "Valid FCM token is required" });
  }

  try {
    // Student note: ERD stores multiple tokens per user
    await prisma.fcmToken.upsert({
      where: { token: fcmToken },
      update: {
        userId,
        deviceInfo: typeof deviceInfo === "string" ? deviceInfo : undefined,
      },
      create: {
        userId,
        token: fcmToken,
        deviceInfo: typeof deviceInfo === "string" ? deviceInfo : null,
      },
    });

    return res.json({ message: "FCM token saved successfully" });
  } catch (e) {
    console.error("saveFcmToken error:", e);
    return res.status(500).json({ error: "Failed to save FCM token" });
  }
}