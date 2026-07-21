const mongoose = require('mongoose');

const staffAccountSchema = new mongoose.Schema(
  {
    staffId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true, unique: true },
    totalEarned: { type: Number, default: 0 },
    totalPaidOut: { type: Number, default: 0 },
    availableForPayout: { type: Number, default: 0 },
    pendingEarnings: { type: Number, default: 0 },
    approvedNotPaid: { type: Number, default: 0 },
    lastEarningDate: { type: Date, default: null },
    lastPayoutDate: { type: Date, default: null },
    currency: { type: String, default: 'UZS' },
  },
  { timestamps: true }
);

staffAccountSchema.statics.getOrCreate = async function getOrCreate(staffId) {
  let account = await this.findOne({ staffId });
  if (!account) account = await this.create({ staffId });
  return account;
};

module.exports = mongoose.model('StaffAccount', staffAccountSchema);
