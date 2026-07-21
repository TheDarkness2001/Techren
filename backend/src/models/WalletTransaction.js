const mongoose = require('mongoose');

const walletTransactionSchema = new mongoose.Schema(
  {
    walletId: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet', required: true, index: true },
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    type: {
      type: String,
      enum: ['topup', 'deduction', 'penalty', 'refund', 'adjustment'],
      required: true,
    },
    amountTyiyn: { type: Number, required: true, min: 1 },
    balanceAfterTyiyn: { type: Number, required: true, min: 0 },
    description: { type: String, default: '' },
    referenceId: { type: String, default: '' },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

walletTransactionSchema.index({ walletId: 1, createdAt: -1 });

walletTransactionSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    walletId: this.walletId,
    studentId: this.studentId,
    type: this.type,
    amountTyiyn: this.amountTyiyn,
    amountSom: this.amountTyiyn / 100,
    balanceAfterTyiyn: this.balanceAfterTyiyn,
    balanceAfterSom: this.balanceAfterTyiyn / 100,
    description: this.description,
    referenceId: this.referenceId,
    createdBy: this.createdBy,
    createdAt: this.createdAt,
  };
};

module.exports = mongoose.model('WalletTransaction', walletTransactionSchema);
