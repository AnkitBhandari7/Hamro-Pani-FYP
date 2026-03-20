import prisma from "../../prisma.js";
import { admin } from "../../firebaseAdmin.js";


// Role normalization

function normalizeRole(role) {
  const r = String(role || "").toLowerCase().trim();

  if (r === "vendor") return "VENDOR";
  if (r === "resident") return "RESIDENT";
  if (r === "ward admin" || r === "ward_admin" || r === "wardadmin") return "WARD_ADMIN";
  if (r === "admin") return "ADMIN";

  return "RESIDENT";
}


// Ward name normalization helpers

function extractWardNumber(s) {
  const m = String(s || "").match(/\d+/);
  return m ? Number(m[0]) : null;
}

function extractCity(s) {
  const lower = String(s || "").toLowerCase();
  if (lower.includes("kathmandu")) return "Kathmandu";
  if (lower.includes("lalitpur")) return "Lalitpur";
  if (lower.includes("bhaktapur")) return "Bhaktapur";
  return null;
}

function canonicalWardName(input) {
  const raw = String(input || "").trim();
  if (!raw) return "";

  const n = extractWardNumber(raw);
  const city = extractCity(raw) ?? "Kathmandu";

  if (n != null && Number.isFinite(n)) return `${city} Ward ${n}`;
  return raw;
}

async function getOrCreateWardByNameTx(tx, wardName) {
  const canonical = canonicalWardName(wardName);
  if (!canonical) return null;

  let ward = await tx.ward.findFirst({ where: { wardName: canonical } });
  if (ward) return ward;


  const n = extractWardNumber(canonical);
  const city = extractCity(canonical);

  if (n != null && city) {
    const candidates = await tx.ward.findMany({
      where: { wardName: { contains: String(n) } },
      select: { id: true, wardName: true },
    });

    const found = candidates.find((w) => {
      const wn = w.wardName.toLowerCase();
      return wn.includes(city.toLowerCase()) && wn.includes("ward") && wn.includes(String(n));
    });

    if (found) return tx.ward.findUnique({ where: { id: found.id } });
  }

  ward = await tx.ward.create({ data: { wardName: canonical } });
  return ward;
}

function hasNonEmptyString(x) {
  return typeof x === "string" && x.trim().length > 0;
}

function isProvided(x) {
  return x !== undefined && x !== null && String(x).trim() !== "";
}


// POST /auth/register

export async function register(req, res) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No authorization header" });
  }

  const idToken = authHeader.split("Bearer ")[1];

  const { phone, name, role, ward, wardId, companyName } = req.body || {};

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const uid = decodedToken.uid;
    const email = decodedToken.email || null;

    const roleEnum = normalizeRole(role);

    const user = await prisma.$transaction(async (tx) => {


      // ward is OPTIONAL at registration (can set later in profile)
      // Also If user already has ward in DB and register is called again
      // without ward info, we DO NOT overwrite their ward with null.

      let finalWardId = null;
      let wardInputProvided = false;

      if (roleEnum === "RESIDENT") {
        if (isProvided(wardId)) {
          wardInputProvided = true;

          const n = Number(wardId);
          if (!Number.isFinite(n)) {
            const err = new Error("wardId must be a number");
            err.statusCode = 400;
            throw err;
          }

          const exists = await tx.ward.findUnique({ where: { id: n } });
          if (!exists) {
            const err = new Error("Invalid wardId");
            err.statusCode = 400;
            throw err;
          }

          finalWardId = n;
        } else if (hasNonEmptyString(ward)) {
          wardInputProvided = true;
          const w = await getOrCreateWardByNameTx(tx, ward);
          finalWardId = w?.id ?? null;
        } else {
          // resident can register with no ward
          finalWardId = null;
          wardInputProvided = false;
        }
      } else if (roleEnum === "WARD_ADMIN") {
        // ward admin never has ward in user table
        finalWardId = null;
        wardInputProvided = true; // we will force clear on update
      } else {

        finalWardId = null;
        wardInputProvided = true; // force clear
      }


      // Find user by firebaseUid, else by email

      let u = await tx.user.findUnique({ where: { firebaseUid: uid } });

      if (!u && email) {
        u = await tx.user.findUnique({ where: { email } });
        if (u) {
          u = await tx.user.update({
            where: { id: u.id },
            data: { firebaseUid: uid },
          });
        }
      }


      // Create or update

      if (!u) {
        u = await tx.user.create({
          data: {
            firebaseUid: uid,
            email,
            phoneNumber: hasNonEmptyString(phone) ? phone.trim() : null,
            name: hasNonEmptyString(name) ? name.trim() : null,
            role: roleEnum,
            wardId: roleEnum === "RESIDENT" ? finalWardId : null,
          },
        });
      } else {

        const wardIdUpdate =
          roleEnum === "RESIDENT"
            ? (wardInputProvided ? finalWardId : undefined)
            : null;

        u = await tx.user.update({
          where: { id: u.id },
          data: {
            email: u.email ?? email,
            phoneNumber: hasNonEmptyString(phone) ? phone.trim() : u.phoneNumber,
            name: hasNonEmptyString(name) ? name.trim() : u.name,
            role: roleEnum,
            wardId: wardIdUpdate,
          },
        });
      }

      // Vendor profile
      if (u.role === "VENDOR") {
        const vendor = await tx.vendor.findUnique({ where: { userId: u.id } });
        if (!vendor) {
          await tx.vendor.create({
            data: {
              userId: u.id,
              companyName: hasNonEmptyString(companyName) ? companyName.trim() : null,
              phone: u.phoneNumber ?? null,
            },
          });
        }
      }

      return u;
    });

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

    if (e?.statusCode === 400) return res.status(400).json({ error: e.message });

    if (e?.code === "P2002") {
      return res.status(409).json({ error: "Unique constraint failed", detail: e?.meta });
    }

    const msg = String(e?.message || "");
    if (msg.toLowerCase().includes("firebase") || msg.toLowerCase().includes("id token")) {
      return res.status(401).json({ error: "Invalid Firebase token" });
    }

    return res.status(500).json({ error: "Failed to register user" });
  }
}


