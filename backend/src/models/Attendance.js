const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema(
  {
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', required: true },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch' },
    date: { type: String, required: true },
    checkInAt: { type: Date },
    checkOutAt: { type: Date },
    checkInPhoto: { type: String },
    checkOutPhoto: { type: String },
    gps: {
      latitude: Number,
      longitude: Number,
    },
    status: {
      type: String,
      enum: ['checked_in', 'checked_out', 'pending', 'approved', 'rejected'],
      default: 'checked_in',
    },
    dailyStatus: {
      type: String,
      enum: ['present', 'absent', 'late'],
    },
    notes: { type: String },
  },
  { timestamps: true }
);

attendanceSchema.index({ teacher: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
