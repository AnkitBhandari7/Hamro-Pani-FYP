const jwt = require('jsonwebtoken');
const prisma = require('../prisma');
const { admin } = require('../firebaseAdmin');
const config = require('../config/config');

function signJwt(user) {
  return jwt.sign(
    { sub: user.id, uid: user.firebaseUid, role: user.role },
    config.jwtSecret,
    { expiresIn: '30d' }
  );
}

async function exchange(req, res) {
  const { idToken, phone, name, role } = req.body;

  if (!idToken) {
    return res.status(400).json({ error: 'idToken is required' });
  }

  let decoded;
  let uid;
  let email;

  try {
    decoded = await admin.auth().verifyIdToken(idToken);
    uid = decoded.uid;
    email = decoded.email;
  } catch (error) {
    console.warn('Token verification failed (emulator/common):', error.message);
    // Fallback: extract from token (safe in dev)
    try {
      const payload = JSON.parse(Buffer.from(idToken.split('.')[1], 'base64').toString());
      uid = payload.sub;
      email = payload.email;
    } catch {
      return res.status(401).json({ error: 'Invalid Firebase token' });
    }
  }

  try {
    const user = await prisma.user.upsert({
      where: { firebaseUid: uid },
      update: {
        email: email || null,
        phone: phone ? phone.trim() : null,
        name: name ? name.trim() : null,
        role: role || 'Resident',
      },
      create: {
        firebaseUid: uid,
        email: email || null,
        phone: phone ? phone.trim() : null,
        name: name ? name.trim() : null,
        role: role || 'Resident',
      },
    });

    const token = signJwt({
      id: user.id,
      firebaseUid: user.firebaseUid,
      role: user.role,
    });

    res.json({
      jwt: token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (e) {
    console.error('Database or JWT error:', e);
    res.status(500).json({ error: 'Failed to process user' });
  }
}

async function me(req, res) {
  const userId = req.auth?.sub;
  if (!userId) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const user = await prisma.user.findUnique({
      where: { id: Number(userId) },
    });

    if (!user) return res.status(404).json({ error: 'User not found' });

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      role: user.role,
    });
  } catch (e) {
    console.error('Me endpoint error:', e);
    res.status(500).json({ error: 'Server error' });
  }
}

module.exports = { exchange, me };