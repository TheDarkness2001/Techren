const logger = require('./logger');

let messaging = null;

const initFirebase = () => {
  if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_CLIENT_EMAIL || !process.env.FIREBASE_PRIVATE_KEY) {
    logger.warn('Firebase not configured — push notifications will be logged only');
    return null;
  }

  try {
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

/**
 * Send FCM multicast. Returns invalidTokens for pruning.
 */
const sendPush = async ({ tokens, title, body, data = {} }) => {
  if (!tokens?.length) {
    return { sent: 0, failed: 0, status: 'skipped', reason: 'no_tokens', invalidTokens: [] };
  }

  const unique = [...new Set(tokens.filter(Boolean))];
  if (!unique.length) {
    return { sent: 0, failed: 0, status: 'skipped', reason: 'no_tokens', invalidTokens: [] };
  }

  const safeTitle = String(title || 'TechRen').trim() || 'TechRen';
  const safeBody = String(body || 'New notification').trim() || 'New notification';

  if (!messaging) {
    logger.info(`FCM stub → ${unique.length} token(s): ${safeTitle} — ${safeBody}`);
    return { sent: unique.length, failed: 0, status: 'stub', invalidTokens: [] };
  }

  try {
    const response = await messaging.sendEachForMulticast({
      tokens: unique,
      notification: { title: safeTitle, body: safeBody },
      data: Object.fromEntries(
        Object.entries({
          ...data,
          title: safeTitle,
          body: safeBody,
        }).map(([k, v]) => [k, String(v ?? '')])
      ),
      android: {
        priority: 'high',
        notification: {
          title: safeTitle,
          body: safeBody,
          channelId: 'techren_notifications',
          priority: 'high',
          defaultSound: true,
          // Ensure tray shows text even if the launcher collapses the card.
          visibility: 'public',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title: safeTitle, body: safeBody },
            sound: 'default',
          },
        },
      },
    });

    const invalidTokens = [];
    response.responses.forEach((res, idx) => {
      if (res.success) return;
      const code = res.error?.code || '';
      if (
        code.includes('registration-token-not-registered') ||
        code.includes('invalid-registration-token') ||
        code === 'messaging/invalid-argument'
      ) {
        invalidTokens.push(unique[idx]);
      }
    });

    return {
      sent: response.successCount,
      failed: response.failureCount,
      status: response.failureCount ? 'partial' : 'sent',
      invalidTokens,
    };
  } catch (error) {
    logger.error(`FCM send failed: ${error.message}`);
    return {
      sent: 0,
      failed: unique.length,
      status: 'failed',
      reason: error.message,
      invalidTokens: [],
    };
  }
};

module.exports = { initFirebase, sendPush };
