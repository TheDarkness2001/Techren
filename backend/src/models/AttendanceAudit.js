const mongoose = require('mongoose');

const attendanceAuditSchema = new mongoose.Schema(
  {
    attendanceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Attendance' },
    action: { type: String, enum: ['approve', 'reject', 'review'], required: true },
    performedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher' },
    reason: { type: String },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch' },
  },
  { timestamps: true }
);

attendanceAuditSchema.index({ branchId: 1, createdAt: -1 });

module.exports = mongoose.model('AttendanceAudit', attendanceAuditSchema);
