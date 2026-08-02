const mongoose = require('mongoose');

const userPresenceSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true },
    userType: { type: String, enum: ['teacher', 'student'], required: true },
    status: { type: String, enum: ['online', 'offline'], default: 'offline' },
    lastSeenAt: { type: Date, default: Date.now },
    socketIds: { type: [String], default: [] },
  },
  { timestamps: true }
);

userPresenceSchema.index({ userId: 1, userType: 1 }, { unique: true });

module.exports = mongoose.model('UserPresence', userPresenceSchema);
