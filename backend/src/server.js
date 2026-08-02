const config = require('./config');
const logger = require('./config/logger');
const connectDB = require('./config/database');
const { initDefaults } = require('./services/settingsService');
const { ensureDevAccounts } = require('./services/bootstrapService');
const createApp = require('./app');
const { initFirebase } = require('./config/firebase');
const { register: registerNotificationWorker } = require('./utils/notificationWorker');
const { attachSocket } = require('./realtime/socket');

const start = async () => {
  // Listen first so Railway healthchecks can pass while Mongo connects.
  const app = createApp();
  const host = process.env.HOST || '0.0.0.0';
  const httpServer = await new Promise((resolve, reject) => {
    const server = app.listen(config.port, host, () => {
      logger.info(`TechRen EDU API listening on http://${host}:${config.port} [${config.env}]`);
      resolve(server);
    });
    server.on('error', reject);
  });

  attachSocket(httpServer);

  logger.info(
    `Boot checks: MONGO_URI=${process.env.MONGO_URI ? 'set' : 'MISSING'}, ` +
      `JWT_REFRESH_SECRET=${process.env.JWT_REFRESH_SECRET ? 'set' : 'MISSING'}, ` +
      `FOUNDER_PASSWORD=${process.env.FOUNDER_PASSWORD ? 'set' : 'MISSING'}`
  );

  await connectDB();
  await initDefaults();
  await ensureDevAccounts();
  try {
    const { seedNewsCategories } = require('./services/newsSeedService');
    await seedNewsCategories();
  } catch (e) {
    logger.warn(`News category seed skipped: ${e.message}`);
  }
  initFirebase();
  registerNotificationWorker();
  logger.info('Startup complete');
};

start().catch((error) => {
  logger.error(`Failed to start server: ${error.message}`);
  process.exit(1);
});
