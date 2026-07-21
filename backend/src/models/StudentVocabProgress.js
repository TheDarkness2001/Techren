const mongoose = require('mongoose');

const studentVocabProgressSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
    lessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', required: true },
    examAttempts: { type: Number, default: 0 },
    bestExamScore: { type: Number, default: 0 },
    lastExamDate: { type: Date, default: null },
    status: { type: String, enum: ['locked', 'available', 'passed'], default: 'locked' },
    unlockedAt: { type: Date, default: null },
    practiceAttempts: { type: Number, default: 0 },
    practiceCorrect: { type: Number, default: 0 },
    lastPracticeDate: { type: Date, default: null },
    wordsMemorized: { type: Number, default: 0 },
    wordsTotal: { type: Number, default: 0 },
  },
  { timestamps: true }
);

studentVocabProgressSchema.index({ studentId: 1, lessonId: 1 }, { unique: true });

module.exports = mongoose.model('StudentVocabProgress', studentVocabProgressSchema);
