const mongoose = require('mongoose');

const participantSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true },
    userType: { type: String, enum: ['teacher', 'student', 'parent'], required: true },
    role: { type: String, enum: ['member', 'admin', 'owner'], default: 'member' },
    lastReadAt: { type: Date, default: null },
    muted: { type: Boolean, default: false },
    pinned: { type: Boolean, default: false },
    leftAt: { type: Date, default: null },
  },
  { _id: false }
);

const conversationSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['private', 'group', 'subject', 'broadcast', 'support'],
      required: true,
      index: true,
    },
    title: { type: String, default: '', trim: true },
    description: { type: String, default: '' },
    avatarUrl: { type: String, default: null },
    participants: { type: [participantSchema], default: [] },
    examGroupId: { type: mongoose.Schema.Types.ObjectId, ref: 'ExamGroup', default: null, index: true },
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', default: null, index: true },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', default: null, index: true },
    allowReplies: { type: Boolean, default: true },
    archived: { type: Boolean, default: false, index: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, default: null },
    createdByType: { type: String, enum: ['teacher', 'student', 'parent', null], default: null },
    lastMessageAt: { type: Date, default: null, index: true },
    lastMessagePreview: { type: String, default: '' },
    pinnedMessageId: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
    /** For private DMs: sorted "teacher:id|student:id" (or parent) key for find-or-create.
     *  Must be omitted on non-private chats — storing null collides on the unique sparse index. */
    privateKey: { type: String, sparse: true, unique: true },
  },
  { timestamps: true }
);

conversationSchema.index({ 'participants.userId': 1, 'participants.userType': 1, lastMessageAt: -1 });
conversationSchema.index({ type: 1, examGroupId: 1 });

module.exports = mongoose.model('Conversation', conversationSchema);
