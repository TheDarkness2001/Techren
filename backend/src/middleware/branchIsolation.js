const Branch = require('../models/Branch');
const { sendError } = require('../utils/apiResponse');

const enforceBranchIsolation = async (req, res, next) => {
  if (req.userType === 'student') {
    return next();
  }

  if (req.userType === 'teacher' && req.user.role === 'founder') {
    return next();
  }

  if (req.userType !== 'teacher') {
    return next();
  }

  if (!req.user.branchId) {
    return sendError(res, 403, 'FORBIDDEN', 'Staff member has no branch assigned');
  }

  const branch = await Branch.findById(req.user.branchId);
  if (!branch || !branch.isActive) {
    return sendError(res, 403, 'FORBIDDEN', 'Branch is inactive');
  }

  if (req.method === 'GET') {
    req.query.branchId = String(req.user.branchId);
  } else if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
    req.body.branchId = req.user.branchId;
  }

  req.branchId = req.user.branchId;
  next();
};

module.exports = enforceBranchIsolation;
