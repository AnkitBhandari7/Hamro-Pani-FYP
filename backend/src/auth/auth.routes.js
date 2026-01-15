import express from "express";
import { authenticateFirebase } from "./auth.middleware.js";
import { register, me, updateWard, updateProfile, saveFcmToken } from "./auth.controller.js";

const router = express.Router();


router.post("/register", register);

// Protected
router.get("/me", authenticateFirebase, me);
router.patch("/update-ward", authenticateFirebase, updateWard);
router.patch("/update-profile", authenticateFirebase, updateProfile);
router.post("/save-fcm-token", authenticateFirebase, saveFcmToken);

export default router;