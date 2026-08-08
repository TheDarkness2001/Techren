const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const parentSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    /** Memorable login id (preferred). Unique when set. */
    username: {
      type: String,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
      match: [/^[a-z0-9._-]{3,40}$/, 'Username must be 3–40 chars: letters, numbers, . _ -'],
    },
    /** Optional; kept for migration / contact. */
    email: {
      type: String,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
    },
    password: { type: String, required: true, select: false },
    phone: { type: String, trim: true },
    relation: {
      type: String,
      enum: ['mother', 'father', 'guardian'],
      default: 'guardian',
    },
    children: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Student' }],
    fcmTokens: [{ type: String }],
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  },
  { timestamps: true }
);

parentSchema.pre('save', async function hashPassword(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

parentSchema.methods.matchPassword = async function matchPassword(candidate) {
  return bcrypt.compare(candidate, this.password);
};

parentSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    name: this.name,
    username: this.username || null,
    email: this.email || null,
    phone: this.phone,
    relation: this.relation || 'guardian',
    children: (this.children || []).map((c) => (c?._id || c)?.toString()),
    status: this.status,
    userType: 'parent',
  };
};

parentSchema.methods.toStaffJSON = function toStaffJSON() {
  return {
    id: this._id,
    name: this.name,
    username: this.username || null,
    email: this.email || null,
    phone: this.phone || null,
    relation: this.relation || 'guardian',
    hasPassword: true,
    status: this.status,
  };
};

module.exports = mongoose.model('Parent', parentSchema);
