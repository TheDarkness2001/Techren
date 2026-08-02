const mongoose = require('mongoose');

const typingStudentStatsSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true },
    bestWpm: { type: Number, default: 0, min: 0 },
    averageWpm: { type: Number, default: 0, min: 0 },
    averageAccuracy: { type: Number, default: 0, min: 0, max: 100 },
    testsCompleted: { type: Number, default: 0, min: 0 },
    wordsTyped: { type: Number, default: 0, min: 0 },
    charactersTyped: { type: Number, default: 0, min: 0 },
    timePracticedSec: { type: Number, default: 0, min: 0 },
    lastResultId: { type: mongoose.Schema.Types.ObjectId, ref: 'TypingResult', default: null },
    lastWpm: { type: Number, default: 0, min: 0 },
    favoriteMode: { type: String, default: null },
    modeCounts: {
      english: { type: Number, default: 0 },
      programming: { type: Number, default: 0 },
      code: { type: Number, default: 0 },
    },
    settings: {
      fontSize: { type: Number, default: 22 },
      caretStyle: { type: String, default: 'line' },
      typingSound: { type: Boolean, default: false },
      keyboardSound: { type: Boolean, default: false },
      countdown: { type: Boolean, default: true },
      showKeyboard: { type: Boolean, default: false },
      showLiveWpm: { type: Boolean, default: true },
      showLiveAccuracy: { type: Boolean, default: true },
    },
    dailyCompletions: [{ type: String }], // YYYY-MM-DD UTC
  },
  { timestamps: true }
);

typingStudentStatsSchema.index({ studentId: 1, subjectId: 1 }, { unique: true });
typingStudentStatsSchema.index({ subjectId: 1, bestWpm: -1 });

module.exports = mongoose.model('TypingStudentStats', typingStudentStatsSchema);
