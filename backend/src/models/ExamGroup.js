const mongoose = require('mongoose');

const examGroupSchema = new mongoose.Schema(
  {
    groupName: { type: String, required: true, trim: true },
    subject: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true },
    students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }],
    teachers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' }],
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true },
    linkedScheduleId: { type: mongoose.Schema.Types.ObjectId, ref: 'ClassSchedule' },
  },
  { timestamps: true }
);

examGroupSchema.index({ branchId: 1 });
examGroupSchema.index({ subject: 1, branchId: 1 });
examGroupSchema.index({ students: 1 });

module.exports = mongoose.model('ExamGroup', examGroupSchema);
