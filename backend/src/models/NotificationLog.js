const mongoose = require('mongoose');

const notificationLogSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    userType: { type: String, enum: ['student', 'teacher', 'parent'], required: true },
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', index: true },
    title: { type: String, required: true, trim: true },
    body: { type: String, required: true, trim: true },
    eventType: { type: String, required: true, index: true },
    channel: { type: String, enum: ['in_app', 'push'], default: 'in_app' },
    date: { type: String, required: true },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
    readAt: { type: Date, default: null },
    pushStatus: { type: String, enum: ['pending', 'sent', 'failed', 'skipped', 'stub'], default: 'pending' },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch' },
  },
  { timestamps: true }
);

notificationLogSchema.index({ userId: 1, userType: 1, createdAt: -1 });
notificationLogSchema.index({ userId: 1, userType: 1, readAt: 1 });
notificationLogSchema.index(
  { studentId: 1, eventType: 1, date: 1, channel: 1 },
  { unique: true, partialFilterExpression: { channel: 'push', studentId: { $exists: true } } }
);

module.exports = mongoose.model('NotificationLog', notificationLogSchema);
