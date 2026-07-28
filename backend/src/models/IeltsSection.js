const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const ieltsSectionSchema = new mongoose.Schema(
  {
    examId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsExam', required: true, index: true },
    skill: { type: String, enum: ['listening', 'reading', 'writing'], required: true, index: true },
    order: { type: Number, default: 0 },
    title: { type: String, default: '', trim: true },
    instructions: { type: String, default: '' },
    /** Listening audio relative path under uploads/ielts */
    audioFile: { type: String, default: null },
    /** Reading passage HTML/text */
    passage: { type: String, default: '' },
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

ieltsSectionSchema.methods.toPublicJSON = function toPublicJSON({ includeAudioPath = false } = {}) {
  return {
    id: this._id,
    examId: this.examId,
    skill: this.skill,
    order: this.order,
    title: this.title,
    instructions: this.instructions,
    hasAudio: Boolean(this.audioFile),
    audioFile: includeAudioPath ? this.audioFile : undefined,
    passage: this.passage,
    prompt: this.prompt,
    imageUrl: this.imageUrl,
    writingTask: this.writingTask,
    minWords: this.minWords,
  };
};

module.exports = mongoose.model('IeltsSection', ieltsSectionSchema);
