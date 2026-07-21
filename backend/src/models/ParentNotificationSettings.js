const mongoose = require('mongoose');

const parentNotificationSettingsSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', unique: true, required: true },
    channels: {
      push: { type: Boolean, default: true },
      inApp: { type: Boolean, default: true },
    },
    events: {
      feedback: { type: Boolean, default: true },
      attendance: { type: Boolean, default: true },
      payment: { type: Boolean, default: true },
      exam: { type: Boolean, default: true },
    },
    quietHoursStart: { type: String, default: '22:00' },
    quietHoursEnd: { type: String, default: '08:00' },
    timezone: { type: String, default: 'Asia/Tashkent' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('ParentNotificationSettings', parentNotificationSettingsSchema);
