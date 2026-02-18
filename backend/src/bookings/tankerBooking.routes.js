
import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import {
  createBooking,
  getMyBookings,
  updateBookingStatus,
} from "./tankerbooking.controller.js";

const router = Router();


router.post("/", authenticateFirebase, createBooking);

router.get("/my", authenticateFirebase, getMyBookings);


router.patch("/:id/status", authenticateFirebase, updateBookingStatus);

export default router;