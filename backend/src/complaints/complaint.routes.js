import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import multer from "multer";
import path from "path";
import fs from "fs";

import {
  createComplaint,
  getMyComplaints,
  getComplaintDetail,
  updateComplaintStatus,
} from "./complaint.controller.js";

const router = Router();

// uploads folder
const uploadDir = path.resolve("uploads/complaints");
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname || "").toLowerCase() || ".jpg";
    cb(null, `complaint_${Date.now()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 4 * 1024 * 1024 }, // 4MB
});

router.post(
  "/",
  authenticateFirebase,
  upload.array("photos", 5),
  createComplaint
);

router.get("/my", authenticateFirebase, getMyComplaints);
router.get("/:id", authenticateFirebase, getComplaintDetail);
router.patch("/:id/status", authenticateFirebase, updateComplaintStatus);

export default router;