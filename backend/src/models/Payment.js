const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
    amount: { type: Number, required: true, min: 0 },
    paymentType: {
      type: String,
      enum: ['tuition-fee', 'exam-fee', 'transport-fee', 'library-fee', 'other'],
      required: true,
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'card', 'bank-transfer', 'online'],
      default: 'cash',
    },
    status: {
      type: String,
      enum: ['paid', 'pending', 'partial', 'overdue'],
      default: 'pending',
    },
    subject: { type: String, required: true, trim: true },
    dueDate: { type: Date, required: true },
    paidDate: { type: Date },
    receiptNumber: { type: String, unique: true, sparse: true },
    academicYear: { type: String, required: true },
    term: {
      type: String,
      enum: ['1st-term', '2nd-term', '3rd-term', 'annual'],
      required: true,
    },
    notes: { type: String, default: '' },
    recordedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
    month: { type: Number, required: true, min: 1, max: 12 },
    year: { type: Number, required: true },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', index: true },
  },
  { timestamps: true }
);

paymentSchema.index({ student: 1, subject: 1, month: 1, year: 1 });
paymentSchema.index({ status: 1 });
paymentSchema.index({ paidDate: 1 });

module.exports = mongoose.model('Payment', paymentSchema);
