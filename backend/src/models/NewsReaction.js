const mongoose = require('mongoose');

const REACTION_EMOJIS = ['like', 'love', 'celebrate', 'fire', 'helpful'];

const newsReactionSchema = new mongoose.Schema(
  {
    postId: { type: mongoose.Schema.Types.ObjectId, ref: 'NewsPost', required: true, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, required: true },
    userType: { type: String, enum: ['teacher', 'student'], required: true },
    emoji: { type: String, enum: REACTION_EMOJIS, required: true },
  },
  { timestamps: true }
);

newsReactionSchema.index({ postId: 1, userId: 1, userType: 1 }, { unique: true });

module.exports = mongoose.model('NewsReaction', newsReactionSchema);
module.exports.REACTION_EMOJIS = REACTION_EMOJIS;
