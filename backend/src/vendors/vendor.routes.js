import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import { getVendorDashboard } from "./vendor.controller.js";

const router = Router();

router.get("/dashboard", authenticateFirebase, getVendorDashboard);

export default router;