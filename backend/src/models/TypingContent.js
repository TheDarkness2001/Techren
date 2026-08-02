const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const typingContentSchema = new mongoose.Schema(
  {
    kind: {
      type: String,
      enum: ['english', 'uzbek', 'programming', 'code'],
      required: true,
      index: true,
    },
    title: { type: String, required: true, trim: true },
    difficulty: {
      type: String,
      enum: ['easy', 'medium', 'hard', 'expert'],
      default: 'medium',
      index: true,
    },
    language: {
      type: String,
      enum: ['javascript', 'python', 'arduino', 'typescript', 'html', 'css', 'other'],
    },
    words: [{ type: String, trim: true }],
    code: { type: String, default: '' },
    published: { type: Boolean, default: true, index: true },
  },
  { timestamps: true }
);

typingContentSchema.index({ kind: 1, difficulty: 1, published: 1 });
typingContentSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('TypingContent', typingContentSchema);
