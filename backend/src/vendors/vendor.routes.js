// src/vendors/vendor.routes.js
import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import {
  getVendorDashboard,
  createRoute,
  getMyRoutes,
  createSlot,
  listSlotsByWardAndDate,
} from "./vendor.controller.js";

const router = Router();

// Student note: vendor dashboard summary
router.get("/dashboard", authenticateFirebase, getVendorDashboard);

// Student note: create route (ERD: Route table)
router.post("/routes", authenticateFirebase, createRoute);

// Student note: get routes created by current vendor
router.get("/routes/my", authenticateFirebase, getMyRoutes);

// Student note: create slot inside a route (ERD: Slot table)
router.post("/routes/:routeId/slots", authenticateFirebase, createSlot);

// Student note: resident can browse slots by ward
router.get("/slots/ward/:ward", listSlotsByWardAndDate);

export default router;