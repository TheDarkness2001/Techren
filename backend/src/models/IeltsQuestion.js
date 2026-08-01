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
  'table_completion',
  'map_labeling',
  'diagram_labeling',
  'task1',
  'task2',
];

const blankSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    label: { type: String, default: '' },
    order: { type: Number, default: 0 },
  },
  { _id: false }
);

const acceptedAnswersSchema = new mongoose.Schema(
  {
    primary: { type: String, default: '' },
    alternatives: [{ type: String }],
    synonyms: [{ type: String }],
    rejected: [{ type: String }],
    explanation: { type: String, default: '' },
  },
  { _id: false }
);

const ieltsQuestionSchema = new mongoose.Schema(
  {
    sectionId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsSection', required: true, index: true },
    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsExam', required: true, index: true },
    order: { type: Number, default: 0 },
    number: { type: Number, default: 1 },
    type: { type: String, enum: QUESTION_TYPES, required: true },
    prompt: { type: String, default: '' },
    /** Visible instruction e.g. NO MORE THAN TWO WORDS AND/OR A NUMBER */
    instruction: { type: String, default: '' },
    options: [{ type: String }],
    /** Legacy accepted answers (strings). Still scored via answer engine. */
    answers: [{ type: String }],
    acceptedAnswers: { type: acceptedAnswersSchema, default: undefined },
    blanks: { type: [blankSchema], default: undefined },
    wordLimit: {
      type: String,
      enum: [
        'ONE_WORD',
        'TWO_WORDS',
        'THREE_WORDS',
        'NO_MORE_THAN_TWO_WORDS',
        'NO_MORE_THAN_THREE_WORDS',
        'ONE_NUMBER',
        'ONE_WORD_AND_OR_A_NUMBER',
        'NO_MORE_THAN_TWO_WORDS_AND_OR_A_NUMBER',
      ],
      default: null,
    },
    allowArticles: { type: Boolean, default: false },
    allowPlurals: { type: Boolean, default: false },
    selectionMode: { type: String, enum: ['single', 'multiple'], default: 'single' },
    matchingStyle: {
      type: String,
      enum: ['dropdown', 'drag_drop', 'cards'],
      default: 'dropdown',
    },
    /** HTML / template for summary, form, table layouts */
    contentHtml: { type: String, default: '' },
    layout: {
      type: String,
      enum: ['default', 'paragraph', 'table', 'notes', 'summary', 'flow_chart', 'form'],
      default: 'default',
    },
    points: { type: Number, default: 1 },
    /** Optional frozen bank version this exam question was cloned from */
    bankVersionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'IeltsQuestionVersion',
      default: null,
      index: true,
    },
    /** Extensible: blankAnswers, matchingPairs, headings, paragraphs, imageUrl, hotspots, etc. */
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true }
);

ieltsQuestionSchema.plugin(softDeletePlugin);
ieltsQuestionSchema.index({ sectionId: 1, order: 1 });

ieltsQuestionSchema.methods.toPublicJSON = function toPublicJSON({ includeAnswers = false } = {}) {
  const json = {
    id: this._id,
    sectionId: this.sectionId,
    examId: this.examId,
    order: this.order,
    number: this.number,
    type: this.type,
    prompt: this.prompt,
    instruction: this.instruction || '',
    options: this.options || [],
    blanks: this.blanks || [],
    wordLimit: this.wordLimit || null,
    allowArticles: this.allowArticles === true,
    allowPlurals: this.allowPlurals === true,
    selectionMode: this.selectionMode || 'single',
    matchingStyle: this.matchingStyle || 'dropdown',
    contentHtml: this.contentHtml || '',
    layout: this.layout || 'default',
    points: this.points,
    bankVersionId: this.bankVersionId || null,
    metadata: this.metadata || {},
  };
  if (includeAnswers) {
    json.answers = this.answers || [];
    json.acceptedAnswers = this.acceptedAnswers || undefined;
  }
  return json;
};

module.exports = mongoose.model('IeltsQuestion', ieltsQuestionSchema);
module.exports.QUESTION_TYPES = QUESTION_TYPES;
