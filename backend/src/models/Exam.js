const mongoose = require('mongoose');

const resultSchema = new mongoose.Schema(
  {
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
    marksObtained: { type: Number, default: 0 },
    grade: { type: String, default: '' },
    remarks: { type: String, default: '' },
    enrollmentStatus: {
      type: String,
      enum: ['enrolled', 'allowed', 'denied', 'attended', 'absent'],
      default: 'enrolled',
    },
  },
  { _id: false }
);

const examSchema = new mongoose.Schema(
  {
    examName: { type: String, required: true, trim: true },
    subject: { type: String, required: true, trim: true },
    class: { type: String, required: true, trim: true },
    scheduleId: { type: mongoose.Schema.Types.ObjectId, ref: 'ClassSchedule' },
    subjectGroup: { type: mongoose.Schema.Types.ObjectId, ref: 'ExamGroup' },
    examDate: { type: Date, required: true },
    startTime: { type: String, required: true },
    duration: { type: Number, required: true },
    totalMarks: { type: Number, required: true },
    passingMarks: { type: Number, required: true },
    examType: {
      type: String,
      enum: ['mid-term', 'final', 'quiz', 'practical', 'assignment'],
      default: 'mid-term',
    },
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
    status: {
      type: String,
      enum: ['scheduled', 'ongoing', 'completed', 'cancelled', 'archived'],
      default: 'scheduled',
    },
    results: [resultSchema],
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', index: true },
  },
  { timestamps: true }
);

examSchema.index({ branchId: 1, examDate: -1 });
examSchema.index({ scheduleId: 1 });
examSchema.index({ subjectGroup: 1 });
examSchema.index({ 'results.student': 1 });

module.exports = mongoose.model('Exam', examSchema);
