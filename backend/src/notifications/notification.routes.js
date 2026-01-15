import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import { getNotifications, createNotification } from "./notification.controller.js";

const router = Router();

router.get("/", authenticateFirebase, getNotifications);
router.post("/", authenticateFirebase, createNotification);

export default router;