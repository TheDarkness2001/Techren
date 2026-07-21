const { sendError } = require('../utils/apiResponse');

const requireFounder = (req, res, next) => {
  if (req.userType !== 'teacher' || req.user.role !== 'founder') {
    return sendError(res, 403, 'FORBIDDEN', 'Founder access required');
  }
  next();
};

const requireStaff = (req, res, next) => {
  if (req.userType !== 'teacher') {
    return sendError(res, 403, 'FORBIDDEN', 'Staff access required');
  }
  next();
};

module.exports = { requireFounder, requireStaff };
