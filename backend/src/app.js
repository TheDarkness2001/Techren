const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const config = require('./config');
const { ensureUploadDirs, getWebsiteRoot } = require('./config/paths');
const sanitizeInput = require('./middleware/sanitize');
const routes = require('./routes');
const { errorHandler, notFound } = require('./middleware/errorHandler');

const createApp = () => {
  const app = express();

  app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
    contentSecurityPolicy: false,
  }));

  const allowedOrigins = [
    process.env.FRONTEND_URL,
    ...(config.isDev
      ? ['http://127.0.0.1:5000', 'http://localhost:5000', 'http://127.0.0.1:3000', 'http://localhost:3000']
      : []),
  ].filter(Boolean);

  app.use(cors({
    origin(origin, callback) {
      // Non-browser / same-origin tools
      if (!origin) return callback(null, true);
      if (config.isDev) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      if (/^https:\/\/([a-z0-9-]+\.)*techrenacademy\.com$/i.test(origin)) {
        return callback(null, true);
      }
      // New TechRen Railway service (native apps + download site). SMS PWA uses its own origin.
      if (/^https:\/\/([a-z0-9-]+\.)*up\.railway\.app$/i.test(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
  }));

  app.use(rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 1000,
    standardHeaders: true,
    legacyHeaders: false,
  }));

  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(mongoSanitize({
    replaceWith: '_',
    onSanitize: ({ key }) => {
      // eslint-disable-next-line no-console
      if (config.isDev) console.warn(`[sanitize] stripped operator key: ${key}`);
    },
  }));
  app.use(sanitizeInput);

  const uploadsRoot = ensureUploadDirs();
  const staticOpts = {
    fallthrough: false,
    index: false,
    dotfiles: 'deny',
    maxAge: config.isDev ? 0 : '1d',
  };

  // Never serve import DOCX/TXT tree publicly — only media used by the app.
  app.use('/api/v1/uploads/images', express.static(path.join(uploadsRoot, 'images'), staticOpts));
  app.use('/api/v1/uploads/audio', express.static(path.join(uploadsRoot, 'audio'), staticOpts));
  app.use('/api/v1/uploads/listening', express.static(path.join(uploadsRoot, 'listening'), staticOpts));

  app.use('/api/v1', routes);

  // Public download site (native installers) — not the Flutter web shell.
  const websiteRoot = getWebsiteRoot();
  const downloadsRoot = path.join(websiteRoot, 'downloads');

  app.use(
    '/downloads',
    express.static(downloadsRoot, {
      fallthrough: true,
      index: false,
      dotfiles: 'deny',
      maxAge: config.isDev ? 0 : '1h',
      setHeaders(res, filePath) {
        if (filePath.endsWith('.apk')) {
          res.setHeader('Content-Type', 'application/vnd.android.package-archive');
          res.setHeader('Content-Disposition', 'attachment; filename="techren-edu.apk"');
        } else if (filePath.endsWith('.zip')) {
          res.setHeader('Content-Type', 'application/zip');
          res.setHeader('Content-Disposition', 'attachment; filename="TechRenEDU-windows.zip"');
        } else if (filePath.endsWith('.exe')) {
          res.setHeader('Content-Type', 'application/octet-stream');
          res.setHeader('Content-Disposition', 'attachment; filename="TechRenEDU-setup.exe"');
        }
      },
    })
  );

  app.get('/', (_req, res) => {
    res.sendFile(path.join(websiteRoot, 'index.html'));
  });

  app.use(
    express.static(websiteRoot, {
      fallthrough: true,
      index: false,
      dotfiles: 'deny',
      maxAge: config.isDev ? 0 : '1h',
    })
  );

  app.use(notFound);
  app.use(errorHandler);

  return app;
};

module.exports = createApp;
