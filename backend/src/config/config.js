import "dotenv/config";

const config = {
  port: parseInt(process.env.PORT || "3000", 10),
  jwtSecret: process.env.JWT_SECRET || "dev-secret-please-change-in-production",
  corsOrigins: process.env.CORS_ORIGINS || "*",


  publicBaseUrl: (process.env.PUBLIC_BASE_URL || "").trim().replace(/\/+$/, ""),

  firebase: {
    projectId: (process.env.FIREBASE_PROJECT_ID || "").replace(/"/g, ""),
    clientEmail: (process.env.FIREBASE_CLIENT_EMAIL || "").replace(/"/g, ""),
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || "")
      .replace(/\\n/g, "\n")
      .replace(/"/g, ""),
  },
};

export default config;