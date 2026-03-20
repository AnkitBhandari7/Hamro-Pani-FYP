
import { Router } from "express";
import multer from "multer";
import path from "path";
import fs from "fs";

import { authenticateFirebase } from "../auth/auth.middleware.js";
import {
  meDetails,
  uploadMyPhoto,
  deleteMyPhoto,
  createLocation,
  updateLocation,
  deleteLocation,
  setDefaultLocation,
} from "./profile.controller.js";

const router = Router();

const uploadDir = path.resolve("uploads/profile");
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const userId = req.auth?.sub ?? "user";
    const ext = path.extname(file.originalname || "").toLowerCase();
    const safeExt = ext && ext.length <= 10 ? ext : ".jpg";
    cb(null, `resident_${userId}_${Date.now()}${safeExt}`);
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

  if (!ok) {
    return cb(
      new Error(
        `Only JPG, PNG, WEBP allowed. Got mime="${mime}", ext="${ext}", name="${file.originalname}"`
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

// profile data
router.get("/me", authenticateFirebase, meDetails);

//  photo upload/delete
router.post("/me/photo", authenticateFirebase, (req, res, next) => {
  upload.single("photo")(req, res, (err) => {
    if (err) return res.status(400).json({ error: err.message });
    next();
  });
}, uploadMyPhoto);

router.delete("/me/photo", authenticateFirebase, deleteMyPhoto);

// compatibility endpoints
router.post("/locations", authenticateFirebase, createLocation);
router.patch("/locations/:id", authenticateFirebase, updateLocation);
router.delete("/locations/:id", authenticateFirebase, deleteLocation);
router.patch("/locations/:id/default", authenticateFirebase, setDefaultLocation);

export default router;