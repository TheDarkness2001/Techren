const mongoose = require('mongoose');
const { roundToHalf } = require('./IeltsWritingReview');

const ieltsSpeakingReviewSchema = new mongoose.Schema(
  {
    attemptId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'IeltsAttempt',
      required: true,
      unique: true,
      index: true,
    },
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
    fluencyCoherence: { type: Number, required: true, min: 0, max: 9 },
    lexicalResource: { type: Number, required: true, min: 0, max: 9 },
    grammaticalRange: { type: Number, required: true, min: 0, max: 9 },
    pronunciation: { type: Number, required: true, min: 0, max: 9 },
    overallBand: { type: Number, required: true, min: 0, max: 9 },
    comments: { type: String, default: '' },
  },
  { timestamps: true }
);

ieltsSpeakingReviewSchema.statics.computeOverall = function computeOverall({
  fluencyCoherence,
  lexicalResource,
  grammaticalRange,
  pronunciation,
}) {
  const mean =
    (Number(fluencyCoherence) +
      Number(lexicalResource) +
      Number(grammaticalRange) +
      Number(pronunciation)) /
    4;
  return roundToHalf(mean);
};

ieltsSpeakingReviewSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    attemptId: this.attemptId,
    teacherId: this.teacherId,
    fluencyCoherence: this.fluencyCoherence,
    lexicalResource: this.lexicalResource,
    grammaticalRange: this.grammaticalRange,
    pronunciation: this.pronunciation,
    overallBand: this.overallBand,
    comments: this.comments,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('IeltsSpeakingReview', ieltsSpeakingReviewSchema);
