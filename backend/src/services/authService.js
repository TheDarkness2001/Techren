const { Teacher, Student, Parent } = require('../models');
const { createTokenPair, revokeRefreshToken, refreshAccessToken } = require('./tokenService');

class AuthError extends Error {
  constructor(message, statusCode = 401, code = 'UNAUTHORIZED') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}

const formatTeacherUser = (teacher) => teacher.toPublicJSON();
const formatStudentUser = (student) => student.toPublicJSON();
const formatParentUser = (parent) => parent.toPublicJSON();

const normalizeIdentifier = (value) => String(value || '').trim().toLowerCase();

const findParentByIdentifier = async (identifier) => {
  const id = normalizeIdentifier(identifier);
  if (!id) return null;
  return Parent.findOne({
    $or: [{ username: id }, { email: id }],
  }).select('+password');
};

const assertParentPortal = async () => {
  const { getFeatureFlag } = require('./settingsService');
  const enabled = await getFeatureFlag('parentPortalEnabled');
  if (!enabled) {
    throw new AuthError('Parent portal is not enabled', 501, 'NOT_ENABLED');
  }
};

const loginTeacher = async (email, password) => {
  const teacher = await Teacher.findOne({ email: normalizeIdentifier(email) }).select('+password');
  if (!teacher || !(await teacher.matchPassword(password))) {
    throw new AuthError('Invalid username/email or password');
  }
  if (teacher.status === 'inactive') {
    throw new AuthError('Account is inactive', 403, 'INACTIVE_ACCOUNT');
  }

  const tokens = await createTokenPair(teacher._id, 'teacher');
  return { ...tokens, user: formatTeacherUser(teacher) };
};

const loginStudent = async (email, password) => {
  const student = await Student.findOne({ email: normalizeIdentifier(email) }).select('+password');
  if (!student || !(await student.matchPassword(password))) {
    throw new AuthError('Invalid username/email or password');
  }

  const tokens = await createTokenPair(student._id, 'student');
  return { ...tokens, user: formatStudentUser(student) };
};

const loginParent = async (identifier, password) => {
  await assertParentPortal();

  const parent = await findParentByIdentifier(identifier);
  if (!parent || !(await parent.matchPassword(password))) {
    throw new AuthError('Invalid username/email or password');
  }
  if (parent.status === 'inactive') {
    throw new AuthError('Account is inactive', 403, 'INACTIVE_ACCOUNT');
  }

  const tokens = await createTokenPair(parent._id, 'parent');
  return { ...tokens, user: formatParentUser(parent) };
};

const login = async (identifier, password, userType = 'auto') => {
  const id = normalizeIdentifier(identifier);

  if (userType === 'teacher') {
    return loginTeacher(id, password);
  }
  if (userType === 'student') {
    return loginStudent(id, password);
  }
  if (userType === 'parent') {
    return loginParent(id, password);
  }

  const teacher = await Teacher.findOne({ email: id }).select('+password');
  if (teacher && (await teacher.matchPassword(password))) {
    if (teacher.status === 'inactive') {
      throw new AuthError('Account is inactive', 403, 'INACTIVE_ACCOUNT');
    }
    const tokens = await createTokenPair(teacher._id, 'teacher');
    return { ...tokens, user: formatTeacherUser(teacher) };
  }

  const student = await Student.findOne({ email: id }).select('+password');
  if (student && (await student.matchPassword(password))) {
    const tokens = await createTokenPair(student._id, 'student');
    return { ...tokens, user: formatStudentUser(student) };
  }

  const parent = await findParentByIdentifier(id);
  if (parent && (await parent.matchPassword(password))) {
    await assertParentPortal();
    if (parent.status === 'inactive') {
      throw new AuthError('Account is inactive', 403, 'INACTIVE_ACCOUNT');
    }
    const tokens = await createTokenPair(parent._id, 'parent');
    return { ...tokens, user: formatParentUser(parent) };
  }

  throw new AuthError('Invalid username/email or password');
};

const getMe = async (user, userType) => {
  if (userType === 'teacher') return formatTeacherUser(user);
  if (userType === 'student') return formatStudentUser(user);
  if (userType === 'parent') return formatParentUser(user);
  throw new AuthError('Unsupported user type');
};

const logout = async (refreshToken) => {
  await revokeRefreshToken(refreshToken);
};

const refresh = async (refreshToken) => {
  if (!refreshToken) {
    throw new AuthError('Refresh token required');
  }
  return refreshAccessToken(refreshToken);
};

module.exports = {
  login,
  loginTeacher,
  loginStudent,
  loginParent,
  getMe,
  logout,
  refresh,
  AuthError,
};
