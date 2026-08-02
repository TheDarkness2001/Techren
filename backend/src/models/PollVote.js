const mongoose = require('mongoose');

const pollVoteSchema = new mongoose.Schema(
  {
    pollId: { type: mongoose.Schema.Types.ObjectId, ref: 'Poll', required: true, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, required: true },
    userType: { type: String, enum: ['teacher', 'student'], required: true },
    optionIds: [{ type: mongoose.Schema.Types.ObjectId, required: true }],
  },
  { timestamps: true }
);

pollVoteSchema.index({ pollId: 1, userId: 1, userType: 1 }, { unique: true });

module.exports = mongoose.model('PollVote', pollVoteSchema);
