import prisma from "../../prisma.js";
import config from "../../config/config.js";
import { NotificationType } from "@prisma/client";

function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

function cleanBaseUrl(u) {
  return String(u || "").trim().replace(/\/+$/, "");
}

function getRequestBaseUrl(req) {
  const proto = req.headers["x-forwarded-proto"] || req.protocol || "http";
  const host = req.headers["x-forwarded-host"] || req.get("host");
  return cleanBaseUrl(`${proto}://${host}`);
}

function sameOrigin(a, b) {
  try {
    const ua = new URL(a);
    const ub = new URL(b);
    return ua.protocol === ub.protocol && ua.host === ub.host; // host includes port
  } catch (_) {
    return false;
  }
}

/**
 * For images/files, return URLs reachable by the client:
 * - Emulator calls API via 10.0.2.2 => return 10.0.2.2 URLs
 * - Real phone calls via LAN IP => return LAN IP URLs
 * Use PUBLIC_BASE_URL only when it matches request origin.
 */
function getPublicBaseUrl(req) {
  const reqBase = getRequestBaseUrl(req);
  const envBase = cleanBaseUrl(config.publicBaseUrl);

  if (envBase && sameOrigin(envBase, reqBase)) return envBase;
  return reqBase;
}

function toAbsoluteUrl(req, storedPath) {
  if (!storedPath) return "";
  const s = String(storedPath).trim();

  if (/^https?:\/\//i.test(s)) return s;

  const base = getPublicBaseUrl(req);
  const rel = s.startsWith("/") ? s : `/${s}`;

  try {
    return new URL(rel, base).toString();
  } catch (_) {
    return `${base}${rel}`;
  }
}

function parseOptionalNumber(v) {
  if (v === null || v === undefined || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : NaN;
}

// In-app notification helpers

async function getLatestTokenOrCreateInAppToken(tx, userId) {
  const existing = await tx.fcmToken.findFirst({
    where: { userId },
    orderBy: { updatedAt: "desc" },
    select: { id: true, userId: true },
  });
  if (existing) return existing;

  const dummyToken = `inapp_user_${userId}`;

  return tx.fcmToken.upsert({
    where: { token: dummyToken },
    update: { userId, deviceInfo: "inapp" },
    create: { userId, token: dummyToken, deviceInfo: "inapp" },
    select: { id: true, userId: true },
  });
}

async function createRecipientsForUsers(tx, notificationId, userIds) {
  const deliveredAt = new Date();

  const uniq = [...new Set((userIds || []).filter(Boolean))];
  const rows = [];

  for (const uid of uniq) {
    const tok = await getLatestTokenOrCreateInAppToken(tx, uid);
    rows.push({
      notificationId,
      recipientId: tok.id,
      userId: uid,
      deliveredAt,
      isRead: false,
    });
  }

  if (rows.length === 0) return 0;

  const result = await tx.notificationRecipient.createMany({
    data: rows,
    skipDuplicates: true,
  });

  return result.count;
}

function mapPhotos(req, photos) {
  return (photos || []).map((p) => ({
    id: p.id,
    photoPath: p.photoUrl, // relative path to debug
    photoUrl: toAbsoluteUrl(req, p.photoUrl), // absolute url for app
  }));
}

/**
 * POST /complaints
 * Ward Admin belongs to ALL wards => notify ALL ward admins.
 */
export async function createComplaint(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const issueType = String(req.body?.issueType || "").trim();
  const description = String(req.body?.description || "").trim();
  const ward = String(req.body?.ward || "").trim();
  const location = String(req.body?.location || "").trim();

  const latParsed = parseOptionalNumber(req.body?.lat);
  const lngParsed = parseOptionalNumber(req.body?.lng);
  if (Number.isNaN(latParsed) || Number.isNaN(lngParsed)) {
    return res.status(400).json({ error: "lat/lng must be numbers" });
  }

  const bookingIdRaw = req.body?.bookingId;
  const bookingIdNum = bookingIdRaw == null ? null : Number(bookingIdRaw);

  if (!issueType) return res.status(400).json({ error: "issueType is required" });
  if (!description) return res.status(400).json({ error: "description is required" });

  try {
    const result = await prisma.$transaction(async (tx) => {
      let bookingId = null;

      // Resolve booking
      if (bookingIdNum != null && Number.isFinite(bookingIdNum)) {
        const b = await tx.booking.findUnique({
          where: { id: bookingIdNum },
          select: { id: true, userId: true },
        });
        if (!b) {
          const err = new Error("Booking not found");
          err.statusCode = 404;
          throw err;
        }
        if (b.userId !== userId) {
          const err = new Error("Forbidden: booking does not belong to you");
          err.statusCode = 403;
          throw err;
        }
        bookingId = b.id;
      } else {
        const latest = await tx.booking.findFirst({
          where: { userId, NOT: { status: "CANCELLED" } },
          orderBy: { createdAt: "desc" },
          select: { id: true },
        });
        if (!latest) {
          const err = new Error("No booking found to attach complaint. Send bookingId.");
          err.statusCode = 400;
          throw err;
        }
        bookingId = latest.id;
      }

      const message =
        `Issue Type: ${issueType}\n` +
        (ward ? `Ward: ${ward}\n` : "") +
        (location ? `Location: ${location}\n` : "") +
        (latParsed != null && lngParsed != null ? `LatLng: ${latParsed}, ${lngParsed}\n` : "") +
        `Description: ${description}`;

      const complaint = await tx.complaint.create({
        data: {
          userId,
          bookingId,
          message,
          status: "OPEN",
          lat: latParsed,
          lng: lngParsed,
        },
      });

      // Save photos
      const files = req.files || [];
      if (files.length > 0) {
        const rows = files.map((f) => ({
          complaintId: complaint.id,
          photoUrl: `/uploads/complaints/${f.filename}`,
        }));
        await tx.complaintPhoto.createMany({ data: rows });
      }

      const photos = await tx.complaintPhoto.findMany({
        where: { complaintId: complaint.id },
        orderBy: { id: "asc" },
      });

      // Load booking route/vendor/ward for recipients + better message
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: {
          user: { select: { id: true, name: true } },
          slot: {
            include: {
              route: {
                include: {
                  ward: true,
                  vendor: { include: { user: true } },
                },
              },
            },
          },
        },
      });

      const route = booking?.slot?.route;
      const vendorUserId = route?.vendor?.userId ?? null;

      const vendorName =
        route?.vendor?.companyName ||
        route?.vendor?.user?.name ||
        "Vendor";

      const wardName = route?.ward?.wardName || ward || "";
      const routeLocation = route?.location || location || "";
      const residentName = booking?.user?.name || "Resident";

      //  Ward admin belongs to ALL wards => notify ALL ward admins
      const wardAdmins = await tx.user.findMany({
        where: { role: "WARD_ADMIN" },
        select: { id: true },
      });

      const recipientUserIds = [
        ...(vendorUserId ? [vendorUserId] : []),
        ...wardAdmins.map((a) => a.id),
      ]
        .filter(Boolean)
        .filter((id) => id !== userId);

      let notif = null;
      let recipientCount = 0;

      if (recipientUserIds.length > 0) {
        const title = "New Complaint Submitted";
        const notifMsg =
          `Complaint #${complaint.id} (Booking #${bookingId})\n` +
          `Resident: ${residentName}\n` +
          `Vendor: ${vendorName}\n` +
          (wardName ? `Ward: ${wardName}\n` : "") +
          (routeLocation ? `Route: ${routeLocation}\n` : "") +
          `Issue: ${issueType}\n` +
          `Description: ${description}`;

        notif = await tx.notification.create({
          data: {
            senderId: userId,
            senderRole: "RESIDENT",
            title,
            message: notifMsg,
            type: NotificationType.COMPLAINT,
          },
        });

        recipientCount = await createRecipientsForUsers(tx, notif.id, recipientUserIds);
      }

      return { complaint, photos, notif, recipientCount };
    });

    return res.status(201).json({
      success: true,
      complaint: {
        id: result.complaint.id,
        status: result.complaint.status,
        createdAt: result.complaint.createdAt,
        bookingId: result.complaint.bookingId,
        message: result.complaint.message,
        lat: result.complaint.lat,
        lng: result.complaint.lng,
        photos: mapPhotos(req, result.photos),
      },
      notified: result.notif
        ? { notificationId: result.notif.id, recipients: result.recipientCount }
        : { notificationId: null, recipients: 0 },
    });
  } catch (e) {
    const code = e?.statusCode || 500;
    console.error("createComplaint error:", e);
    return res.status(code).json({ error: e.message || "Failed to submit complaint" });
  }
}

