const admin = require('firebase-admin');
const config = require('./config/config');

let initialized = false;

function initFirebaseAdmin() {
  if (initialized) return;

  if (config.firebase.projectId && config.firebase.clientEmail && config.firebase.privateKey) {
    admin.initializeApp({
      credential: admin.credential.cert(config.firebase),
    });
  } else {
    console.warn('Using Application Default Credentials. Set GOOGLE_APPLICATION_CREDENTIALS or provide FIREBASE_* env vars.');
    admin.initializeApp();
  }

  initialized = true;
}

module.exports = { admin, initFirebaseAdmin };