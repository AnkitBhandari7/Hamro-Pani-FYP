import { admin } from "../firebaseAdmin.js";
import prisma from "../prisma.js";

// Checks Firebase token + finds user in DB
export async function authenticateFirebase(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No authorization header" });
  }

  const idToken = authHeader.split("Bearer ")[1];

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);

    const user = await prisma.user.findUnique({
      where: { firebaseUid: decoded.uid },
    });

    if (!user) {
      return res.status(401).json({ error: "User not found. Please register first." });
    }

    req.auth = {
      sub: user.id,
      uid: decoded.uid,
      email: user.email,
      role: user.role,
      ward: user.ward,
    };

    next();
  } catch (e) {
    console.error("Token verification failed:", e.message);
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}