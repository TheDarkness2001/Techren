const mongoose = require('mongoose');

const answerSchema = new mongoose.Schema(
  {
    questionId: { type: mongoose.Schema.Types.ObjectId, required: true },
    selectedOptionIndex: { type: Number, default: null },
    textAnswers: { type: [String], default: [] },
    correct: { type: Boolean, default: false },
    pointsAwarded: { type: Number, default: 0 },
  },
  { _id: false }
);

const learningQuizAttemptSchema = new mongoose.Schema(
  {
    quizId: { type: mongoose.Schema.Types.ObjectId, ref: 'LearningQuiz', required: true, index: true },
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    status: {
      type: String,
      enum: ['in_progress', 'submitted'],
      default: 'in_progress',
      index: true,
    },
    answers: { type: [answerSchema], default: [] },
    scorePercent: { type: Number, default: 0 },
    pointsEarned: { type: Number, default: 0 },
    pointsPossible: { type: Number, default: 0 },
    passed: { type: Boolean, default: false },
    startedAt: { type: Date, default: Date.now },
    submittedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

learningQuizAttemptSchema.index({ studentId: 1, quizId: 1, createdAt: -1 });

module.exports = mongoose.model('LearningQuizAttempt', learningQuizAttemptSchema);
