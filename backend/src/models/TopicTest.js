const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['multiple-choice', 'fill-blank', 'translation', 'true-false', 'short-answer'],
      required: true,
    },
    question: { type: String, required: true, trim: true },
    options: { type: [String], default: [] },
    correctAnswer: { type: mongoose.Schema.Types.Mixed, required: true },
    explanation: { type: String, default: '' },
    points: { type: Number, default: 1 },
  },
  { _id: true }
);

const topicTestSchema = new mongoose.Schema(
  {
    videoLessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'VideoLesson', required: true, unique: true },
    title: { type: String, default: '' },
    practiceEnabled: { type: Boolean, default: true },
    examEnabled: { type: Boolean, default: true },
    timerSeconds: { type: Number, default: 300 },
    passingScore: { type: Number, default: 70, min: 0, max: 100 },
    randomizeQuestions: { type: Boolean, default: true },
    questions: { type: [questionSchema], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('TopicTest', topicTestSchema);
