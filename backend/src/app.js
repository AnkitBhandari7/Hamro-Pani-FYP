import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import path from "path";
import multer from "multer";
import config from "./config/config.js";
import authRoutes from "./auth/auth.routes.js";
import profileRoutes from "./profile/profile.routes.js";
import wardAdminProfileRoutes from "./admin/ward_admin_profile.routes.js";
import notificationRoutes from "./notifications/notification.routes.js";
import scheduleRoutes from "./schedules/schedule.routes.js";
import vendorRoutes from "./vendors/vendor.routes.js";
import bookingRoutes from "./bookings/tankerBooking.routes.js";
import tankerRoutes from "./bookings/tanker/tanker.routes.js";
import complaintRouter from "./complaints/complaint.routes.js";
import paymentRoutes from "./payments/payment.routes.js";

const app = express();

app.use(helmet());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan("dev"));

// Serve uploaded images
app.use("/uploads", express.static(path.resolve("uploads")));

if (config.corsOrigins === "*") {
  app.use(cors());
} else {
  const origins = config.corsOrigins.split(",").map((s) => s.trim());
  app.use(cors({ origin: origins, credentials: true }));
}

app.get("/health", (_req, res) => res.json({ ok: true }));
app.get("/api/health", (_req, res) => res.json({ ok: true }));

app.use("/auth", authRoutes);
app.use("/profile", profileRoutes);

// Ward Admin profile endpoints
app.use("/admin/profile", wardAdminProfileRoutes);

app.use("/notifications", notificationRoutes);
app.use("/schedules", scheduleRoutes);
app.use("/vendors", vendorRoutes);
app.use("/bookings", bookingRoutes);
app.use("/tankers", tankerRoutes);
app.use("/complaints", complaintRouter);
app.use("/payments", paymentRoutes);

// with /api

app.use("/api/auth", authRoutes);
app.use("/api/profile", profileRoutes);

// Ward Admin profile endpoints
app.use("/api/admin/profile", wardAdminProfileRoutes);

app.use("/api/notifications", notificationRoutes);
app.use("/api/schedules", scheduleRoutes);
app.use("/api/vendors", vendorRoutes);
app.use("/api/bookings", bookingRoutes);

app.use("/api/tankers", tankerRoutes);

app.use((req, res) => res.status(404).json({ error: "Route not found" }));

// Global error handler
app.use((err, _req, res, _next) => {
  console.error("Unhandled error:", err);

  // Multer errors
  if (err instanceof multer.MulterError) {
    return res.status(400).json({ error: err.message });
  }

  // Custom errors
  if (err?.statusCode) {
    return res.status(err.statusCode).json({ error: err.message });
  }

  // Default
  return res.status(500).json({ error: "Server error" });
});

export default app;