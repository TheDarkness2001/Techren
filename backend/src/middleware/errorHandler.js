const { sendError } = require('../utils/apiResponse');
const config = require('../config');

// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  if (err.name === 'ValidationError') {
    const details = Object.values(err.errors).map((e) => ({ field: e.path, message: e.message }));
    return sendError(res, 400, 'VALIDATION_ERROR', err.message, details);
  }

  if (err.code === 11000) {
    const field = Object.keys(err.keyPattern || {})[0] || 'field';
    return sendError(res, 409, 'DUPLICATE', `${field} already exists`);
  }

  if (err.name === 'CastError') {
    return sendError(res, 400, 'INVALID_ID', 'Invalid resource ID');
  }

  const statusCode = err.statusCode || 500;
  const message = statusCode === 500 && !config.isDev
    ? 'Internal server error'
    : err.message || 'Internal server error';

  if (config.isDev && err.stack) {
    return res.status(statusCode).json({
      success: false,
      error: { code: 'SERVER_ERROR', message, details: [], stack: err.stack },
    });
  }

  return sendError(res, statusCode, err.code || 'SERVER_ERROR', message);
};

const notFound = (req, res) => {
  sendError(res, 404, 'NOT_FOUND', `Route not found: ${req.method} ${req.originalUrl}`);
};

module.exports = { errorHandler, notFound };
