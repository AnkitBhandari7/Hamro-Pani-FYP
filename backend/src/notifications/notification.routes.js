
import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import { getNotifications, createNotification } from "./notification.controller.js";

const router = Router();

// logged-in user sees their delivered notifications
router.get("/", authenticateFirebase, getNotifications);

//  ward admin creates a notification
router.post("/", authenticateFirebase, createNotification);

export default router;