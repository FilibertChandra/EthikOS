const express = require('express');
const path = require('path');
const { applySecurityMiddleware } = require('./middleware/security');
require('dotenv').config();

const app = express();

// We sit behind one reverse proxy (ngrok), which sets X-Forwarded-For.
// Trusting it lets express-rate-limit read the real client IP without throwing
// ERR_ERL_UNEXPECTED_X_FORWARDED_FOR.
app.set('trust proxy', 1);

// Parse incoming requests into JSON payloads because express does not do this by default
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Apply all security middleware
applySecurityMiddleware(app);

// Serve uploaded images statically (e.g. GET /uploads/<filename>)
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/posts', require('./routes/posts'));

// Handle unknown routes
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Global error handler - passes error message in development, hides it in production
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

module.exports = app;