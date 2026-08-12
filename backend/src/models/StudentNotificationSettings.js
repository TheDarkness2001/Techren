const mongoose = require('mongoose');

/** Per-student push category prefs (non-critical). Payment + lock always push. */
const studentNotificationSettingsSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', unique: true, required: true },
    channels: {
      push: { type: Boolean, default: true },
      inApp: { type: Boolean, default: true },
    },
    events: {
      feedback: { type: Boolean, default: true },
      attendance: { type: Boolean, default: true },
      payment: { type: Boolean, default: true }, // reminders still always push (business rule)
      messages: { type: Boolean, default: true },
      news: { type: Boolean, default: true },
      exam: { type: Boolean, default: true },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('StudentNotificationSettings', studentNotificationSettingsSchema);
