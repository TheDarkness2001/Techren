const { sendError } = require('../utils/apiResponse');

/** Students must have ieltsAccess; staff bypass. */
const requireIeltsAccess = (req, res, next) => {
  if (req.userType === 'teacher') return next();
  if (req.userType === 'student' && req.user?.ieltsAccess === true) return next();
  return sendError(res, 403, 'IELTS_LOCKED', 'IELTS Preparation is locked for this account');
};

module.exports = { requireIeltsAccess };
