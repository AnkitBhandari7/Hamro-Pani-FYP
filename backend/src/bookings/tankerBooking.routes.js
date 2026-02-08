import express from "express";
import cors from "cors";
import helmet from "helmet";

import authRoutes from "./auth/auth.routes.js";
import vendorRoutes from "./vendors/vendor.routes.js";
import bookingRoutes from "./bookings/tankerBooking.routes.js";

import express from "express";

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/vendors", vendorRoutes);
app.use("/api/bookings", bookingRoutes);

export default app;