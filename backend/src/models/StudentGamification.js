const mongoose = require('mongoose');

const studentGamificationSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', unique: true, required: true },
    totalXp: { type: Number, default: 0, min: 0 },
    level: { type: Number, default: 1, min: 1 },
    currentStreak: { type: Number, default: 0, min: 0 },
    longestStreak: { type: Number, default: 0, min: 0 },
    lastActivityDate: { type: String, default: null },
    moduleXp: {
      words: { type: Number, default: 0, min: 0 },
      sentences: { type: Number, default: 0, min: 0 },
      listening: { type: Number, default: 0, min: 0 },
      video: { type: Number, default: 0, min: 0 },
    },
  },
  { timestamps: true }
);

studentGamificationSchema.index({ totalXp: -1 });

module.exports = mongoose.model('StudentGamification', studentGamificationSchema);
