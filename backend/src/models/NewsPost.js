const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const mediaSchema = new mongoose.Schema(
  {
    url: { type: String, required: true },
    mime: { type: String, default: '' },
    name: { type: String, default: '' },
    size: { type: Number, default: 0 },
    kind: { type: String, enum: ['image', 'video', 'file', 'audio'], default: 'file' },
  },
  { _id: false }
);

const linkSchema = new mongoose.Schema(
  {
    url: { type: String, required: true },
    provider: { type: String, default: '' },
    previewTitle: { type: String, default: '' },
    previewImage: { type: String, default: '' },
    previewDesc: { type: String, default: '' },
  },
  { _id: false }
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

const eventSchema = new mongoose.Schema(
  {
    startsAt: { type: Date },
    endsAt: { type: Date },
    location: { type: String, default: '' },
    joinUrl: { type: String, default: '' },
    registrationUrl: { type: String, default: '' },
    registrations: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId },
        userType: { type: String, enum: ['teacher', 'student'] },
        name: { type: String, default: '' },
        at: { type: Date, default: Date.now },
      },
    ],
  },
  { _id: false }
);

const statsSchema = new mongoose.Schema(
  {
    views: { type: Number, default: 0 },
    clicks: { type: Number, default: 0 },
    reactionCounts: {
      like: { type: Number, default: 0 },
      love: { type: Number, default: 0 },
      celebrate: { type: Number, default: 0 },
      fire: { type: Number, default: 0 },
      helpful: { type: Number, default: 0 },
    },
    commentCount: { type: Number, default: 0 },
  },
  { _id: false }
);

const POST_TYPES = [
  'announcement',
  'news',
  'event',
  'reminder',
  'motivation',
  'quote',
  'success_story',
  'holiday',
  'exam_schedule',
  'class_schedule',
  'job',
  'scholarship',
  'video',
  'social',
  'link',
  'poll_embed',
];

const newsPostSchema = new mongoose.Schema(
  {
    type: { type: String, enum: POST_TYPES, default: 'announcement', index: true },
    title: { type: String, required: true, trim: true },
    body: { type: String, default: '' },
    category: { type: String, default: 'News', index: true },
    tags: [{ type: String }],
    authorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
    authorType: { type: String, enum: ['teacher'], default: 'teacher' },
    authorName: { type: String, default: '' },
    status: {
      type: String,
      enum: ['draft', 'scheduled', 'published', 'archived'],
      default: 'draft',
      index: true,
    },
    publishAt: { type: Date, default: null, index: true },
    expiresAt: { type: Date, default: null, index: true },
    pinned: { type: Boolean, default: false, index: true },
    pinOrder: { type: Number, default: 0 },
    commentsEnabled: { type: Boolean, default: true },
    reactionsEnabled: { type: Boolean, default: true },
    audience: { type: audienceSchema, default: () => ({ mode: 'everyone' }) },
    media: [mediaSchema],
    links: [linkSchema],
    event: { type: eventSchema, default: null },
    pollId: { type: mongoose.Schema.Types.ObjectId, ref: 'Poll', default: null },
    showAsQuoteOfDay: { type: Boolean, default: false },
    quoteDate: { type: Date, default: null },
    stats: { type: statsSchema, default: () => ({}) },
  },
  { timestamps: true }
);

newsPostSchema.plugin(softDeletePlugin);
newsPostSchema.index({ status: 1, publishAt: -1, pinned: -1 });
newsPostSchema.index({ 'audience.mode': 1, status: 1 });

module.exports = mongoose.model('NewsPost', newsPostSchema);
module.exports.POST_TYPES = POST_TYPES;
