const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const timerSchema = new mongoose.Schema(
  {
    listeningMinutes: { type: Number, default: 30 },
    readingMinutes: { type: Number, default: 60 },
    writingMinutes: { type: Number, default: 60 },
    speakingMinutes: { type: Number, default: 14 },
  },
  { _id: false }
);

const ieltsExamSchema = new mongoose.Schema(
  {
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true, index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    mode: {
      type: String,
      enum: ['full', 'listening', 'reading', 'writing', 'speaking'],
      default: 'full',
      index: true,
    },
    trainingType: { type: String, enum: ['academic', 'general'], default: 'academic' },
    difficulty: {
      type: String,
      enum: ['easy', 'medium', 'hard', 'official'],
      default: 'official',
    },
    timers: { type: timerSchema, default: () => ({}) },
    published: { type: Boolean, default: false, index: true },
    archived: { type: Boolean, default: false, index: true },
    /** When set in the future, exam auto-publishes once that time is reached */
    publishAt: { type: Date, default: null, index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
  },
  { timestamps: true }
);

ieltsExamSchema.plugin(softDeletePlugin);

ieltsExamSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    subjectId: this.subjectId,
    title: this.title,
    description: this.description,
    mode: this.mode,
    trainingType: this.trainingType,
    difficulty: this.difficulty,
    timers: this.timers,
    published: this.published,
    archived: this.archived === true,
    publishAt: this.publishAt || null,
    createdBy: this.createdBy,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('IeltsExam', ieltsExamSchema);
