const mongoose = require('mongoose');

const scoreSchema = new mongoose.Schema(
  {
    listeningRaw: { type: Number, default: null },
    listeningMax: { type: Number, default: null },
    listeningBand: { type: Number, default: null },
    readingRaw: { type: Number, default: null },
    readingMax: { type: Number, default: null },
    readingBand: { type: Number, default: null },
    writingBand: { type: Number, default: null },
    overallBand: { type: Number, default: null },
  },
  { _id: false }
);

const ieltsAttemptSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsExam', required: true, index: true },
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    status: {
      type: String,
      enum: ['in_progress', 'submitted', 'scored'],
      default: 'in_progress',
      index: true,
    },
    /** questionId -> answer string / array */
    answers: { type: Map, of: mongoose.Schema.Types.Mixed, default: {} },
    /** questionId -> flagged */
    flags: { type: Map, of: Boolean, default: {} },
    /** writing sectionId -> essay text */
    writingResponses: { type: Map, of: String, default: {} },
    currentSectionId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsSection', default: null },
    sectionStartedAt: { type: Date, default: null },
    remainingSeconds: { type: Number, default: null },
    audioPlayed: { type: Boolean, default: false },
    startedAt: { type: Date, default: Date.now },
    submittedAt: { type: Date, default: null },
    autosaveAt: { type: Date, default: null },
    scores: { type: scoreSchema, default: () => ({}) },
    questionReview: [
      {
        questionId: mongoose.Schema.Types.ObjectId,
        correct: Boolean,
        studentAnswer: mongoose.Schema.Types.Mixed,
        correctAnswers: [String],
      },
    ],
  },
  { timestamps: true }
);

ieltsAttemptSchema.index({ studentId: 1, examId: 1, status: 1 });
ieltsAttemptSchema.index({ studentId: 1, submittedAt: -1 });

ieltsAttemptSchema.methods.toPublicJSON = function toPublicJSON({ includeKeys = false } = {}) {
  const answers = {};
  if (this.answers) {
    for (const [k, v] of this.answers.entries()) answers[k] = v;
  }
  const flags = {};
  if (this.flags) {
    for (const [k, v] of this.flags.entries()) flags[k] = v;
  }
  const writingResponses = {};
  if (this.writingResponses) {
    for (const [k, v] of this.writingResponses.entries()) writingResponses[k] = v;
  }

  return {
    id: this._id,
    studentId: this.studentId,
    examId: this.examId,
    subjectId: this.subjectId,
    status: this.status,
    answers,
    flags,
    writingResponses,
    currentSectionId: this.currentSectionId,
    sectionStartedAt: this.sectionStartedAt,
    remainingSeconds: this.remainingSeconds,
    audioPlayed: this.audioPlayed,
    startedAt: this.startedAt,
    submittedAt: this.submittedAt,
    autosaveAt: this.autosaveAt,
    scores: this.scores,
    questionReview: includeKeys || this.status !== 'in_progress' ? this.questionReview : undefined,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('IeltsAttempt', ieltsAttemptSchema);
