const mongoose = require('mongoose');

const CATEGORIES = ['teacher-payment', 'rent', 'electricity', 'repair', 'other'];

const branchExpenseSchema = new mongoose.Schema(
  {
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true, index: true },
    category: { type: String, enum: CATEGORIES, required: true },
    amount: { type: Number, required: true, min: 0 },
    month: { type: Number, required: true, min: 1, max: 12 },
    year: { type: Number, required: true },
    notes: { type: String, trim: true, default: '' },
    teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
    teacherName: { type: String, trim: true, default: '' },
    recordedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
  },
  { timestamps: true }
);

branchExpenseSchema.index({ branchId: 1, month: 1, year: 1, category: 1 });

const BranchExpense = mongoose.model('BranchExpense', branchExpenseSchema);
BranchExpense.CATEGORIES = CATEGORIES;
module.exports = BranchExpense;
