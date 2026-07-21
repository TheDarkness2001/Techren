const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const wordSchema = new mongoose.Schema(
  {
    english: { type: String, required: true, trim: true },
    uzbek: { type: String, required: true, trim: true },
    lessonId: { type: mongoose.Schema.Types.ObjectId, ref: 'Lesson', required: true },
  },
  { timestamps: true }
);

wordSchema.index({ lessonId: 1 });
wordSchema.index(
  { lessonId: 1, english: 1 },
  {
    unique: true,
    partialFilterExpression: { isDeleted: { $ne: true } },
    collation: { locale: 'en', strength: 2 },
  }
);
wordSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('Word', wordSchema);
