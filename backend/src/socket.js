import { Server } from "socket.io";

/**

 * This file creates a Socket.IO server.
 * - We use rooms based on tripId, so multiple users can track the same trip.
 * - Driver sends location updates -> server broadcasts to watchers.
 */
export function initSocket(httpServer) {
  const io = new Server(httpServer, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
    },
  });

  io.on("connection", (socket) => {
    console.log("socket connected:", socket.id);

    /**
     * join a tracking room: { tripId }
     * both driver and customer join the same room
     */
    socket.on("tracking:join", ({ tripId }) => {
      if (!tripId) return;
      socket.join(String(tripId));
      console.log(`socket ${socket.id} joined trip ${tripId}`);
    });

    /**
     * driver updates location: { tripId, lat, lng, heading, speed, ts }
     * we broadcast to all watchers in that trip room
     */
    socket.on("tracking:update", (payload) => {
      try {
        const tripId = payload?.tripId;
        if (!tripId) return;

        const lat = Number(payload?.lat);
        const lng = Number(payload?.lng);
        if (!Number.isFinite(lat) || !Number.isFinite(lng)) return;

        const data = {
          tripId: String(tripId),
          lat,
          lng,
          heading: payload?.heading ?? null,
          speed: payload?.speed ?? null,
          ts: payload?.ts ?? Date.now(),
        };

        // broadcast to everyone in room
        io.to(String(tripId)).emit("tracking:position", data);
      } catch (e) {
        console.error("tracking:update error:", e);
      }
    });

    socket.on("disconnect", () => {
      console.log("socket disconnected:", socket.id);
    });
  });

  return io;
}