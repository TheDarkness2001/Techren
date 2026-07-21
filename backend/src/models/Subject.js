const mongoose = require('mongoose');

const moduleSchema = new mongoose.Schema(
  {
    key: { type: String, required: true, trim: true },
    label: { type: String, required: true, trim: true },
    category: {
      type: String,
      enum: ['learning', 'assessment', 'management', 'statistics'],
      default: 'learning',
    },
    icon: { type: String, default: 'menu_book' },
    audience: {
      type: String,
      enum: ['all', 'staff', 'student'],
      default: 'all',
    },
    enabled: { type: Boolean, default: true },
  },
  { _id: false }
);

const subjectSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    code: { type: String, trim: true },
    pricePerClass: { type: Number, default: 0 },
    branchId: { type: mongoose.Schema.Types.ObjectId, ref: 'Branch', required: true },
    icon: { type: String, trim: true },
    color: { type: String, trim: true },
    description: { type: String, trim: true, default: '' },
    modules: { type: [moduleSchema], default: [] },
  },
  { timestamps: true }
);

subjectSchema.index({ name: 1, branchId: 1 }, { unique: true });
subjectSchema.index({ branchId: 1 });

module.exports = mongoose.model('Subject', subjectSchema);
