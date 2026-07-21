const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { generateId } = require('../utils/idGenerator');

const teacherSchema = new mongoose.Schema(
  {
    teacherId: { type: String, unique: true },
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true, select: false },
    phone: { type: String, trim: true },
    subject: [{ type: String }],
    role: {
      type: String,
      enum: ['founder', 'admin', 'teacher', 'sales', 'receptionist', 'manager'],
      default: 'teacher',
    },
    permissions: { type: mongoose.Schema.Types.Mixed, default: {} },
    perClassEarning: { type: Number, default: 0 },
    perClassEarnings: { type: Map, of: Number, default: {} },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch' },
    status: { type: String, enum: ['active', 'inactive', 'on-leave'], default: 'active' },
    profileImage: { type: String },
  },
  { timestamps: true }
);

teacherSchema.index({ branchId: 1, role: 1 });
teacherSchema.index({ branchId: 1, status: 1 });

teacherSchema.pre('save', async function hashPassword(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

teacherSchema.pre('save', function assignTeacherId(next) {
  if (!this.teacherId) {
    this.teacherId = generateId('TCH');
  }
  next();
});

teacherSchema.methods.matchPassword = async function matchPassword(candidate) {
  return bcrypt.compare(candidate, this.password);
};

teacherSchema.methods.toPublicJSON = function toPublicJSON() {
  const permissions = {};
  if (this.permissions) {
    if (this.permissions instanceof Map) {
      for (const [key, value] of this.permissions.entries()) {
        permissions[key] = value;
      }
    } else if (typeof this.permissions === 'object') {
      Object.assign(permissions, this.permissions);
    }
  }
  return {
    id: this._id,
    teacherId: this.teacherId,
    name: this.name,
    email: this.email,
    phone: this.phone,
    subject: this.subject,
    role: this.role,
    permissions,
    branchId: this.branchId,
    status: this.status,
    profileImage: this.profileImage,
    userType: 'teacher',
  };
};

module.exports = mongoose.model('Teacher', teacherSchema);
