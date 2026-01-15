const express = require('express');
const router = express.Router();

const { authenticateFirebase } = require('../middlewares/auth.middleware');
const { getNotifications, createNotification } = require('../controllers/notification.controller');

// ✅ Debug AFTER imports
console.log("authenticateFirebase:", authenticateFirebase);
console.log("getNotifications:", getNotifications);
console.log("createNotification:", createNotification);

router.get('/', authenticateFirebase, getNotifications);
router.post('/', authenticateFirebase, createNotification);

module.exports = router;