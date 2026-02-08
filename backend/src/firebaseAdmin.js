import admin from "firebase-admin";
import config from "./config/config.js";

let initialized = false;

export function initFirebaseAdmin() {
  if (initialized || admin.apps.length > 0) return admin;

  const { projectId, clientEmail, privateKey } = config.firebase;

  if (projectId && clientEmail && privateKey) {
    admin.initializeApp({
      credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
    });
    console.log("Firebase Admin initialized (from .env)");
  } else {
    console.warn("Firebase Admin: Missing env vars. Initializing without cert.");
    admin.initializeApp();
  }

  initialized = true;
  return admin;
}

// init immediately
initFirebaseAdmin();

export { admin };