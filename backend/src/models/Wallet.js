const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema(
  {
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true, unique: true, index: true },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', index: true },
    balanceTyiyn: { type: Number, default: 0, min: 0 },
    isLocked: { type: Boolean, default: false },
    graceBalanceTyiyn: { type: Number, default: 0, min: 0 },
  },
  { timestamps: true }
);

walletSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    studentId: this.studentId,
    branchId: this.branchId,
    balanceTyiyn: this.balanceTyiyn,
    balanceSom: this.balanceTyiyn / 100,
    isLocked: this.isLocked,
    graceBalanceTyiyn: this.graceBalanceTyiyn,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('Wallet', walletSchema);
