const express = require('express');
const { applySecurityMiddleware } = require('./middleware/security');
require('dotenv').config();

const app = express();

// Parse incoming requests into JSON payloads because express does not do this by default
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Apply all security middleware
applySecurityMiddleware(app);

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