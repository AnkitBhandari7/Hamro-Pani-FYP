import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import { getNotifications, createNotification,markNotificationRead,
       markAllNotificationsRead, } from "./notification.controller.js";

const router = Router();


router.get("/", authenticateFirebase, getNotifications);

router.patch("/:id/read", authenticateFirebase, markNotificationRead);
router.post("/mark-all-read", authenticateFirebase, markAllNotificationsRead);

router.post("/", authenticateFirebase, createNotification);

export default router;