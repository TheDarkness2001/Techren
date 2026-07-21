const Language = require('../models/Language');
const Level = require('../models/Level');

const formatLanguage = (doc) => ({
  id: doc._id,
  name: doc.name,
  moduleType: doc.moduleType,
});

const formatLevel = (doc) => ({
  id: doc._id,
  name: doc.name,
  languageId: doc.languageId,
  classesCount: doc.classesCount,
  wordsPerClass: doc.wordsPerClass,
  examTimeLimit: doc.examTimeLimit,
  minPassScore: doc.minPassScore,
  practiceUnlockedFor: doc.practiceUnlockedFor || [],
  moduleType: doc.moduleType,
});

const listLanguages = async (moduleType = 'words') => {
  const items = await Language.find({ moduleType }).sort({ name: 1 });
  return items.map(formatLanguage);
};

const createLanguage = async (data) => {
  const item = await Language.create({
    name: data.name.trim(),
    moduleType: data.moduleType || 'words',
  });
  return formatLanguage(item);
};

const updateLanguage = async (id, data) => {
  const item = await Language.findByIdAndUpdate(id, { name: data.name?.trim() }, { new: true, runValidators: true });
  if (!item) throw Object.assign(new Error('Language not found'), { statusCode: 404, code: 'NOT_FOUND' });
  return formatLanguage(item);
};

const removeLanguage = async (id) => {
  const item = await Language.findByIdAndDelete(id);
  if (!item) throw Object.assign(new Error('Language not found'), { statusCode: 404, code: 'NOT_FOUND' });
  return formatLanguage(item);
};

const listLevels = async ({ languageId, moduleType = 'words' }) => {
  const filter = { moduleType };
  if (languageId) filter.languageId = languageId;
  const items = await Level.find(filter).sort({ name: 1 });
  return items.map(formatLevel);
};

const createLevel = async (data) => {
  const item = await Level.create({
    name: data.name.trim(),
    languageId: data.languageId,
    classesCount: data.classesCount,
    wordsPerClass: data.wordsPerClass,
    examTimeLimit: data.examTimeLimit,
    minPassScore: data.minPassScore,
    practiceUnlockedFor: data.practiceUnlockedFor || [],
    moduleType: data.moduleType || 'words',
  });
  return formatLevel(item);
};

const updateLevel = async (id, data) => {
  const item = await Level.findByIdAndUpdate(id, data, { new: true, runValidators: true });
  if (!item) throw Object.assign(new Error('Level not found'), { statusCode: 404, code: 'NOT_FOUND' });
  return formatLevel(item);
};

const removeLevel = async (id) => {
  const item = await Level.findByIdAndDelete(id);
  if (!item) throw Object.assign(new Error('Level not found'), { statusCode: 404, code: 'NOT_FOUND' });
  return formatLevel(item);
};

const togglePracticeUnlock = async (levelId, groupId, unlock) => {
  const level = await Level.findById(levelId);
  if (!level) throw Object.assign(new Error('Level not found'), { statusCode: 404, code: 'NOT_FOUND' });
  const ids = (level.practiceUnlockedFor || []).map(String);
  if (unlock && !ids.includes(String(groupId))) {
    level.practiceUnlockedFor.push(groupId);
  } else if (!unlock) {
    level.practiceUnlockedFor = level.practiceUnlockedFor.filter((g) => String(g) !== String(groupId));
  }
  await level.save();
  return formatLevel(level);
};

module.exports = {
  listLanguages,
  createLanguage,
  updateLanguage,
  removeLanguage,
  listLevels,
  createLevel,
  updateLevel,
  removeLevel,
  togglePracticeUnlock,
  formatLevel,
};
