const xss = require('xss');

const SKIP_KEYS = new Set(['password', 'currentPassword', 'newPassword', 'token', 'refreshToken']);

const sanitizeValue = (value) => {
  if (typeof value === 'string') return xss(value.trim());
  if (Array.isArray(value)) return value.map(sanitizeValue);
  if (value && typeof value === 'object') return sanitizeObject(value);
  return value;
};

const sanitizeObject = (obj) => {
  const result = {};
  for (const [key, value] of Object.entries(obj)) {
    if (SKIP_KEYS.has(key)) {
      result[key] = value;
    } else {
      result[key] = sanitizeValue(value);
    }
  }
  return result;
};

const sanitizeInput = (req, res, next) => {
  if (req.body && typeof req.body === 'object') {
    req.body = sanitizeObject(req.body);
  }
  if (req.query && typeof req.query === 'object') {
    req.query = sanitizeObject(req.query);
  }
  next();
};

module.exports = sanitizeInput;
