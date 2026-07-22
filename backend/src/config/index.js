require('dotenv').config();
const crypto = require('crypto');

const required = ['JWT_SECRET'];

for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}

const WEAK_JWT_DEFAULTS = new Set([
  'change-this-to-a-long-random-secret',
  'secret',
  'jwt_secret',
  'your-secret',
  'replace-with-a-long-random-secret-at-least-32-chars',
]);

const WEAK_FOUNDER_PASSWORDS = new Set([
  'Founder123!',
  'founder123',
  'password',
  'Password1!',
  'replace-with-a-strong-founder-password',
  'replace-with-a-strong-password',
  'replace-with-a-strong-unique-password',
]);

const env = process.env.NODE_ENV || 'development';
const isProduction = env === 'production';
const jwtSecret = process.env.JWT_SECRET;
const jwtRefreshSecretEnv = process.env.JWT_REFRESH_SECRET || null;

if (isProduction) {
  if (!process.env.MONGO_URI || process.env.MONGO_URI.includes('127.0.0.1') || process.env.MONGO_URI.includes('localhost')) {
    throw new Error(
      'Refusing to start: set MONGO_URI to your MongoDB Atlas connection string in production.'
    );
  }
  if (WEAK_JWT_DEFAULTS.has(jwtSecret) || jwtSecret.length < 32) {
    throw new Error(
      'Refusing to start: set a strong JWT_SECRET (32+ chars) in production. Do not use example defaults.'
    );
  }
  if (jwtRefreshSecretEnv && (jwtRefreshSecretEnv === jwtSecret || jwtRefreshSecretEnv.length < 32)) {
    throw new Error(
      'Refusing to start: JWT_REFRESH_SECRET must be 32+ chars and different from JWT_SECRET (or omit it to auto-derive).'
    );
  }
  if (!process.env.FOUNDER_PASSWORD || WEAK_FOUNDER_PASSWORDS.has(process.env.FOUNDER_PASSWORD)) {
    throw new Error(
      'Refusing to start: set a strong FOUNDER_PASSWORD in production (not the example default).'
    );
  }
} else if (WEAK_JWT_DEFAULTS.has(jwtSecret)) {
  // eslint-disable-next-line no-console
  console.warn(
    '[config] WARNING: JWT_SECRET is an insecure example value. Rotate it before any shared/deployed use.'
  );
}

const mongoUri = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/techren_edu';
const isAtlasUri = mongoUri.includes('mongodb+srv://');

// Prefer an explicit refresh secret. If unset, derive a distinct key from JWT_SECRET
// so production can boot with only JWT_SECRET configured.
const resolvedRefreshSecret =
  jwtRefreshSecretEnv
  || crypto.createHash('sha256').update(`${jwtSecret}:techren-refresh`).digest('hex');

// Guard against accidentally putting a secret string into JWT_REFRESH_EXPIRE.
const rawRefreshExpire = process.env.JWT_REFRESH_EXPIRE || '7d';
const refreshExpire = /^\d+[smhd]$/i.test(String(rawRefreshExpire).trim())
  ? String(rawRefreshExpire).trim()
  : '7d';

if (rawRefreshExpire !== refreshExpire) {
  // eslint-disable-next-line no-console
  console.warn(
    `[config] JWT_REFRESH_EXPIRE="${rawRefreshExpire}" is not a duration (e.g. 7d). Using 7d instead.`
  );
}

module.exports = {
  env,
  port: Number(process.env.PORT) || 5002,
  mongoUri,
  isAtlasUri,
  useMemoryFallback:
    process.env.MONGO_FALLBACK_MEMORY === 'true'
    || (process.env.MONGO_FALLBACK_MEMORY !== 'false' && !isAtlasUri && !isProduction),
  // Demo role accounts are never auto-seeded unless explicitly requested.
  seedDemoData: process.env.SEED_DEMO_DATA === 'true',
  jwt: {
    secret: jwtSecret,
    refreshSecret: resolvedRefreshSecret,
    accessExpire: process.env.JWT_ACCESS_EXPIRE || '15m',
    refreshExpire,
  },
  founder: {
    email: process.env.FOUNDER_EMAIL || 'founder@techren.uz',
    password: process.env.FOUNDER_PASSWORD || 'Founder123!',
  },
  features: {
    walletEnabled: process.env.WALLET_ENABLED === 'true',
    gamificationEnabled: process.env.GAMIFICATION_ENABLED !== 'false',
  },
  isDev: !isProduction,
};
