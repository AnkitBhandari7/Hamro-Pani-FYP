const app = require('./app');
const config = require('./config/config');
const { initFirebaseAdmin } = require('./firebaseAdmin');

initFirebaseAdmin();

app.listen(config.port, () => {
  console.log(`API listening on http://localhost:${config.port}`);
});