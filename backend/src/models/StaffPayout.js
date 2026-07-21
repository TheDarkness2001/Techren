const mongoose = require('mongoose');

const staffPayoutSchema = new mongoose.Schema(
  {
    payoutRef: { type: String, unique: true, required: true },
    staffId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true, index: true },
    earningIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'StaffEarning' }],
    amount: { type: Number, required: true, min: 0 },
    method: {
      type: String,
      enum: ['cash', 'bank-transfer', 'uzcard', 'humo', 'card', 'check'],
      required: true,
    },
    status: { type: String, enum: ['pending', 'completed', 'cancelled'], default: 'pending', index: true },
    bankDetails: {
      accountNumber: String,
      bankName: String,
      accountHolder: String,
    },
    referenceNumber: { type: String, default: '' },
    approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
    completedAt: { type: Date, default: null },
    cancelledAt: { type: Date, default: null },
    cancellationReason: { type: String, default: '' },
    notes: { type: String, default: '' },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', index: true },
  },
  { timestamps: true }
);

staffPayoutSchema.pre('validate', function assignPayoutRef(next) {
  if (this.isNew && !this.payoutRef) {
    this.payoutRef = `PAYOUT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
  }
  next();
});

module.exports = mongoose.model('StaffPayout', staffPayoutSchema, 'salarypayouts');
