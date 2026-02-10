// src/auth/auth.routes.js
import express from "express";
import { authenticateFirebase } from "./auth.middleware.js";
import {
  register,
  me,
  updateWard,
  updateProfile,
  saveFcmToken,
} from "./auth.controller.js";

const router = express.Router();

// Student note: register creates/updates user in our DB after Firebase login
router.post("/register", register);

// Student note: protected routes (need token)
router.get("/me", authenticateFirebase, me);
router.patch("/update-ward", authenticateFirebase, updateWard);
router.patch("/update-profile", authenticateFirebase, updateProfile);
router.post("/save-fcm-token", authenticateFirebase, saveFcmToken);

export default router;