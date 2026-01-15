import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import { meDetails, createLocation, updateLocation, deleteLocation, setDefaultLocation } from "./profile.controller.js";

const router = Router();

router.get("/me", authenticateFirebase, meDetails);

router.post("/locations", authenticateFirebase, createLocation);
router.patch("/locations/:id", authenticateFirebase, updateLocation);
router.delete("/locations/:id", authenticateFirebase, deleteLocation);
router.patch("/locations/:id/default", authenticateFirebase, setDefaultLocation);

export default router;