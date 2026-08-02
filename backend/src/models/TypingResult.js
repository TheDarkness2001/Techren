const mongoose = require('mongoose');

const typingResultSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    mode: {
      type: String,
      enum: ['english', 'programming', 'code'],
      required: true,
    },
    difficulty: {
      type: String,
      enum: ['easy', 'medium', 'hard', 'expert'],
      default: 'medium',
    },
    durationSec: { type: Number, default: 60, min: 0 },
    unlimited: { type: Boolean, default: false },
    wpm: { type: Number, required: true, min: 0 },
    rawWpm: { type: Number, default: 0, min: 0 },
    accuracy: { type: Number, required: true, min: 0, max: 100 },
    correctChars: { type: Number, default: 0, min: 0 },
    incorrectChars: { type: Number, default: 0, min: 0 },
    totalChars: { type: Number, default: 0, min: 0 },
    mistakes: { type: Number, default: 0, min: 0 },
    wordsTyped: { type: Number, default: 0, min: 0 },
    correctWords: { type: Number, default: 0, min: 0 },
    wrongWords: { type: Number, default: 0, min: 0 },
    xpEarned: { type: Number, default: 0, min: 0 },
    isDaily: { type: Boolean, default: false, index: true },
    contentId: { type: mongoose.Schema.Types.ObjectId, ref: 'TypingContent', default: null },
    elapsedSec: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true }
);

typingResultSchema.index({ subjectId: 1, wpm: -1 });
typingResultSchema.index({ studentId: 1, subjectId: 1, createdAt: -1 });
typingResultSchema.index({ subjectId: 1, createdAt: -1 });
typingResultSchema.index({ subjectId: 1, isDaily: 1, createdAt: -1 });

module.exports = mongoose.model('TypingResult', typingResultSchema);
