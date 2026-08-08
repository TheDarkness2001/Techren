const mongoose = require('mongoose');

const attachmentSchema = new mongoose.Schema(
  {
    kind: { type: String, enum: ['image', 'file', 'audio', 'video', 'other'], default: 'file' },
    url: { type: String, required: true },
    name: { type: String, default: '' },
    mime: { type: String, default: '' },
    size: { type: Number, default: 0 },
    durationSec: { type: Number, default: 0 },
  },
  { _id: false }
);

const reactionSchema = new mongoose.Schema(
  {
    emoji: { type: String, required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, required: true },
    userType: { type: String, enum: ['teacher', 'student', 'parent'], required: true },
  },
  { _id: false }
);

const mentionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true },
    userType: { type: String, enum: ['teacher', 'student', 'parent'], required: true },
    name: { type: String, default: '' },
  },
  { _id: false }
);

const starSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true },
    userType: { type: String, enum: ['teacher', 'student', 'parent'], required: true },
  },
  { _id: false }
);

const messageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      required: true,
      index: true,
    },
    senderId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    senderType: { type: String, enum: ['teacher', 'student', 'parent'], required: true },
    body: { type: String, default: '' },
    attachments: { type: [attachmentSchema], default: [] },
    replyToId: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
    forwardFromId: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
    forwardFromConversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Conversation',
      default: null,
    },
    reactions: { type: [reactionSchema], default: [] },
    mentions: { type: [mentionSchema], default: [] },
    starredBy: { type: [starSchema], default: [] },
    messageType: {
      type: String,
      enum: ['text', 'poll', 'call', 'system'],
      default: 'text',
    },
    pollId: { type: mongoose.Schema.Types.ObjectId, ref: 'Poll', default: null },
    scheduledAt: { type: Date, default: null, index: true },
    callPayload: {
      action: { type: String, enum: ['invite', 'accept', 'decline', 'end'], default: null },
      roomId: { type: String, default: '' },
      media: { type: String, enum: ['audio', 'video'], default: 'audio' },
    },
    status: {
      type: String,
      enum: ['scheduled', 'sent', 'delivered', 'seen', 'edited', 'deleted'],
      default: 'sent',
    },
    editedAt: { type: Date, default: null },
    deletedAt: { type: Date, default: null },
    clientId: { type: String, default: null },
    moderationNote: { type: String, default: '' },
  },
  { timestamps: true }
);

messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ conversationId: 1, clientId: 1 }, { sparse: true });
messageSchema.index({ status: 1, scheduledAt: 1 });
messageSchema.index({ body: 'text' });

module.exports = mongoose.model('Message', messageSchema);