// GET /auth/me

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


// PATCH /auth/update-profile

export async function updateProfile(req, res) {
  const userId = Number(req.auth?.sub);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const { name, phone, ward, wardId, language } = req.body || {};

  try {
    //  get role because ward update rules depend on role
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });
    if (!me) return res.status(401).json({ error: "Unauthorized" });

    //  Ward update logic
    let wardIdUpdate = undefined;

    if (me.role === "RESIDENT") {
      if (isProvided(wardId)) {
        const n = Number(wardId);
        if (!Number.isFinite(n)) return res.status(400).json({ error: "wardId must be a number" });

        const exists = await prisma.ward.findUnique({ where: { id: n } });
        if (!exists) return res.status(400).json({ error: "Invalid wardId" });

        wardIdUpdate = n;
      } else if (hasNonEmptyString(ward)) {
        const w = await prisma.$transaction((tx) => getOrCreateWardByNameTx(tx, ward));
        wardIdUpdate = w?.id;
      } else {
        wardIdUpdate = undefined;
      }
    } else {
      wardIdUpdate = null; // non-resident must always be null
    }

    // Language update logic
    let languageUpdate = undefined;
    if (typeof language === "string" && language.trim()) {
      const lang = language.trim().toUpperCase();
      if (!["EN", "NP"].includes(lang)) {
        return res.status(400).json({ error: "language must be EN or NP" });
      }
      languageUpdate = lang;
    }

    const updated = await prisma.user.update({
      where: { id: userId },
      data: {
        name: hasNonEmptyString(name) ? name.trim() : undefined,
        phoneNumber: hasNonEmptyString(phone) ? phone.trim() : undefined,
        wardId: wardIdUpdate,
        language: languageUpdate,
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
        language: updated.language,
        ward: updated.ward ? { id: updated.ward.id, name: updated.ward.wardName } : null,
      },
    });
  } catch (e) {
    console.error("updateProfile error:", e);
    return res.status(500).json({ error: "Failed to update profile" });
  }
}

export async function updateWard(req, res) {
  return updateProfile(req, res);
}

// POST /auth/save-fcm-token

export async function saveFcmToken(req, res) {
  const userId = Number(req.auth?.sub);
  const { fcmToken, deviceInfo } = req.body || {};

  if (!userId) return res.status(401).json({ error: "Unauthorized" });
  if (!fcmToken || typeof fcmToken !== "string") {
    return res.status(400).json({ error: "Valid FCM token is required" });
  }

  try {
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