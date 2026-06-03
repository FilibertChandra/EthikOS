const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const xss = require('xss');
const cors = require('cors');

// Strict rate limiter for auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // max 10 requests per 15 minutes per IP
  message: 'Too many login attempts, please try again after 15 minutes'
});

// General rate limiter for all other routes
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // max 100 requests per 15 minutes per IP
  message: 'Too many requests from this IP, please try again after 15 minutes'
});

// Sanitize object recursively
const sanitizeObject = (obj) => {
  for (let key in obj) {
    if (typeof obj[key] === 'string') {
      // XSS prevention
      obj[key] = xss(obj[key]);
      // NoSQL injection prevention - remove $ and . from keys and values
      if (key.startsWith('$') || key.includes('.')) {
        delete obj[key];
      }
    } else if (typeof obj[key] === 'object' && obj[key] !== null) {
      sanitizeObject(obj[key]);
    }
  }
};

// Custom sanitize middleware - replaces xss-clean and express-mongo-sanitize
// Both were incompatible with Express 5
const sanitizeMiddleware = (req, res, next) => {
  if (req.body) sanitizeObject(req.body);
  if (req.params) sanitizeObject(req.params);
  next();
};

// Custom HPP middleware - replaces hpp package which was incompatible with Express 5
const hppMiddleware = (req, res, next) => {
  if (req.query) {
    for (let key in req.query) {
      if (Array.isArray(req.query[key])) {
        req.query[key] = req.query[key][req.query[key].length - 1];
      }
    }
  }
  next();
};

const applySecurityMiddleware = (app) => {
  // Secure Express apps by setting various HTTP headers
  app.use(helmet());

  app.use('/api', generalLimiter);

  // Cross-Origin Resource Sharing (cors) allows us to specify which domains can access our API. In development, we can allow all origins, but in production, we should restrict this to our frontend domain.
  // Allow Flutter web during development
  app.use(cors({
    origin: ['http://localhost:5000', 'http://localhost:3000', 'http://127.0.0.1'],
    credentials: true
  }));

  // Prevent Malicious script injection and NoSQL Injection
  app.use(sanitizeMiddleware);

  // Prevent HTTP Parameter Pollution, use only last parameter if there are duplicate query parameters
  app.use(hppMiddleware);
};

module.exports = { authLimiter, applySecurityMiddleware };