const mongoose = require('mongoose');

const roundToHalf = (n) => Math.round(n * 2) / 2;

const criteriaSchema = new mongoose.Schema(
  {
    taskAchievement: { type: Number, min: 0, max: 9 },
    coherenceCohesion: { type: Number, min: 0, max: 9 },
    lexicalResource: { type: Number, min: 0, max: 9 },
    grammaticalRange: { type: Number, min: 0, max: 9 },
    mean: { type: Number, min: 0, max: 9 },
  },
  { _id: false }
);

const meanOf = ({ taskAchievement, coherenceCohesion, lexicalResource, grammaticalRange }) =>
  roundToHalf(
    (Number(taskAchievement) +
      Number(coherenceCohesion) +
      Number(lexicalResource) +
      Number(grammaticalRange)) /
      4
  );

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
    /** Flat criteria — used for single-task reviews and as Task 2 when both tasks scored */
    taskAchievement: { type: Number, required: true, min: 0, max: 9 },
    coherenceCohesion: { type: Number, required: true, min: 0, max: 9 },
    lexicalResource: { type: Number, required: true, min: 0, max: 9 },
    grammaticalRange: { type: Number, required: true, min: 0, max: 9 },
    overallBand: { type: Number, required: true, min: 0, max: 9 },
    /** Optional per-task bands; overall = (task1 + 2×task2) / 3 when both present */
    task1: { type: criteriaSchema, default: undefined },
    task2: { type: criteriaSchema, default: undefined },
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
  return meanOf({ taskAchievement, coherenceCohesion, lexicalResource, grammaticalRange });
};

/** Official IELTS writing: Task 2 is worth twice Task 1 → (T1 + 2×T2) / 3 */
ieltsWritingReviewSchema.statics.computeWeightedOverall = function computeWeightedOverall(task1, task2) {
  const m1 = meanOf(task1);
  const m2 = meanOf(task2);
  return roundToHalf((m1 + 2 * m2) / 3);
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
    task1: this.task1 || null,
    task2: this.task2 || null,
    comments: this.comments,
    corrections: this.corrections,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('IeltsWritingReview', ieltsWritingReviewSchema);
module.exports.roundToHalf = roundToHalf;
module.exports.meanOf = meanOf;
