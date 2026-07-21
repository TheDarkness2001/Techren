const mongoose = require('mongoose');

const recycleBinSchema = new mongoose.Schema(
  {
    collectionName: { type: String, required: true, index: true },
    documentId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    snapshot: { type: mongoose.Schema.Types.Mixed, required: true },
    label: { type: String, default: '' },
    cascadeGroupId: { type: String, index: true },
    deletedBy: { type: String, default: '' },
    deletedAt: { type: Date, default: Date.now, index: true },
    isImportant: { type: Boolean, default: false },
    restoredAt: { type: Date, default: null },
    purgedAt: { type: Date, default: null },
    moduleType: { type: String, default: '' },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', default: null, index: true },
  },
  { timestamps: true }
);

recycleBinSchema.index({ collectionName: 1, deletedAt: -1 });
recycleBinSchema.index({ purgedAt: 1, restoredAt: 1 });

module.exports = mongoose.model('RecycleBin', recycleBinSchema);
