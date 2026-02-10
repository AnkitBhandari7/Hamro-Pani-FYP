// src/bookings/tankerBooking.routes.js
import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import {
  createBooking,
  getMyBookings,
  updateBookingStatus,
} from "./tankerbooking.controller.js";

const router = Router();

// Student note: resident creates booking (ERD: just slotId)
router.post("/", authenticateFirebase, createBooking);

// Student note: resident sees their bookings
router.get("/my", authenticateFirebase, getMyBookings);

// Student note: update booking status (also creates status history in ERD)
router.patch("/:id/status", authenticateFirebase, updateBookingStatus);

export default router;