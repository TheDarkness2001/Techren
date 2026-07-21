const jwt = require('jsonwebtoken');
const config = require('../config');
const { Teacher, Student, Parent } = require('../models');
const { sendError } = require('../utils/apiResponse');
const { findSettingsDocument } = require('../services/settingsService');

const INACTIVE_STUDENT_PREFIXES = [
  '/auth',
  '/payments',
  '/exams',
  '/feedback',
  '/homework',
  '/sentences',
  '/listening',
  '/video-lessons',
  '/penalties',
  '/presentations',
  '/notifications',
  '/gamification',
  '/wallet',
];

const protect = async (req, res, next) => {
  try {
    let token;
    if (req.headers.authorization?.startsWith('Bearer ')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return sendError(res, 401, 'UNAUTHORIZED', 'Not authorized, no token');
    }

    const decoded = jwt.verify(token, config.jwt.secret);

    // Refresh JWTs must never be accepted as API access credentials.
    if (decoded.type === 'refresh' || decoded.typ === 'refresh') {
      return sendError(res, 401, 'UNAUTHORIZED', 'Refresh token cannot be used as access token');
    }

    let user;

    if (decoded.userType === 'teacher') {
      user = await Teacher.findById(decoded.id);
      if (!user || user.status === 'inactive') {
        return sendError(res, 401, 'UNAUTHORIZED', 'Teacher not found or inactive');
      }
      req.user = user;
      req.userType = 'teacher';
    } else if (decoded.userType === 'student') {
      user = await Student.findById(decoded.id);
      if (!user) {
        return sendError(res, 401, 'UNAUTHORIZED', 'Student not found');
      }
      req.user = user;
      req.userType = 'student';

      if (user.status === 'inactive') {
        const path = req.baseUrl + req.path;
        const allowed = INACTIVE_STUDENT_PREFIXES.some((prefix) => path.includes(prefix))
          || (req.method === 'GET' && path.includes(`/students/${user._id}`));
        if (!allowed) {
          return sendError(res, 403, 'INACTIVE_STUDENT', 'Account inactive. Limited access only.');
        }
      }
    } else if (decoded.userType === 'parent') {
      user = await Parent.findById(decoded.id);
      if (!user || user.status === 'inactive') {
        return sendError(res, 401, 'UNAUTHORIZED', 'Parent not found or inactive');
      }
      req.user = user;
      req.userType = 'parent';
    } else {
      return sendError(res, 401, 'UNAUTHORIZED', 'Invalid user type');
    }

    req.settings = await findSettingsDocument();
    next();
  } catch (error) {
    return sendError(res, 401, 'UNAUTHORIZED', 'Not authorized, token invalid or expired');
  }
};

/** Founder + admin — platform-level operators (recycle bin, etc.). */
const isPlatformAdmin = (user) => ['founder', 'admin'].includes(user?.role);

/**
 * Elevated branch staff (founder/admin/manager).
 * Prefer checkPermission / hasPermission for feature gates; use this only for
 * ownership shortcuts (e.g. any class vs only own classes).
 */
const isPrivilegedStaff = (user) => ['founder', 'admin', 'manager'].includes(user?.role);

const resolvePermission = async (req, permission) => {
  if (req.userType !== 'teacher') return false;
  if (req.user.role === 'founder') return true;

  const settings = req.settings || (await findSettingsDocument());
  const rolePerms = settings?.rolePermissions?.[req.user.role];
  if (rolePerms?.[permission] === true) return true;
  if (rolePerms?.[permission] === false) return false;

  return req.user.permissions?.get?.(permission) === true
    || req.user.permissions?.[permission] === true;
};

const hasPermission = async (req, permission) => resolvePermission(req, permission);

const checkPermission = (permission) => async (req, res, next) => {
  if (req.userType !== 'teacher') {
    return sendError(res, 403, 'FORBIDDEN', 'Staff permission required');
  }

  // Only founder bypasses the matrix. Admin/manager must match rolePermissions.
  if (await resolvePermission(req, permission)) {
    return next();
  }

  return sendError(res, 403, 'FORBIDDEN', `Missing permission: ${permission}`);
};

module.exports = {
  protect,
  checkPermission,
  hasPermission,
  isPrivilegedStaff,
  isPlatformAdmin,
};
