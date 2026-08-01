const mongoose = require('mongoose');

/**
 * Immutable snapshot of a bank question. Publishing an exam freezes references to these.
 */
const versionSchema = new mongoose.Schema(
  {
    bankItemId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'IeltsQuestionBankItem',
      required: true,
      index: true,
    },
    version: { type: Number, required: true },
    payload: { type: mongoose.Schema.Types.Mixed, required: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', default: null },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

versionSchema.index({ bankItemId: 1, version: 1 }, { unique: true });

versionSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    bankItemId: this.bankItemId,
    version: this.version,
    payload: this.payload,
    createdBy: this.createdBy,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('IeltsQuestionVersion', versionSchema);
