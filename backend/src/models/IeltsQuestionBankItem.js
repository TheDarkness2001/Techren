const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const bankItemSchema = new mongoose.Schema(
  {
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', index: true },
    skill: { type: String, enum: ['listening', 'reading'], required: true, index: true },
    type: { type: String, required: true, index: true },
    title: { type: String, default: '', trim: true },
    topic: { type: String, default: 'General' },
    difficulty: { type: String, default: 'Medium' },
    tags: [{ type: String }],
    sourceId: { type: mongoose.Schema.Types.ObjectId, ref: 'IeltsSource', default: null },
    status: { type: String, enum: ['draft', 'active', 'archived'], default: 'active', index: true },
    latestVersion: { type: Number, default: 1 },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', default: null },
  },
  { timestamps: true }
);

bankItemSchema.plugin(softDeletePlugin);
bankItemSchema.index({ subjectId: 1, skill: 1, type: 1, topic: 1 });

bankItemSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    subjectId: this.subjectId,
    skill: this.skill,
    type: this.type,
    title: this.title,
    topic: this.topic,
    difficulty: this.difficulty,
    tags: this.tags || [],
    sourceId: this.sourceId,
    status: this.status,
    latestVersion: this.latestVersion,
    createdBy: this.createdBy,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('IeltsQuestionBankItem', bankItemSchema);