/**
 * GET /complaints/my
 */
export async function getMyComplaints(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const list = await prisma.complaint.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
      include: { photos: true },
      take: 50,
    });

    return res.json(
      list.map((c) => ({
        id: c.id,
        status: c.status,
        createdAt: c.createdAt,
        bookingId: c.bookingId,
        message: c.message,
        lat: c.lat,
        lng: c.lng,
        photos: mapPhotos(req, c.photos),
      }))
    );
  } catch (e) {
    console.error("getMyComplaints error:", e);
    return res.status(500).json({ error: "Failed to load complaints" });
  }
}

/**
 * GET /complaints/vendor
 */
export async function getVendorComplaints(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });
    if (String(me?.role || "") !== "VENDOR") {
      return res.status(403).json({ error: "Only VENDOR can access vendor complaints" });
    }

    const vendor = await prisma.vendor.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!vendor) return res.status(404).json({ error: "Vendor profile not found" });

    const list = await prisma.complaint.findMany({
      where: {
        booking: { slot: { route: { vendorId: vendor.id } } },
      },
      orderBy: { createdAt: "desc" },
      include: {
        photos: true,
        user: { select: { id: true, name: true } },
        booking: {
          include: {
            slot: { include: { route: { include: { ward: true } } } },
          },
        },
      },
      take: 100,
    });

    return res.json(
      list.map((c) => ({
        id: c.id,
        status: c.status,
        createdAt: c.createdAt,
        bookingId: c.bookingId,
        message: c.message,
        resident: c.user ? { id: c.user.id, name: c.user.name } : null,
        wardName: c.booking?.slot?.route?.ward?.wardName ?? "",
        lat: c.lat,
        lng: c.lng,
        photos: mapPhotos(req, c.photos),
      }))
    );
  } catch (e) {
    console.error("getVendorComplaints error:", e);
    return res.status(500).json({ error: "Failed to load vendor complaints" });
  }
}

