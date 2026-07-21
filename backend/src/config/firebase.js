const logger = require('./logger');

let messaging = null;

const initFirebase = () => {
  if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL || !process.env.FIREBASE_PRIVATE_KEY) {
    logger.warn('Firebase not configured — push notifications will be logged only');
    return null;
  }

  try {
    // Optional dependency: only loaded when credentials are present.
    // eslint-disable-next-line global-require, import/no-extraneous-dependencies
    const admin = require('firebase-admin');
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
    }
    messaging = admin.messaging();
    logger.info('Firebase FCM initialized');
  } catch (error) {
    logger.warn(`Firebase init skipped: ${error.message}`);
    messaging = null;
  }

  return messaging;
};

const sendPush = async ({ tokens, title, body, data = {} }) => {
  if (!tokens?.length) {
    return { sent: 0, failed: 0, status: 'skipped', reason: 'no_tokens' };
  }

  if (!messaging) {
    logger.info(`FCM stub → ${tokens.length} token(s): ${title} — ${body}`);
    return { sent: tokens.length, failed: 0, status: 'stub' };
  }

  try {
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    });
    return {
      sent: response.successCount,
      failed: response.failureCount,
      status: response.failureCount ? 'partial' : 'sent',
    };
  } catch (error) {
    logger.error(`FCM send failed: ${error.message}`);
    return { sent: 0, failed: tokens.length, status: 'failed', reason: error.message };
  }
};

module.exports = { initFirebase, sendPush };
