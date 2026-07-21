const mongoose = require('mongoose');

const studentAttendanceSchema = new mongoose.Schema(
  {
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
    classSchedule: { type: mongoose.Schema.Types.ObjectId, ref: 'ClassSchedule', required: true },
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
    date: { type: String, required: true },
    status: {
      type: String,
      enum: ['present', 'absent', 'late', 'excused'],
      default: 'present',
    },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch' },
    markedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
  },
  { timestamps: true }
);

studentAttendanceSchema.index({ student: 1, classSchedule: 1, date: 1 }, { unique: true });
studentAttendanceSchema.index({ classSchedule: 1, date: 1 });
studentAttendanceSchema.index({ student: 1, date: -1 });

module.exports = mongoose.model('StudentAttendance', studentAttendanceSchema);
