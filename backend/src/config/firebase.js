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

const isChatPayload = (data = {}) => {
  const eventType = String(data.eventType || '').toLowerCase();
  const screen = String(data.screen || '').toLowerCase();
  return (
    eventType.includes('chat') ||
    eventType.includes('message') ||
    screen === 'messages' ||
    screen === 'chat' ||
    String(data.actions || '') === 'chat'
  );
};

/**
 * Send FCM multicast. Returns invalidTokens for pruning.
 * Chat: Android is data-only so the app can attach Reply / Mark as read actions.
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
  const chat = isChatPayload(data);

  if (!messaging) {
    logger.info(`FCM stub → ${unique.length} token(s): ${safeTitle} — ${safeBody}`);
    return { sent: unique.length, failed: 0, status: 'stub', invalidTokens: [] };
  }

  try {
    const payloadData = Object.fromEntries(
      Object.entries({
        ...data,
        title: safeTitle,
        body: safeBody,
        ...(chat ? { actions: 'chat' } : {}),
      }).map(([k, v]) => [k, String(v ?? '')])
    );

    /** @type {import('firebase-admin/messaging').MulticastMessage} */
    const message = {
      tokens: unique,
      data: payloadData,
      android: {
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            alert: { title: safeTitle, body: safeBody },
            sound: 'default',
            ...(chat ? { category: 'CHAT_MESSAGE' } : {}),
          },
        },
      },
    };

    if (chat) {
      // Data-only on Android so flutter_local_notifications can show Reply / Mark as read.
      // iOS still gets APNs alert above.
    } else {
      message.notification = { title: safeTitle, body: safeBody };
      message.android.notification = {
        title: safeTitle,
        body: safeBody,
        channelId: 'techren_notifications',
        priority: 'high',
        defaultSound: true,
        visibility: 'public',
      };
    }

    const response = await messaging.sendEachForMulticast(message);

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
