

import express from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import { createSchedule, getSchedules, getSchedule, deleteSchedule } from "./schedule.controller.js";

const router = express.Router();

router.post("/", authenticateFirebase, createSchedule);
router.get("/", authenticateFirebase, getSchedules);
router.get("/:id", authenticateFirebase, getSchedule);
router.delete("/:id", authenticateFirebase, deleteSchedule);

export default router;