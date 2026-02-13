
import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";

import config from "./config/config.js";

import authRoutes from "./auth/auth.routes.js";
import profileRoutes from "./profile/profile.routes.js";
import notificationRoutes from "./notifications/notification.routes.js";
import scheduleRoutes from "./schedules/schedule.routes.js";
import vendorRoutes from "./vendors/vendor.routes.js";
import bookingRoutes from "./bookings/tankerBooking.routes.js";

const app = express();

app.use(helmet());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan("dev"));

if (config.corsOrigins === "*") {
  app.use(cors());
} else {
  const origins = config.corsOrigins.split(",").map((s) => s.trim());
  app.use(cors({ origin: origins, credentials: true }));
}

app.get("/health", (_req, res) => res.json({ ok: true }));
app.get("/api/health", (_req, res) => res.json({ ok: true }));

// without /api
app.use("/auth", authRoutes);
app.use("/profile", profileRoutes);
app.use("/notifications", notificationRoutes);
app.use("/schedules", scheduleRoutes);
app.use("/vendors", vendorRoutes);
app.use("/bookings", bookingRoutes);
// with /api
app.use("/api/auth", authRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/schedules", scheduleRoutes);
app.use("/api/vendors", vendorRoutes);
app.use("/api/bookings", bookingRoutes);
app.use((req, res) => res.status(404).json({ error: "Route not found" }));

app.use((err, _req, res, _next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({ error: "Server error" });
});

export default app;