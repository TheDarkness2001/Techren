const mongoose = require('mongoose');
const softDeletePlugin = require('../plugins/softDeletePlugin');

const newsCategorySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    slug: { type: String, required: true, trim: true, lowercase: true, unique: true },
    order: { type: Number, default: 0 },
    active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

newsCategorySchema.plugin(softDeletePlugin);

module.exports = mongoose.model('NewsCategory', newsCategorySchema);
