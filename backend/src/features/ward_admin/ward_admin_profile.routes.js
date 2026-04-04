import { Router } from "express";
import multer from "multer";
import path from "path";
import fs from "fs";

import { authenticateFirebase } from "../auth/auth.middleware.js";
import {
  getWardAdminProfile,
  updateWardAdminProfile,
  uploadWardAdminPhoto,
  deleteWardAdminPhoto,
  exportWardAdminProfile,
} from "./ward_admin_profile.controller.js";

const router = Router();

const uploadDir = path.resolve("uploads/profile");
fs.mkdirSync(uploadDir, { recursive: true });

// Store profile photos locally
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const userId = req.auth?.sub ?? "user";
    const ext = path.extname(file.originalname || "").toLowerCase();
    const safeExt = ext && ext.length <= 10 ? ext : ".jpg";
    cb(null, `profile_${userId}_${Date.now()}${safeExt}`);
  },
});

const ALLOWED_EXT = new Set([".jpg", ".jpeg", ".png", ".webp"]);
const ALLOWED_MIME = new Set([
  "image/jpeg",
  "image/jpg",
  "image/png",
  "image/x-png",
  "image/webp",
]);

// Allow only images
function fileFilter(_req, file, cb) {
  const mime = String(file.mimetype || "").toLowerCase();
  const ext = path.extname(file.originalname || "").toLowerCase();

  const ok =
    ALLOWED_MIME.has(mime) ||
    ALLOWED_EXT.has(ext) ||
    (mime === "application/octet-stream" && ALLOWED_EXT.has(ext));

  if (!ok) {
    return cb(
      new Error(
        `Only JPG, PNG, WEBP images are allowed. Got mime="${mime}", ext="${ext}", name="${file.originalname}"`
      )
    );
  }
  cb(null, true);
}

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 3 * 1024 * 1024 }, // 3MB
});

// APIs
router.get("/me", authenticateFirebase, getWardAdminProfile);
router.patch("/me", authenticateFirebase, updateWardAdminProfile);

// Photo APIs  handle multer errors here so it returns 400
router.post("/me/photo", authenticateFirebase, (req, res, next) => {
  upload.single("photo")(req, res, (err) => {
    if (err) {
      // Multer errors
      const message = err?.message || "Invalid upload";
      return res.status(400).json({ error: message });
    }
    next();
  });
}, uploadWardAdminPhoto);

router.delete("/me/photo", authenticateFirebase, deleteWardAdminPhoto);

// Download/export API
router.get("/me/export", authenticateFirebase, exportWardAdminProfile);

export default router;