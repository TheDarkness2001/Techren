const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const pollOptionSchema = new mongoose.Schema(
  {
    label: { type: String, required: true, trim: true },
    order: { type: Number, default: 0 },
  },
  { _id: true }
);

const audienceSchema = new mongoose.Schema(
  {
    mode: {
      type: String,
      enum: ['everyone', 'roles', 'subjects', 'groups', 'branches'],
      default: 'everyone',
    },
    roles: [{ type: String }],
    subjectIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Subject' }],
    examGroupIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'ExamGroup' }],
    branchIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Branch' }],
  },
  { _id: false }
);

const pollSchema = new mongoose.Schema(
  {
    postId: { type: mongoose.Schema.Types.ObjectId, ref: 'NewsPost', default: null, index: true },
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      default: null,
      index: true,
    },
    question: { type: String, required: true, trim: true },
    pollType: {
      type: String,
      enum: ['single', 'multiple', 'yes_no', 'true_false', 'rating', 'emoji'],
      default: 'single',
    },
    options: {
      type: [pollOptionSchema],
      validate: [(v) => v.length >= 2 && v.length <= 10, 'Poll needs 2–10 options'],
    },
    allowChangeVote: { type: Boolean, default: false },
    resultsVisibility: {
      type: String,
      enum: ['immediate', 'after_close', 'percent_only', 'counts', 'voters', 'anonymous'],
      default: 'immediate',
    },
    startsAt: { type: Date, default: null },
    endsAt: { type: Date, default: null },
    status: {
      type: String,
      enum: ['draft', 'scheduled', 'published', 'closed', 'archived'],
      default: 'draft',
      index: true,
    },
    audience: { type: audienceSchema, default: () => ({ mode: 'everyone' }) },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
  },
  { timestamps: true }
);

pollSchema.plugin(softDeletePlugin);

module.exports = mongoose.model('Poll', pollSchema);
