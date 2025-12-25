const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const config = require('./config/config');
const authRoutes = require('./routes/auth.routes');

const app = express();

app.use(helmet());

if (config.corsOrigins === '*') {
  app.use(cors());
} else {
  const origins = config.corsOrigins.split(',').map(s => s.trim());
  app.use(cors({ origin: origins, credentials: true }));
}

app.use(express.json());
app.use(morgan('dev'));

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use('/auth', authRoutes);

// Global error handler
app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Server error' });
});

module.exports = app;