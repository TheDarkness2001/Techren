const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const questionSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['mcq', 'form_completion'],
      required: true,
    },
    prompt: { type: String, required: true, trim: true },
    /** MCQ options (A–D). Ignored for form_completion. */
    options: { type: [String], default: [] },
    /** 0-based correct option for mcq. */
    correctOptionIndex: { type: Number, default: 0 },
    /** Expected answers for each blank in form_completion (___). */
    answers: { type: [String], default: [] },
    points: { type: Number, default: 1, min: 0 },
  },
  { _id: true }
);

const learningQuizSchema = new mongoose.Schema(
  {
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    title: { type: String, required: true, trim: true },
    topic: { type: String, required: true, trim: true },
    level: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    published: { type: Boolean, default: false, index: true },
    unlockedFor: [{ type: mongoose.Schema.Types.ObjectId, ref: 'ExamGroup' }],
    passingScore: { type: Number, default: 70, min: 0, max: 100 },
    timeLimitMinutes: { type: Number, default: 0, min: 0 },
    questions: { type: [questionSchema], default: [] },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
  },
  { timestamps: true }
);

learningQuizSchema.plugin(softDeletePlugin);
learningQuizSchema.index({ subjectId: 1, level: 1, topic: 1 });

module.exports = mongoose.model('LearningQuiz', learningQuizSchema);
