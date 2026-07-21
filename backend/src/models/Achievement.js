const mongoose = require('mongoose');

const achievementSchema = new mongoose.Schema(
  {
    code: { type: String, unique: true, required: true, trim: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    icon: { type: String, default: 'emoji_events' },
    category: { type: String, default: 'milestone' },
    criteria: { type: mongoose.Schema.Types.Mixed, required: true },
    xpReward: { type: Number, default: 0, min: 0 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Achievement', achievementSchema);
