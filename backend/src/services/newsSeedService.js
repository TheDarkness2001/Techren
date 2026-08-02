const NewsCategory = require('../models/NewsCategory');

const DEFAULT_CATEGORIES = [
  'News',
  'Motivation',
  'Events',
  'Important',
  'Scholarships',
  'IELTS',
  'Programming',
  'English',
  'Russian',
  'Technology',
  'Holiday',
  'Contest',
];

const slugify = (name) =>
  String(name)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');

const seedNewsCategories = async () => {
  for (let i = 0; i < DEFAULT_CATEGORIES.length; i += 1) {
    const name = DEFAULT_CATEGORIES[i];
    const slug = slugify(name);
    const existing = await NewsCategory.findOne({ slug }).setOptions({ includeDeleted: true });
    if (existing) {
      if (existing.isDeleted) {
        existing.isDeleted = false;
        existing.deletedAt = null;
        existing.active = true;
        existing.order = i;
        existing.name = name;
        await existing.save();
      }
      continue;
    }
    await NewsCategory.create({ name, slug, order: i, active: true });
  }
};

module.exports = { seedNewsCategories, DEFAULT_CATEGORIES };
