import prisma from "../prisma.js";
import { admin } from "../firebaseAdmin.js";

export async function register(req, res) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No authorization header" });
  }

  const idToken = authHeader.split("Bearer ")[1];
  const { phone, name, role } = req.body || {};

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;
    const email = decodedToken.email || null;

    let user = await prisma.user.findUnique({ where: { firebaseUid: uid } });

    if (user) {
      const updateData = {};
      if (!user.email && email) updateData.email = email;

      if (Object.keys(updateData).length > 0) {
        user = await prisma.user.update({
          where: { firebaseUid: uid },
          data: updateData,
        });
      }
    } else {
      user = await prisma.user.create({
        data: {
          firebaseUid: uid,
          email,
          phone: typeof phone === "string" && phone.trim() ? phone.trim() : null,
          name: typeof name === "string" && name.trim() ? name.trim() : null,
          role: role || "Resident",
        },
      });
    }

    return res.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        role: user.role,
        ward: user.ward,
      },
    });
  } catch (e) {
    return res.status(401).json({ error: "Invalid Firebase token" });
  }
}

export async function me(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const user = await prisma.user.findUnique({
      where: { id: Number(userId) },
      select: { id: true, email: true, name: true, phone: true, role: true, ward: true },
    });

    if (!user) return res.status(404).json({ error: "User not found" });
    return res.json(user);
  } catch (e) {
    return res.status(500).json({ error: "Failed to fetch user profile" });
  }
}

export async function updateProfile(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { name, phone, ward } = req.body || {};
  const data = {};

  if (typeof name === "string" && name.trim()) data.name = name.trim();
  if (typeof phone === "string" && phone.trim()) data.phone = phone.trim();
  if (typeof ward === "string" && ward.trim()) data.ward = ward.trim();

  if (Object.keys(data).length === 0) {
    return res.status(400).json({ error: "Nothing to update" });
  }

  try {
    const updatedUser = await prisma.user.update({
      where: { id: Number(userId) },
      data,
      select: { id: true, name: true, phone: true, email: true, role: true, ward: true },
    });

    return res.json({ message: "Profile updated successfully", user: updatedUser });
  } catch (e) {
    return res.status(500).json({ error: "Failed to update profile" });
  }
}

export async function updateWard(req, res) {
  const userId = req.auth?.sub;
  const { ward } = req.body || {};

  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!ward || typeof ward !== "string") return res.status(400).json({ error: "Valid ward is required" });

  try {
    const updatedUser = await prisma.user.update({
      where: { id: Number(userId) },
      data: { ward: ward.trim() },
      select: { id: true, name: true, phone: true, email: true, role: true, ward: true },
    });

    return res.json({ message: "Ward updated successfully", user: updatedUser });
  } catch (e) {
    return res.status(500).json({ error: "Failed to update ward" });
  }
}

export async function saveFcmToken(req, res) {
  const userId = req.auth?.sub;
  const { fcmToken } = req.body || {};

  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!fcmToken || typeof fcmToken !== "string") {
    return res.status(400).json({ error: "Valid FCM token is required" });
  }

  try {
    await prisma.user.update({
      where: { id: Number(userId) },
      data: { fcmToken },
    });

    return res.json({ message: "FCM token saved successfully" });
  } catch (e) {
    return res.status(500).json({ error: "Failed to save FCM token" });
  }
}