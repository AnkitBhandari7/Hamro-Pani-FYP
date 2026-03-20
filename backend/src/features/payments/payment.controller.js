import prisma from "../../prisma.js";

function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

function getEsewaBaseUrl() {

  return process.env.ESEWA_ENV === "prod"
    ? "https://esewa.com.np"
    : "https://rc.esewa.com.np";
}

// POST /payments/esewa/verify
export async function verifyEsewaPayment(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const bookingId = Number(req.body?.bookingId);
  const refId = String(req.body?.refId || "").trim();

  if (!Number.isFinite(bookingId)) return res.status(400).json({ error: "bookingId is required" });
  if (!refId) return res.status(400).json({ error: "refId is required" });

  try {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: { payment: true },
    });

    if (!booking) return res.status(404).json({ error: "Booking not found" });
    if (booking.userId !== userId) return res.status(403).json({ error: "Forbidden" });
    if (!booking.payment) return res.status(400).json({ error: "Payment row not found" });

    const method = String(booking.payment.method || "").toUpperCase();
    if (method !== "ESEWA") return res.status(400).json({ error: "Not an eSewa payment" });

    const merchantId = String(process.env.ESEWA_MERCHANT_ID || "").trim();
    const merchantSecret = String(process.env.ESEWA_MERCHANT_SECRET || "").trim();

    if (!merchantId || !merchantSecret) {
      return res.status(500).json({ error: "Missing ESEWA_MERCHANT_ID / ESEWA_MERCHANT_SECRET in .env" });
    }

    // Mobile SDK verification API
    const base = getEsewaBaseUrl();
    const url = `${base}/mobile/transaction?txnRefId=${encodeURIComponent(refId)}`;

    const verifyRes = await fetch(url, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        merchantId: merchantId,
        merchantSecret: merchantSecret,
      },
    });

    const data = await verifyRes.json();

    // API sometimes returns an array
    const row = Array.isArray(data) ? data[0] : data;

    const status = String(row?.transactionDetails?.status || "").toUpperCase();
    const code = String(row?.code || "").toUpperCase();

    const ok = (status === "COMPLETE") && (code === "00" || code === "");

    if (!ok) {
      await prisma.payment.update({
        where: { bookingId },
        data: { status: "FAILED" },
      });

      return res.status(400).json({
        success: false,
        error: "eSewa transaction not complete",
        esewa: row,
      });
    }

    const updated = await prisma.payment.update({
      where: { bookingId },
      data: {
        status: "PAID",
        paidAt: new Date(),
        transactionId: refId,
      },
    });

    return res.json({ success: true, payment: updated, esewa: row });
  } catch (e) {
    console.error("verifyEsewaPayment error:", e);
    return res.status(500).json({ error: "Failed to verify eSewa payment" });
  }
}

// GET /payments/receipt/:bookingId
export async function getPaymentReceipt(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const bookingId = Number(req.params.bookingId);
  if (!Number.isFinite(bookingId)) return res.status(400).json({ error: "Invalid bookingId" });

  try {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        payment: true,
        slot: {
          include: {
            route: {
              include: {
                vendor: { include: { user: true } },
              },
            },
          },
        },
      },
    });

    if (!booking) return res.status(404).json({ error: "Booking not found" });
    if (booking.userId !== userId) return res.status(403).json({ error: "Forbidden" });

    if (!booking.payment) return res.status(400).json({ error: "Payment not found" });

    // For eSewa, we saved refId into payment.transactionId in verify API
    const transactionId = booking.payment.transactionId || `BOOKING-${booking.id}`;
    const paidAt = booking.payment.paidAt || booking.updatedAt || booking.createdAt;

    const vendorName =
      booking.slot?.route?.vendor?.user?.name ||
      booking.slot?.route?.vendor?.companyName ||
      "Vendor";

    const liters = booking.slot?.tankerCapacityLiters ?? 12000;

    // Prisma Decimal -> number safe conversion
    const amt = booking.payment.amount;
    const amount =
      amt && typeof amt.toNumber === "function"
        ? amt.toNumber()
        : Number(amt ?? 0);

    return res.json({
      bookingId: booking.id,
      transactionId,
      dateTime: paidAt,
      paymentMethod: booking.payment.method, // CASH/ESEWA
      recipient: vendorName,
      service: "Water Tanker Delivery",
      quantityLiters: liters,
      amount,
    });
  } catch (e) {
    console.error("getPaymentReceipt error:", e);
    return res.status(500).json({ error: "Failed to load receipt" });
  }
}