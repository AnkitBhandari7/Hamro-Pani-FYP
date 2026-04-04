import http from "http";
import app from "./app.js";
import config from "./config/config.js";
import "./firebaseAdmin.js";
import { initSocket } from "./socket.js";

const PORT = config.port || 3000;

//  Create HTTP server so Socket.IO can share same port
const httpServer = http.createServer(app);

//  Initialize Socket.IO
initSocket(httpServer);

//  Listen on same port
httpServer.listen(PORT, "0.0.0.0", () => {
  console.log("API + Socket server is running!");
  console.log(`   • Local:            http://localhost:${PORT}`);
  console.log(`   • Android Emulator: http://10.0.2.2:${PORT}`);
});