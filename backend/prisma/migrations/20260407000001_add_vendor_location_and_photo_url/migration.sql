-- Add vendor live-location columns
-- These are populated by the vendor app's LocationService (POST /vendors/location)
-- and read by the resident tracking endpoint (GET /bookings/:id/tracking)

ALTER TABLE `vendors`
  ADD COLUMN `current_latitude`        DOUBLE        NULL,
  ADD COLUMN `current_longitude`       DOUBLE        NULL,
  ADD COLUMN `last_location_updated_at` DATETIME(3)  NULL;
