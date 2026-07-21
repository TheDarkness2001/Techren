const mongoose = require('mongoose');

const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const classScheduleSchema = new mongoose.Schema(
  {
    className: { type: String, required: true, trim: true },
    // Canonical: Subject ObjectId. Legacy string labels may still exist in older rows.
    subject: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject' },
    subjectGroup: { type: mongoose.Schema.Types.ObjectId, ref: 'ExamGroup' },
    enrolledStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }],
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
    scheduledDays: [{ type: String, enum: DAYS }],
    startTime: { type: String, required: true },
    endTime: { type: String, required: true },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true },
  },
  { timestamps: true }
);

classScheduleSchema.index({ branchId: 1, teacher: 1 });
classScheduleSchema.index({ enrolledStudents: 1 });
classScheduleSchema.index({ subjectGroup: 1 });
classScheduleSchema.index({ subject: 1 });

module.exports = mongoose.model('ClassSchedule', classScheduleSchema);
module.exports.DAYS = DAYS;
