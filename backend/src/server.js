const config = require('./config');
const logger = require('./config/logger');
const connectDB = require('./config/database');
const { initDefaults } = require('./services/settingsService');
const { ensureDevAccounts } = require('./services/bootstrapService');
const createApp = require('./app');
const { initFirebase } = require('./config/firebase');
const { register: registerNotificationWorker } = require('./utils/notificationWorker');

const start = async () => {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();
  initFirebase();
  registerNotificationWorker();

  const app = createApp();
  const host = process.env.HOST || '0.0.0.0';
  app.listen(config.port, host, () => {
    logger.info(`TechRen EDU API listening on http://${host}:${config.port} [${config.env}]`);
  });
};

start().catch((error) => {
  logger.error(`Failed to start server: ${error.message}`);
  process.exit(1);
});
