const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const languageSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    moduleType: { type: String, enum: ['words', 'sentences', 'listening'], required: true },
  },
  { timestamps: true }
);

languageSchema.index({ name: 1, moduleType: 1 }, { unique: true });
languageSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('Language', languageSchema);
