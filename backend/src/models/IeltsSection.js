const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const ieltsSectionSchema = new mongoose.Schema(
  {
    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsExam', required: true, index: true },
    skill: { type: String, enum: ['listening', 'reading', 'writing'], required: true, index: true },
    order: { type: Number, default: 0 },
    title: { type: String, default: '', trim: true },
    instructions: { type: String, default: '' },
    /** Listening Part 1–4 (optional) */
    part: { type: Number, min: 1, max: 4, default: null },
    /** Staff transcript — exposed after submit or to staff */
    transcript: { type: String, default: '' },
    /** Optional library source */
    sourceId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsSource', default: null, index: true },
    /** Listening audio relative path under uploads/ielts */
    audioFile: { type: String, default: null },
    /** Reading passage HTML/text */
    passage: { type: String, default: '' },
    /** Passage format: plain | html */
    passageFormat: { type: String, enum: ['plain', 'html'], default: 'plain' },
    /** Staff-only answer highlight ranges (HTML ids / markers) */
    answerHighlights: { type: String, default: '' },
    /** Writing prompt */
    prompt: { type: String, default: '' },
    /** Task 1 chart/image URL */
    imageUrl: { type: String, default: null },
    writingTask: { type: String, enum: ['task1', 'task2'], default: undefined },
    minWords: { type: Number, default: 0 },
  },
  { timestamps: true }
);

ieltsSectionSchema.plugin(softDeletePlugin);
ieltsSectionSchema.index({ examId: 1, order: 1 });

ieltsSectionSchema.methods.toPublicJSON = function toPublicJSON({
  includeAudioPath = false,
  includeTranscript = false,
} = {}) {
  return {
    id: this._id,
    examId: this.examId,
    skill: this.skill,
    order: this.order,
    title: this.title,
    instructions: this.instructions,
    part: this.part ?? null,
    hasAudio: Boolean(this.audioFile),
    audioFile: includeAudioPath ? this.audioFile : undefined,
    transcript: includeTranscript ? this.transcript || '' : undefined,
    sourceId: this.sourceId || null,
    passage: this.passage,
    passageFormat: this.passageFormat || 'plain',
    answerHighlights: includeTranscript ? this.answerHighlights || '' : undefined,
    prompt: this.prompt,
    imageUrl: this.imageUrl,
    writingTask: this.writingTask,
    minWords: this.minWords,
  };
};

module.exports = mongoose.model('IeltsSection', ieltsSectionSchema);
