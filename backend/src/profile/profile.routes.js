// src/profile/profile.routes.js
import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import {
  meDetails,
  createLocation,
  updateLocation,
  deleteLocation,
  setDefaultLocation,
} from "./profile.controller.js";

const router = Router();

// Student note: profile data for current user
router.get("/me", authenticateFirebase, meDetails);

// Student note: these endpoints are kept for compatibility, but ERD does not support SavedLocation
router.post("/locations", authenticateFirebase, createLocation);
router.patch("/locations/:id", authenticateFirebase, updateLocation);
router.delete("/locations/:id", authenticateFirebase, deleteLocation);
router.patch("/locations/:id/default", authenticateFirebase, setDefaultLocation);

export default router;