import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";

import multer from "multer";
import path from "path";
import fs from "fs";

import {
  getVendorDashboard,
  createRoute,
  getMyRoutes,
  createSlot,
  listSlotsByWardAndDate,
  updateBookingStatus,
   updateSlot,
  markSlotFull,
  deleteSlot,

  // vendor profile endpoints
  getVendorProfileMe,
  updateVendorProfileMe,
  uploadVendorPhotoMe,
  deleteVendorPhotoMe,
} from "./vendor.controller.js";

const router = Router();


// Multer setup for vendor photo upload

const uploadDir = path.resolve("uploads/profile");
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const userId = req.auth?.sub ?? "user";
    const ext = path.extname(file.originalname || "").toLowerCase();
    const safeExt = ext && ext.length <= 10 ? ext : ".jpg";
    cb(null, `vendor_${userId}_${Date.now()}${safeExt}`);
  },
});

const ALLOWED_EXT = new Set([".jpg", ".jpeg", ".png", ".webp"]);
const ALLOWED_MIME = new Set(["image/jpeg", "image/jpg", "image/png", "image/webp", "image/x-png"]);

function fileFilter(_req, file, cb) {
  const mime = String(file.mimetype || "").toLowerCase();
  const ext = path.extname(file.originalname || "").toLowerCase();

  const ok =
    ALLOWED_MIME.has(mime) ||
    ALLOWED_EXT.has(ext) ||
    (mime === "application/octet-stream" && ALLOWED_EXT.has(ext));

  if (!ok) return cb(new Error("Only JPG, PNG, WEBP images are allowed"));
  cb(null, true);
}

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 3 * 1024 * 1024 }, // 3MB
});


// Dashboard
router.get("/dashboard", authenticateFirebase, getVendorDashboard);

// Profile
router.get("/profile/me", authenticateFirebase, getVendorProfileMe);
router.patch("/profile/me", authenticateFirebase, updateVendorProfileMe);

router.post(
  "/profile/me/photo",
  authenticateFirebase,
  (req, res, next) => {
    upload.single("photo")(req, res, (err) => {
      if (err) return res.status(400).json({ error: err.message });
      next();
    });
  },
  uploadVendorPhotoMe
);

router.delete("/profile/me/photo", authenticateFirebase, deleteVendorPhotoMe);


// Routes + Slots

router.post("/routes", authenticateFirebase, createRoute);
router.get("/routes/my", authenticateFirebase, getMyRoutes);

// create slot under route
router.post("/routes/:routeId/slots", authenticateFirebase, createSlot);

router.patch("/slots/:slotId", authenticateFirebase, updateSlot);
router.patch("/slots/:slotId/mark-full", authenticateFirebase, markSlotFull);
router.delete("/slots/:slotId", authenticateFirebase, deleteSlot);

router.get("/slots/ward/:ward", listSlotsByWardAndDate);

// Confirm/Decline booking request
router.patch("/requests/:bookingId", authenticateFirebase, updateBookingStatus);

export default router;