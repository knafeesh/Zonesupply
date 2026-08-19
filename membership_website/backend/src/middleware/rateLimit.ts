import rateLimit from 'express-rate-limit';

// Rate limiter for membership applications (max 3 per IP per hour)
export const applyRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3,
  message: {
    success: false,
    message: 'Too many applications from this IP. Please try again after 1 hour.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiter for status check (max 20 per minute)
export const statusRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  message: {
    success: false,
    message: 'Too many requests. Please slow down.',
  },
});

// Rate limiter for admin login (max 5 per 15 minutes)
export const adminLoginRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: {
    success: false,
    message: 'Too many login attempts. Try again in 15 minutes.',
  },
});
