import { Router } from "express";
import { authenticateFirebase } from "../../auth/auth.middleware.js";
import { getNearbyTankers, bookTankerSlot, getSlotDetails } from "./tanker.controller.js";

const router = Router();

// GET /tankers/nearby?search=&filter=
router.get("/nearby", authenticateFirebase, getNearbyTankers);

// POST /tankers/book  { slotId }
router.post("/book", authenticateFirebase, bookTankerSlot);

//GET /tankers/slots/:slotId/details
router.get("/slots/:slotId/details", authenticateFirebase, getSlotDetails);

export default router;