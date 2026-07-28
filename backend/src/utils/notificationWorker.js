const EventEmitter = require('events');
const notificationService = require('../services/notificationService');
const logger = require('../config/logger');

const bus = new EventEmitter();
let paymentReminderTimer = null;

const register = () => {
  bus.on('feedback:created', (feedback) => {
    notificationService.notifyFeedbackSubmitted(feedback).catch((error) => {
      logger.warn(`feedback notification handler failed: ${error.message}`);
    });
  });

  bus.on('attendance:marked', (payload) => {
    notificationService.notifyAttendanceMarked(payload).catch((error) => {
      logger.warn(`attendance notification handler failed: ${error.message}`);
    });
  });

  if (paymentReminderTimer) clearInterval(paymentReminderTimer);
  // Check every minute for payment reminder slots (1–7 once/day, 8–10 three/day).
  paymentReminderTimer = setInterval(() => {
    notificationService.runPaymentDueReminders().catch((error) => {
      logger.warn(`payment due reminder job failed: ${error.message}`);
    });
  }, 60 * 1000);

  // Kick once shortly after boot in case we restart during a slot window.
  setTimeout(() => {
    notificationService.runPaymentDueReminders().catch((error) => {
      logger.warn(`payment due reminder boot tick failed: ${error.message}`);
    });
  }, 15 * 1000);

  logger.info('Notification worker registered (feedback, attendance, payment reminders)');
};

const emit = (event, payload) => bus.emit(event, payload);

module.exports = { register, emit };
