const Language = require('../models/Language');
const Level = require('../models/Level');
const Lesson = require('../models/Lesson');

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

const applyGroupUnlock = (list, groupId, unlock) => {
  const gid = String(groupId);
  const current = (list || []).map(String);
  if (unlock) {
    return current.includes(gid) ? list || [] : [...(list || []), groupId];
  }
  return (list || []).filter((g) => String(g) !== gid);
};

const togglePracticeUnlock = async (levelId, groupId, unlock) => {
  const level = await Level.findById(levelId);
  if (!level) throw Object.assign(new Error('Level not found'), { statusCode: 404, code: 'NOT_FOUND' });
  level.practiceUnlockedFor = applyGroupUnlock(level.practiceUnlockedFor, groupId, unlock);
  await level.save();
  return formatLevel(level);
};

/**
 * Unlock / lock every level (and optionally every lesson exam) under a language for one group.
 * Used by Words / Sentences / BBC Listening "Unlock all" on the Permissions screen.
 */
const bulkUnlockForGroup = async ({
  languageId,
  moduleType = 'words',
  groupId,
  unlock,
  includeExam = false,
}) => {
  if (!languageId || !groupId) {
    throw Object.assign(new Error('languageId and groupId are required'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }

  const levels = await Level.find({ languageId, moduleType });
  let levelsUpdated = 0;
  for (const level of levels) {
    const before = (level.practiceUnlockedFor || []).map(String);
    const next = applyGroupUnlock(level.practiceUnlockedFor, groupId, unlock);
    const after = next.map(String);
    const changed =
      before.length !== after.length || before.some((id) => !after.includes(id));
    if (changed) {
      level.practiceUnlockedFor = next;
      await level.save();
      levelsUpdated += 1;
    }
  }

  let lessonsUpdated = 0;
  if (includeExam && levels.length) {
    const levelIds = levels.map((l) => l._id);
    const lessons = await Lesson.find({ levelId: { $in: levelIds } });
    for (const lesson of lessons) {
      const before = (lesson.examUnlockedFor || []).map(String);
      const next = applyGroupUnlock(lesson.examUnlockedFor, groupId, unlock);
      const after = next.map(String);
      const changed =
        before.length !== after.length || before.some((id) => !after.includes(id));
      if (changed) {
        lesson.examUnlockedFor = next;
        await lesson.save();
        lessonsUpdated += 1;
      }
    }
  }

  return {
    languageId: String(languageId),
    moduleType,
    groupId: String(groupId),
    unlock: !!unlock,
    includeExam: !!includeExam,
    levelsTotal: levels.length,
    levelsUpdated,
    lessonsUpdated,
  };
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
  bulkUnlockForGroup,
  formatLevel,
};
