const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { generateId } = require('../utils/idGenerator');

const studentSchema = new mongoose.Schema(
  {
    studentId: { type: String, unique: true },
    name: { type: String, required: true, trim: true },
    email: { type: String, lowercase: true, trim: true },
    password: { type: String, required: true, select: false },
    phone: { type: String, trim: true },
    parentName: { type: String, trim: true },
    parentPhone: { type: String, trim: true },
    /** Monthly total fee (sum of subjectFees). Used when per-subject amounts are empty. */
    coursePrice: { type: Number, default: 0, min: 0 },
    subjectFees: [
      {
        subject: { type: String, trim: true },
        amount: { type: Number, min: 0, default: 0 },
      },
    ],
    dateOfBirth: { type: Date },
    gender: { type: String, enum: ['male', 'female', 'other', ''], default: '' },
    bloodGroup: { type: String, trim: true, default: '' },
    address: { type: String, trim: true, default: '' },
    medicalConditions: { type: String, trim: true, default: '' },
    status: { type: String, enum: ['active', 'inactive', 'graduated'], default: 'active' },
    examEligibility: { type: Boolean, default: true },
    /** Founder-gated premium IELTS Preparation module under English. */
    ieltsAccess: { type: Boolean, default: false },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch' },
    profileImage: { type: String },
    fcmTokens: [{ type: String }],
  },
  { timestamps: true }
);

studentSchema.index({ email: 1, branchId: 1 });
studentSchema.index({ branchId: 1, status: 1 });

studentSchema.pre('save', async function hashPassword(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

studentSchema.pre('save', function assignStudentId(next) {
  if (!this.studentId) {
    this.studentId = generateId('STU');
  }
  next();
});

studentSchema.post('save', async function removeFromGroupsOnDeactivate(doc) {
  if (doc.status !== 'inactive') return;
  const ClassSchedule = require('./ClassSchedule');
  const ExamGroup = require('./ExamGroup');
  await ClassSchedule.updateMany(
    { enrolledStudents: doc._id },
    { $pull: { enrolledStudents: doc._id } }
  );
  await ExamGroup.updateMany({ students: doc._id }, { $pull: { students: doc._id } });
});

studentSchema.methods.matchPassword = async function matchPassword(candidate) {
  return bcrypt.compare(candidate, this.password);
};

studentSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    studentId: this.studentId,
    name: this.name,
    email: this.email,
    phone: this.phone || '',
    parentName: this.parentName,
    parentPhone: this.parentPhone,
    coursePrice: Number(this.coursePrice || 0),
    subjectFees: (this.subjectFees || []).map((f) => ({
      subject: f.subject || '',
      amount: Number(f.amount || 0),
    })),
    subjects: (this.subjectFees || []).map((f) => f.subject).filter(Boolean),
    dateOfBirth: this.dateOfBirth || null,
    gender: this.gender || '',
    bloodGroup: this.bloodGroup || '',
    address: this.address || '',
    medicalConditions: this.medicalConditions || '',
    status: this.status,
    examEligibility: this.examEligibility,
    ieltsAccess: this.ieltsAccess === true,
    branchId: this.branchId,
    profileImage: this.profileImage,
    userType: 'student',
  };
};

module.exports = mongoose.model('Student', studentSchema);
