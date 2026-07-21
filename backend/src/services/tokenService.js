const jwt = require('jsonwebtoken');
const config = require('../config');
const RefreshToken = require('../models/RefreshToken');

const signAccessToken = (payload) =>
  jwt.sign({ ...payload, typ: 'access' }, config.jwt.secret, {
    expiresIn: config.jwt.accessExpire,
  });

const signRefreshToken = (payload) =>
  jwt.sign({ ...payload, type: 'refresh', typ: 'refresh' }, config.jwt.refreshSecret, {
    expiresIn: config.jwt.refreshExpire,
  });

const createTokenPair = async (userId, userType) => {
  const payload = { id: userId, userType };
  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);

  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7);

  await RefreshToken.create({
    tokenHash: RefreshToken.hashToken(refreshToken),
    userId,
    userType,
    expiresAt,
  });

  return { accessToken, refreshToken, expiresIn: 900 };
};

const revokeRefreshToken = async (refreshToken) => {
  if (!refreshToken) return;
  await RefreshToken.findOneAndUpdate(
    { tokenHash: RefreshToken.hashToken(refreshToken) },
    { revokedAt: new Date() }
  );
};

const refreshAccessToken = async (refreshToken) => {
  let decoded;
  try {
    decoded = jwt.verify(refreshToken, config.jwt.refreshSecret);
  } catch {
    throw Object.assign(new Error('Invalid refresh token'), {
      statusCode: 401,
      code: 'UNAUTHORIZED',
    });
  }

  if (decoded.type !== 'refresh' && decoded.typ !== 'refresh') {
    throw Object.assign(new Error('Invalid refresh token'), {
      statusCode: 401,
      code: 'UNAUTHORIZED',
    });
  }

  const stored = await RefreshToken.findOne({
    tokenHash: RefreshToken.hashToken(refreshToken),
    revokedAt: null,
  });

  if (!stored || stored.expiresAt < new Date()) {
    throw Object.assign(new Error('Refresh token expired or revoked'), {
      statusCode: 401,
      code: 'UNAUTHORIZED',
    });
  }

  const accessToken = signAccessToken({ id: decoded.id, userType: decoded.userType });
  return { accessToken, expiresIn: 900, userId: decoded.id, userType: decoded.userType };
};

module.exports = {
  createTokenPair,
  revokeRefreshToken,
  refreshAccessToken,
};