/**
 * GET /complaints/ward
 * Ward admin belongs to ALL wards => return ALL complaints (no wardId needed)
 */
export async function getWardComplaints(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    if (String(me?.role || "") !== "WARD_ADMIN") {
      return res.status(403).json({ error: "Only WARD_ADMIN can access ward complaints" });
    }

    const list = await prisma.complaint.findMany({
      orderBy: { createdAt: "desc" },
      include: {
        photos: true,
        user: { select: { id: true, name: true } },
        booking: {
          include: {
            slot: {
              include: {
                route: {
                  include: {
                    ward: true,
                    vendor: { include: { user: true } },
                  },
                },
              },
            },
          },
        },
      },
      take: 200,
    });

    return res.json(
      list.map((c) => {
        const route = c.booking?.slot?.route;
        const vendor = route?.vendor;

        const vendorName =
          vendor?.companyName ||
          vendor?.user?.name ||
          "";

        return {
          id: c.id,
          status: c.status,
          createdAt: c.createdAt,
          bookingId: c.bookingId,
          message: c.message,

          resident: c.user ? { id: c.user.id, name: c.user.name } : null,

          wardName: route?.ward?.wardName ?? "",
          routeLocation: route?.location ?? "",

          vendorId: route?.vendorId ?? null,
          vendorName: vendorName,
          vendorPhone: vendor?.phone ?? "",

          lat: c.lat,
          lng: c.lng,

          photos: mapPhotos(req, c.photos),
        };
      })
    );
  } catch (e) {
    console.error("getWardComplaints error:", e);
    return res.status(500).json({ error: "Failed to load ward complaints" });
  }
}

/**
 * GET /complaints/:id
 * allow: resident owner OR vendor owner OR ward admin (any ward)
 */
export async function getComplaintDetail(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const complaintId = Number(req.params.id);
  if (!Number.isFinite(complaintId)) return res.status(400).json({ error: "Invalid complaint id" });

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    const complaint = await prisma.complaint.findUnique({
      where: { id: complaintId },
      include: {
        photos: true,
        booking: {
          include: {
            slot: {
              include: {
                route: {
                  include: {
                    ward: true,
                    vendor: { include: { user: true } },
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!complaint) return res.status(404).json({ error: "Complaint not found" });

    const role = String(me?.role || "").toUpperCase();
    const route = complaint.booking?.slot?.route;

    const isOwner = complaint.userId === userId;
    const isVendorOwner = role === "VENDOR" && route?.vendor?.userId === userId;
    const isWardAdmin = role === "WARD_ADMIN";

    if (!isOwner && !isVendorOwner && !isWardAdmin) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const vendorName = route?.vendor?.user?.name ?? "Vendor";
    const routeLocation = route?.location ?? "";
    const wardName = route?.ward?.wardName ?? "";

    return res.json({
      id: complaint.id,
      status: complaint.status,
      createdAt: complaint.createdAt,
      updatedAt: complaint.updatedAt,
      bookingId: complaint.bookingId,
      message: complaint.message,
      lat: complaint.lat,
      lng: complaint.lng,
      booking: complaint.booking
        ? {
            id: complaint.booking.id,
            status: complaint.booking.status,
            createdAt: complaint.booking.createdAt,
            vendorName,
            routeLocation,
            wardName,
            slotStartTime: complaint.booking.slot?.startTime ?? null,
            slotEndTime: complaint.booking.slot?.endTime ?? null,
          }
        : null,
      photos: mapPhotos(req, complaint.photos),
    });
  } catch (e) {
    console.error("getComplaintDetail error:", e);
    return res.status(500).json({ error: "Failed to load complaint detail" });
  }
}

/**
 * PATCH /complaints/:id/status
 */
export async function updateComplaintStatus(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const complaintId = Number(req.params.id);
  const status = String(req.body?.status || "").trim().toUpperCase();

  if (!Number.isFinite(complaintId)) return res.status(400).json({ error: "Invalid complaint id" });

  const allowed = ["OPEN", "IN_REVIEW", "RESOLVED", "REJECTED"];
  if (!allowed.includes(status)) return res.status(400).json({ error: "Invalid status" });

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });

    const role = String(me?.role || "").toUpperCase();
    if (role !== "WARD_ADMIN") return res.status(403).json({ error: "Only WARD_ADMIN can update status" });

    const updated = await prisma.complaint.update({
      where: { id: complaintId },
      data: { status },
    });

    return res.json({ success: true, complaint: updated });
  } catch (e) {
    console.error("updateComplaintStatus error:", e);
    return res.status(500).json({ error: "Failed to update complaint" });
  }
}