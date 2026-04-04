import express from "express";
import multer from "multer";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import {
  createSchedule,
  getSchedules,
  getSchedule,
  deleteSchedule,
  uploadScheduleFile,
} from "./schedule.controller.js";

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
});

// Return JSON error when multer fails
function uploadSingleFile(req, res, next) {
  upload.single("file")(req, res, (err) => {
    if (err) {
      return res.status(400).json({
        error: err.message,
        code: err.code,
      });
    }
    next();
  });
}

router.post("/upload", authenticateFirebase, uploadSingleFile, uploadScheduleFile);

router.post("/", authenticateFirebase, createSchedule);
router.get("/", authenticateFirebase, getSchedules);
router.get("/:id", authenticateFirebase, getSchedule);
router.delete("/:id", authenticateFirebase, deleteSchedule);

export default router;