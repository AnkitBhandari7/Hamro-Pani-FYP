import { Router } from "express";
import { authenticateFirebase } from "../auth/auth.middleware.js";
import {
  createBooking,
  getMyBookings,
  updateBookingStatus,
  getBookingDetail,
  confirmDeliveryAndRate,
  getVendorBookings,
  getBookingTracking,
} from "./tankerBooking.controller.js";

const router = Router();

// Resident
router.post("/", authenticateFirebase, createBooking);
router.get("/my", authenticateFirebase, getMyBookings);

// Vendor lists bookings (MUST be before "/:id")
router.get("/vendor/list", authenticateFirebase, getVendorBookings);

// Status updates
router.patch("/:id/status", authenticateFirebase, updateBookingStatus);

// Resident rating (works even if booking is COMPLETED)
router.post("/:id/confirm-delivery", authenticateFirebase, confirmDeliveryAndRate);

// Live tracking: vendor GPS + resident destination
router.get("/:id/tracking", authenticateFirebase, getBookingTracking);

// Resident booking detail (keep this LAST among GET routes)
router.get("/:id", authenticateFirebase, getBookingDetail);

export default router;