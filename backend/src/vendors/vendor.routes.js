import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import {
  getVendorDashboard,
  createTankerRoute,
  getMyTankerRoutes,
  createTankerSlot,
  listSlotsByWardAndDate,
} from "./vendor.controller.js";

const router = Router();

// Existing vendor dashboard
router.get("/dashboard", authenticateFirebase, getVendorDashboard);

// Tanker booking: vendor route + slot management
router.post("/routes", authenticateFirebase, createTankerRoute);
router.get("/routes/my", authenticateFirebase, getMyTankerRoutes);
router.post(
  "/routes/:routeId/slots",
  authenticateFirebase,
  createTankerSlot
);

// Resident-side listing of open slots by ward
router.get("/slots/ward/:ward", listSlotsByWardAndDate);

export default router;