const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const sentenceSchema = new mongoose.Schema(
  {
    english: { type: String, required: true, trim: true },
    uzbek: { type: String, required: true, trim: true },
    lessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', required: true },
    task: { type: String, trim: true, default: '' },
    imageUrl: { type: String, trim: true, default: '' },
  },
  { timestamps: true }
);

sentenceSchema.index({ lessonId: 1 });
sentenceSchema.index(
  { lessonId: 1, english: 1 },
  {
    unique: true,
    partialFilterExpression: { isDeleted: { $ne: true } },
    collation: { locale: 'en', strength: 2 },
  }
);
sentenceSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('Sentence', sentenceSchema);
