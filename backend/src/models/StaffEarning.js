const mongoose = require('mongoose');

const staffEarningSchema = new mongoose.Schema(
  {
    staffId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true, index: true },
    classScheduleId: { type: mongoose.Schema.Types.ObjectId, ref: 'ClassSchedule', default: null },
    classId: { type: mongoose.Schema.Types.ObjectId, ref: 'Class', default: null },
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', default: null },
    amount: { type: Number, required: true },
    earningType: {
      type: String,
      enum: ['per-class', 'hourly', 'commission', 'bonus', 'adjustment', 'penalty'],
      default: 'per-class',
      required: true,
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'paid', 'cancelled'],
      default: 'pending',
      index: true,
    },
    referenceDate: { type: Date, required: true, default: Date.now },
    description: { type: String, default: '', maxlength: 200 },
    reason: { type: String, default: '', maxlength: 500 },
    approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', default: null },
    approvedAt: { type: Date, default: null },
    payoutId: { type: mongoose.Schema.Types.ObjectId, ref: 'StaffPayout', default: null },
    paidAt: { type: Date, default: null },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', default: null },
    createdByType: { type: String, enum: ['system', 'admin', 'manager', 'founder', 'teacher'], default: 'system' },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', index: true },
  },
  { timestamps: true }
);

staffEarningSchema.index({ staffId: 1, status: 1 });
staffEarningSchema.index({ branchId: 1, referenceDate: -1 });

module.exports = mongoose.model('StaffEarning', staffEarningSchema, 'teacherearnings');
