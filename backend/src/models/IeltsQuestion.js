const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const QUESTION_TYPES = [
  'mcq',
  'matching',
  'form_completion',
  'sentence_completion',
  'short_answer',
  'tfng',
  'ynng',
  'matching_headings',
  'summary_completion',
  'task1',
  'task2',
];

const ieltsQuestionSchema = new mongoose.Schema(
  {
    sectionId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsSection', required: true, index: true },
    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsExam', required: true, index: true },
    order: { type: Number, default: 0 },
    number: { type: Number, default: 1 },
    type: { type: String, enum: QUESTION_TYPES, required: true },
    prompt: { type: String, default: '' },
    options: [{ type: String }],
    /** Accepted answers (strings). Matching may use "A=1" style keys. */
    answers: [{ type: String }],
    points: { type: Number, default: 1 },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

ieltsQuestionSchema.plugin(softDeletePlugin);
ieltsQuestionSchema.index({ sectionId: 1, order: 1 });

ieltsQuestionSchema.methods.toPublicJSON = function toPublicJSON({ includeAnswers = false } = {}) {
  return {
    id: this._id,
    sectionId: this.sectionId,
    examId: this.examId,
    order: this.order,
    number: this.number,
    type: this.type,
    prompt: this.prompt,
    options: this.options || [],
    points: this.points,
    metadata: this.metadata || {},
    answers: includeAnswers ? this.answers || [] : undefined,
  };
};

module.exports = mongoose.model('IeltsQuestion', ieltsQuestionSchema);
module.exports.QUESTION_TYPES = QUESTION_TYPES;
