import app from "./app.js";
import config from "./config/config.js";
import "./firebaseAdmin.js";

const PORT = config.port || 3000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(" API server is running!");
  console.log(`   • Local:            http://localhost:${PORT}`);
  console.log(`   • Android Emulator: http://10.0.2.2:${PORT}`);
});