const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const ieltsSectionSchema = new mongoose.Schema(
  {
    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsExam', required: true, index: true },
    skill: {
      type: String,
      enum: ['listening', 'reading', 'writing', 'speaking'],
      required: true,
      index: true,
    },
    order: { type: Number, default: 0 },
    title: { type: String, default: '', trim: true },
    instructions: { type: String, default: '' },
    /** Listening Part 1–4, or Reading Passage 1–3 (optional) */
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
    /** Academic Task 1 visual / GT letter subtype */
    writingSubtype: {
      type: String,
      enum: [
        'chart',
        'graph',
        'table',
        'diagram',
        'map',
        'process',
        'letter_formal',
        'letter_semi_formal',
        'letter_informal',
        'essay_opinion',
        'essay_discussion',
        'essay_problem_solution',
        'essay_advantage_disadvantage',
        'essay_two_part',
      ],
      default: undefined,
    },
    minWords: { type: Number, default: 0 },
    /** Suggested minutes for this writing task (Task 1 ≈ 20, Task 2 ≈ 40) */
    suggestedMinutes: { type: Number, default: 0 },
    /** Speaking cue-card / topic text */
    speakingPrompt: { type: String, default: '' },
    /** Speaking part (MVP defaults to cue-card Part 2) */
    speakingPart: { type: Number, min: 1, max: 3, default: 2 },
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
    writingSubtype: this.writingSubtype || null,
    minWords: this.minWords,
    suggestedMinutes: this.suggestedMinutes || 0,
    speakingPrompt: this.speakingPrompt || '',
    speakingPart: this.speakingPart ?? 2,
  };
};

module.exports = mongoose.model('IeltsSection', ieltsSectionSchema);
