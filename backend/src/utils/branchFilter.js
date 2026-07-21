const mongoose = require('mongoose');

const getBranchFilter = (req) => {
  if (req.userType === 'teacher' && req.user.role === 'founder') {
    const branchId = req.query.branchId || req.body?.branchId;
    if (branchId && mongoose.Types.ObjectId.isValid(branchId)) {
      return { branchId: new mongoose.Types.ObjectId(branchId) };
    }
    return {};
  }

  if (req.branchId) {
    return { branchId: req.branchId };
  }

  if (req.user?.branchId) {
    return { branchId: req.user.branchId };
  }

  return {};
};

const canAccessBranch = (req, branchId) => {
  if (req.userType === 'teacher' && req.user.role === 'founder') return true;
  if (!branchId || !req.user?.branchId) return false;
  return String(req.user.branchId) === String(branchId);
};

module.exports = { getBranchFilter, canAccessBranch };
