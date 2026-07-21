const mongoose = require('mongoose');

const feedbackSchema = new mongoose.Schema(
  {
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
    classSchedule: { type: mongoose.Schema.Types.ObjectId, ref: 'ClassSchedule', required: true },
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch' },
    date: { type: String, required: true },
    homework: { type: Number, min: 0, max: 100, default: 0 },
    behavior: { type: Number, min: 0, max: 100, default: 0 },
    participation: { type: Number, min: 0, max: 100, default: 0 },
    isExamDay: { type: Boolean, default: false },
    examPercentage: { type: Number, min: 0, max: 100 },
    parentComments: { type: String },
    notes: { type: String },
  },
  { timestamps: true }
);

feedbackSchema.index({ student: 1, classSchedule: 1, date: 1 }, { unique: true });
feedbackSchema.index({ classSchedule: 1, date: -1 });
feedbackSchema.index({ branchId: 1, date: -1 });

module.exports = mongoose.model('Feedback', feedbackSchema);
