import { Router } from "express";
import { authenticateFirebase } from "../../auth/auth.middleware.js";
import { getNearbyTankers, bookTankerSlot } from "./tanker.controller.js";

const router = Router();

// GET /tankers/nearby?search=&filter=
router.get("/nearby", authenticateFirebase, getNearbyTankers);

// POST /tankers/book  { slotId }
router.post("/book", authenticateFirebase, bookTankerSlot);

export default router;