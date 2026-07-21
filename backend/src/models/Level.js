const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const levelSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    languageId: { type: mongoose.Schema.Types.ObjectId, ref: 'Language', required: true },
    classesCount: { type: Number, default: 11, min: 1 },
    wordsPerClass: { type: Number, default: 20, min: 1 },
    examTimeLimit: { type: Number, default: 300, min: 30 },
    minPassScore: { type: Number, default: 70, min: 1, max: 100 },
    practiceUnlockedFor: [{ type: mongoose.Schema.Types.ObjectId, ref: 'ExamGroup' }],
    moduleType: { type: String, enum: ['words', 'sentences', 'listening'], default: 'words' },
    order: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true }
);

levelSchema.index({ languageId: 1, name: 1 });
levelSchema.index({ languageId: 1, moduleType: 1, order: 1 });
levelSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('Level', levelSchema);
