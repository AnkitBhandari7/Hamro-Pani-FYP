import { admin } from "../../firebaseAdmin.js";
import prisma from "../../prisma.js";

/**
  Auth middleware (Firebase)
 This middleware verifies the Firebase ID token sent from Flutter.
 If token is valid, we find the same user in our database.
 Then we attach the user info to `req.auth` so every protected route can use it.
 If user is not in our DB, we return 404 (Not Found).
 In our app flow, user must be created by calling /auth/register at least once.
 Returning 404 helps the mobile app detect "first time login" and register the user.
 **/

export async function authenticateFirebase(req, res, next) {
  //  Read Authorization header
  const authHeader = req.headers.authorization;

  // Every request must send token like:
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    console.error("DEBUG: 401 - No valid Bearer token header sent. Header was:", authHeader);
    return res.status(401).json({ error: "No authorization header" });
  }

  // Extract token from "Bearer <token>"
  const idToken = authHeader.split("Bearer ")[1]?.trim();
  if (!idToken) {
    console.error("DEBUG: 401 - Token extraction failed/missing.");
    return res.status(401).json({ error: "Missing token" });
  }

  try {
    // Verify Firebase token (checks signature + expiry)
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    // Find the user in our DB by firebaseUid
    // I also include ward so that `/auth/me` can return ward info easily.
    const user = await prisma.user.findUnique({
      where: { firebaseUid: decodedToken.uid },
      include: { ward: true },
    });

    // If user does not exist in DB, it means they never registered in backend
    // we return 404 so mobile app can call /auth/register and create the user.
    if (!user) {
      return res.status(404).json({ error: "User not found. Please register first." });
    }

    // Attach auth info to request for next controllers/routes
    req.auth = {
      sub: user.id,                 // internal DB user id
      uid: decodedToken.uid,        // firebase uid
      email: user.email,            // email from DB (or Firebase)
      role: user.role,              // role-based access (RESIDENT/VENDOR/WARD_ADMIN)
      wardId: user.wardId,          //  ward foreign key (nullable)
      ward: user.ward,              // ward object (nullable)
    };


    next();
  } catch (error) {
    // Token invalid / expired / other error
    console.error("CRITICAL DEBUG: authenticateFirebase verifyIdToken error:", error);
    return res.status(401).json({ error: "Invalid or expired token", trace: error.message });
  }
}