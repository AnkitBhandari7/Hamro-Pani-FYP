import prisma from "../prisma.js";

function getUserId(req) {
  const id = Number(req.auth?.sub);
  return Number.isFinite(id) ? id : null;
}

function toAbsoluteUrl(req, storedPath) {
  if (!storedPath) return "";
  const s = String(storedPath);
  if (s.startsWith("http://") || s.startsWith("https://")) return s;
  const base = `${req.protocol}://${req.get("host")}`;
  const p = s.startsWith("/") ? s : `/${s}`;
  return `${base}${p}`;
}

/**
 * POST /complaints
 */
export async function createComplaint(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const issueType = String(req.body?.issueType || "").trim();
  const description = String(req.body?.description || "").trim();
  const ward = String(req.body?.ward || "").trim();
  const location = String(req.body?.location || "").trim();

  const bookingIdRaw = req.body?.bookingId;
  const bookingIdNum = bookingIdRaw == null ? null : Number(bookingIdRaw);

  if (!issueType) return res.status(400).json({ error: "issueType is required" });
  if (!description) return res.status(400).json({ error: "description is required" });

  try {
    const result = await prisma.$transaction(async (tx) => {
      let bookingId = null;

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
          where: {
            userId,
            NOT: { status: "CANCELLED" },
          },
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
        `Description: ${description}`;

      const complaint = await tx.complaint.create({
        data: {
          userId,
          bookingId,
          message,
          status: "OPEN",
        },
      });

      // MULTIPLE files
      const files = req.files || [];
      if (files.length > 0) {
        const rows = files.map((f) => ({
          complaintId: complaint.id,
          photoUrl: `/uploads/complaints/${f.filename}`,
        }));

        await tx.complaintPhoto.createMany({ data: rows });
      }

      // fetch photos for response
      const photos = await tx.complaintPhoto.findMany({
        where: { complaintId: complaint.id },
        orderBy: { id: "asc" },
      });

      return { complaint, photos };
    });

    return res.status(201).json({
      success: true,
      complaint: {
        id: result.complaint.id,
        status: result.complaint.status,
        createdAt: result.complaint.createdAt,
        bookingId: result.complaint.bookingId,
        message: result.complaint.message,
        photos: result.photos.map((p) => ({
          id: p.id,
          photoUrl: toAbsoluteUrl(req, p.photoUrl),
        })),
      },
    });
  } catch (e) {
    const code = e?.statusCode || 500;
    console.error("createComplaint error:", e);
    return res.status(code).json({ error: e.message || "Failed to submit complaint" });
  }
}

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
        photos: (c.photos || []).map((p) => ({
          id: p.id,
          photoUrl: toAbsoluteUrl(req, p.photoUrl),
        })),
      }))
    );
  } catch (e) {
    console.error("getMyComplaints error:", e);
    return res.status(500).json({ error: "Failed to load complaints" });
  }
}

export async function updateComplaintStatus(req, res) {
  const userId = getUserId(req);
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const complaintId = Number(req.params.id);
  const status = String(req.body?.status || "").trim().toUpperCase();

  if (!Number.isFinite(complaintId)) {
    return res.status(400).json({ error: "Invalid complaint id" });
  }

  const allowed = ["OPEN", "IN_REVIEW", "RESOLVED", "REJECTED"];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: "Invalid status" });
  }

  try {
    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });
    const role = String(me?.role || "").toUpperCase();
    if (role !== "ADMIN") return res.status(403).json({ error: "Only ADMIN can update status" });

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