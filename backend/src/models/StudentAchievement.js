const mongoose = require('mongoose');

const studentAchievementSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    achievementId: { type: mongoose.Schema.Types.ObjectId, ref: 'Achievement', required: true },
    unlockedAt: { type: Date, default: Date.now },
    notified: { type: Boolean, default: false },
  },
  { timestamps: true }
);

studentAchievementSchema.index({ studentId: 1, achievementId: 1 }, { unique: true });

module.exports = mongoose.model('StudentAchievement', studentAchievementSchema);
