const EventEmitter = require('events');
const notificationService = require('../services/notificationService');
const logger = require('../config/logger');

const bus = new EventEmitter();

const register = () => {
  bus.on('feedback:created', (feedback) => {
    notificationService.notifyFeedbackSubmitted(feedback).catch((error) => {
      logger.warn(`feedback notification handler failed: ${error.message}`);
    });
  });

  logger.info('Notification worker registered');
};

const emit = (event, payload) => bus.emit(event, payload);

module.exports = { register, emit };
