require('dotenv').config();

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
]);

const WEAK_FOUNDER_PASSWORDS = new Set(['Founder123!', 'founder123', 'password', 'Password1!']);

const env = process.env.NODE_ENV || 'development';
const isProduction = env === 'production';
const jwtSecret = process.env.JWT_SECRET;
const jwtRefreshSecret = process.env.JWT_REFRESH_SECRET || null;

if (isProduction) {
  if (WEAK_JWT_DEFAULTS.has(jwtSecret) || jwtSecret.length < 32) {
    throw new Error(
      'Refusing to start: set a strong JWT_SECRET (32+ chars) in production. Do not use example defaults.'
    );
  }
  if (!jwtRefreshSecret || jwtRefreshSecret === jwtSecret || jwtRefreshSecret.length < 32) {
    throw new Error(
      'Refusing to start: set a distinct JWT_REFRESH_SECRET (32+ chars) in production.'
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

// Prefer an explicit refresh secret; in non-prod, derive so refresh tokens cannot
// be verified with the access-token secret alone when JWT_REFRESH_SECRET is unset.
const resolvedRefreshSecret =
  jwtRefreshSecret || `${jwtSecret}:refresh`;

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
    refreshExpire: process.env.JWT_REFRESH_EXPIRE || '7d',
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
