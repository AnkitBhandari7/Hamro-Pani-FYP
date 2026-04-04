import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import { verifyEsewaPayment, getPaymentReceipt } from "./payment.controller.js";

const router = Router();

router.post("/esewa/verify", authenticateFirebase, verifyEsewaPayment);
router.get("/receipt/:bookingId", authenticateFirebase, getPaymentReceipt);

export default router;