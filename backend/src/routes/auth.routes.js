const { Router } = require('express');
const { exchange, me } = require('../controllers/auth.controller');
const requireAuth = require('../middlewares/requireAuth');

const router = Router();

router.post('/exchange', exchange);
router.get('/me', requireAuth, me);

module.exports = router;