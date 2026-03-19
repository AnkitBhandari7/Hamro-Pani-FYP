import { admin } from "../firebaseAdmin.js";
import prisma from "../prisma.js";

/**
 * Auth middleware (Firebase)
 * ------------------------------------
 * Student Notes:
 * - This middleware verifies the Firebase ID token sent from Flutter.
 * - If token is valid, we find the same user in our database (Prisma).
 * - Then we attach the user info to `req.auth` so every protected route can use it.
 * - IMPORTANT: If user is not in our DB, we return 404 (Not Found).
 *   Reason: In our app flow, user must be created by calling /auth/register at least once.
 *   Returning 404 helps the mobile app detect "first time login" and register the user.
 */
export async function authenticateFirebase(req, res, next) {
  // 1) Read Authorization header
  const authHeader = req.headers.authorization;

  // Student: Every request must send token like:
  // Authorization: Bearer <FIREBASE_ID_TOKEN>
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "No authorization header" });
  }

  // 2) Extract token from "Bearer <token>"
  const idToken = authHeader.split("Bearer ")[1]?.trim();
  if (!idToken) {
    return res.status(401).json({ error: "Missing token" });
  }

  try {
    // 3) Verify Firebase token (checks signature + expiry)
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    // 4) Find the user in our DB by firebaseUid
    // Student: We also include ward so that `/auth/me` can return ward info easily.
    const user = await prisma.user.findUnique({
      where: { firebaseUid: decodedToken.uid },
      include: { ward: true },
    });

    // 5) If user does not exist in DB, it means they never registered in backend
    // Student: we return 404 so mobile app can call /auth/register and create the user.
    if (!user) {
      return res.status(404).json({ error: "User not found. Please register first." });
    }

    // 6) Attach auth info to request for next controllers/routes
    req.auth = {
      sub: user.id,                 // Student: internal DB user id (used for Prisma queries)
      uid: decodedToken.uid,        // Student: firebase uid
      email: user.email,            // Student: email from DB (or Firebase)
      role: user.role,              // Student: role-based access (RESIDENT/VENDOR/WARD_ADMIN)
      wardId: user.wardId,          // Student: ward foreign key (nullable)
      ward: user.ward,              // Student: ward object (nullable)
    };

    // 7) Continue to actual API route handler
    next();
  } catch (error) {
    // Student: Token invalid / expired / malformed
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}