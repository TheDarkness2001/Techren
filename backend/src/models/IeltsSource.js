const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const TOPICS = [
  'Science',
  'Business',
  'Education',
  'Environment',
  'Technology',
  'History',
  'Travel',
  'Medicine',
  'Culture',
  'Nature',
  'Psychology',
  'Economics',
  'Engineering',
  'General',
  'Custom',
];

const DIFFICULTIES = ['Easy', 'Medium', 'Hard', 'IELTS 5', 'IELTS 6', 'IELTS 7', 'IELTS 8', 'IELTS 9'];

const ieltsSourceSchema = new mongoose.Schema(
  {
    subjectId: { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', index: true },
    title: { type: String, required: true, trim: true },
    author: { type: String, default: '', trim: true },
    publisher: { type: String, default: '', trim: true },
    publication: { type: String, default: '', trim: true },
    originalUrl: { type: String, default: '', trim: true },
    license: { type: String, default: '', trim: true },
    copyrightStatus: {
      type: String,
      enum: ['unknown', 'original', 'licensed', 'public_domain', 'fair_use'],
      default: 'unknown',
    },
    difficulty: { type: String, enum: DIFFICULTIES, default: 'Medium' },
    topic: { type: String, default: 'General' },
    cefrLevel: { type: String, default: '', trim: true },
    wordCount: { type: Number, default: 0 },
    durationSeconds: { type: Number, default: 0 },
    language: { type: String, default: 'en' },
    country: { type: String, default: '' },
    kind: { type: String, enum: ['listening', 'reading', 'mixed', 'other'], default: 'other' },
    tags: [{ type: String }],
    notes: { type: String, default: '' },
    status: { type: String, enum: ['draft', 'active', 'archived'], default: 'active', index: true },
    version: { type: Number, default: 1 },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Teacher', default: null },
  },
  { timestamps: true }
);

ieltsSourceSchema.plugin(softDeletePlugin);
ieltsSourceSchema.index({ subjectId: 1, topic: 1, status: 1 });
ieltsSourceSchema.index({ title: 'text', author: 'text', notes: 'text' });

ieltsSourceSchema.methods.toPublicJSON = function toPublicJSON() {
  return {
    id: this._id,
    subjectId: this.subjectId,
    title: this.title,
    author: this.author,
    publisher: this.publisher,
    publication: this.publication,
    originalUrl: this.originalUrl,
    license: this.license,
    copyrightStatus: this.copyrightStatus,
    difficulty: this.difficulty,
    topic: this.topic,
    cefrLevel: this.cefrLevel,
    wordCount: this.wordCount,
    durationSeconds: this.durationSeconds,
    language: this.language,
    country: this.country,
    kind: this.kind,
    tags: this.tags || [],
    notes: this.notes,
    status: this.status,
    version: this.version,
    createdBy: this.createdBy,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('IeltsSource', ieltsSourceSchema);
module.exports.TOPICS = TOPICS;
module.exports.DIFFICULTIES = DIFFICULTIES;
