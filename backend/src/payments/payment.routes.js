import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import { verifyEsewaPayment } from "./payment.controller.js";

const router = Router();

router.post("/esewa/verify", authenticateFirebase, verifyEsewaPayment);

export default router;