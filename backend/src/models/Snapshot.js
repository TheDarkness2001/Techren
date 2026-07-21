const mongoose = require('mongoose');

const snapshotSchema = new mongoose.Schema(
  {
    collectionName: { type: String, required: true, index: true },
    documentId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    version: { type: Number, required: true, default: 1 },
    snapshot: { type: mongoose.Schema.Types.Mixed, required: true },
    changedBy: { type: String, default: '' },
    changeType: { type: String, enum: ['create', 'update', 'delete'], default: 'update' },
  },
  { timestamps: true }
);

snapshotSchema.index({ collectionName: 1, documentId: 1, version: -1 });

module.exports = mongoose.model('Snapshot', snapshotSchema);
