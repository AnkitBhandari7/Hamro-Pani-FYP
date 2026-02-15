import { admin } from "../firebaseAdmin.js";
import prisma from "../prisma.js";

export async function authenticateFirebase(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No authorization header" });
  }

  const idToken = authHeader.split("Bearer ")[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    const user = await prisma.user.findUnique({
      where: { firebaseUid: decodedToken.uid },
      include: { ward: true }, // IMPORTANT
    });

    if (!user) {
      return res.status(401).json({ error: "User not found. Please register first." });
    }

    req.auth = {
      sub: user.id,
      uid: decodedToken.uid,
      email: user.email,
      role: user.role,
      wardId: user.wardId,
      ward: user.ward,
    };

    next();
  } catch (error) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}