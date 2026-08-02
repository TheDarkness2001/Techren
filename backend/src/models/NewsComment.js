const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const newsCommentSchema = new mongoose.Schema(
  {
    postId: { type: mongoose.Schema.Types.ObjectId, ref: 'NewsPost', required: true, index: true },
    parentId: { type: mongoose.Schema.Types.ObjectId, ref: 'NewsComment', default: null },
    authorId: { type: mongoose.Schema.Types.ObjectId, required: true },
    authorType: { type: String, enum: ['teacher', 'student'], required: true },
    authorName: { type: String, default: '' },
    body: { type: String, required: true, trim: true },
  },
  { timestamps: true }
);

newsCommentSchema.plugin(softDeletePlugin);
newsCommentSchema.index({ postId: 1, createdAt: -1 });

module.exports = mongoose.model('NewsComment', newsCommentSchema);
