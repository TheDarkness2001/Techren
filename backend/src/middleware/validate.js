const { validationResult } = require('express-validator');
const { sendError } = require('../utils/apiResponse');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return sendError(res, 400, 'VALIDATION_ERROR', 'Validation failed', errors.array());
  }
  next();
};

module.exports = validate;
