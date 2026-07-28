const mongoose = require('mongoose');

const roundToHalf = (n) => Math.round(n * 2) / 2;

const ieltsWritingReviewSchema = new mongoose.Schema(
  {
    attemptId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'IeltsAttempt',
      required: true,
      unique: true,
      index: true,
    },
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
    taskAchievement: { type: Number, required: true, min: 0, max: 9 },
    coherenceCohesion: { type: Number, required: true, min: 0, max: 9 },
    lexicalResource: { type: Number, required: true, min: 0, max: 9 },
    grammaticalRange: { type: Number, required: true, min: 0, max: 9 },
    overallBand: { type: Number, required: true, min: 0, max: 9 },
    comments: { type: String, default: '' },
    corrections: { type: String, default: '' },
  },
  { timestamps: true }
);

ieltsWritingReviewSchema.statics.computeOverall = function computeOverall({
  taskAchievement,
  coherenceCohesion,
  lexicalResource,
  grammaticalRange,
}) {
  const mean = (Number(taskAchievement) + Number(coherenceCohesion) + Number(lexicalResource) + Number(grammaticalRange)) / 4;
  return roundToHalf(mean);
};

ieltsWritingReviewSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    attemptId: this.attemptId,
    teacherId: this.teacherId,
    taskAchievement: this.taskAchievement,
    coherenceCohesion: this.coherenceCohesion,
    lexicalResource: this.lexicalResource,
    grammaticalRange: this.grammaticalRange,
    overallBand: this.overallBand,
    comments: this.comments,
    corrections: this.corrections,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('IeltsWritingReview', ieltsWritingReviewSchema);
module.exports.roundToHalf = roundToHalf;
