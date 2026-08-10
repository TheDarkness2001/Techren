const mongoose = require('mongoose');
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
  practiceUnlockedFor: (doc.practiceUnlockedFor || []).map((g) => String(g._id || g)),
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

const toObjectId = (id) => {
  const raw = String(id);
  if (!mongoose.Types.ObjectId.isValid(raw)) {
    throw Object.assign(new Error('Invalid group id'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }
  return new mongoose.Types.ObjectId(raw);
};

const applyGroupUnlock = (list, groupId, unlock) => {
  const gid = String(groupId);
  const current = (list || []).map((g) => String(g._id || g));
  if (unlock) {
    if (current.includes(gid)) return list || [];
    return [...(list || []), toObjectId(gid)];
  }
  return (list || []).filter((g) => String(g._id || g) !== gid);
};

const lessonsForLevel = async (level) => {
  const filter = { levelId: level._id };
  if (level.moduleType === 'words' || level.moduleType === 'sentences') {
    filter.type = level.moduleType;
  }
  return Lesson.find(filter).sort({ order: 1 });
};

const togglePracticeUnlock = async (levelId, groupId, unlock) => {
  const level = await Level.findById(levelId);
  if (!level) throw Object.assign(new Error('Level not found'), { statusCode: 404, code: 'NOT_FOUND' });
  level.practiceUnlockedFor = applyGroupUnlock(level.practiceUnlockedFor, groupId, unlock);
  await level.save();

  // Locking practice must also lock every class under that level (no half-open Blackhole).
  if (!unlock) {
    const lessons = await lessonsForLevel(level);
    for (const lesson of lessons) {
      const next = applyGroupUnlock(lesson.examUnlockedFor, groupId, false);
      const before = (lesson.examUnlockedFor || []).map((g) => String(g._id || g));
      const after = next.map((g) => String(g._id || g));
      const changed =
        before.length !== after.length || before.some((id) => !after.includes(id));
      if (changed) {
        lesson.examUnlockedFor = next;
        await lesson.save();
      }
    }
  }

  return formatLevel(level);
};

/**
 * Unlock / lock one level's practice and every lesson exam under it for a group.
 */
const bulkUnlockLevel = async ({ levelId, groupId, unlock }) => {
  if (!levelId || !groupId) {
    throw Object.assign(new Error('levelId and groupId are required'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }

  const level = await Level.findById(levelId);
  if (!level) throw Object.assign(new Error('Level not found'), { statusCode: 404, code: 'NOT_FOUND' });

  level.practiceUnlockedFor = applyGroupUnlock(level.practiceUnlockedFor, groupId, unlock);
  await level.save();

  const lessons = await lessonsForLevel(level);
  let lessonsUpdated = 0;
  for (const lesson of lessons) {
    const before = (lesson.examUnlockedFor || []).map((g) => String(g._id || g));
    const next = applyGroupUnlock(lesson.examUnlockedFor, groupId, unlock);
    const after = next.map((g) => String(g._id || g));
    const changed =
      before.length !== after.length || before.some((id) => !after.includes(id));
    if (changed) {
      lesson.examUnlockedFor = next;
      await lesson.save();
      lessonsUpdated += 1;
    }
  }

  return {
    levelId: String(level._id),
    groupId: String(groupId),
    unlock: !!unlock,
    practiceUpdated: true,
    lessonsTotal: lessons.length,
    lessonsUpdated,
    level: formatLevel(level),
  };
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
    const before = (level.practiceUnlockedFor || []).map((g) => String(g._id || g));
    const next = applyGroupUnlock(level.practiceUnlockedFor, groupId, unlock);
    const after = next.map((g) => String(g._id || g));
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
    const lessons = await Lesson.find({
      levelId: { $in: levelIds },
      ...(moduleType === 'words' || moduleType === 'sentences' ? { type: moduleType } : {}),
    });
    for (const lesson of lessons) {
      const before = (lesson.examUnlockedFor || []).map((g) => String(g._id || g));
      const next = applyGroupUnlock(lesson.examUnlockedFor, groupId, unlock);
      const after = next.map((g) => String(g._id || g));
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
  bulkUnlockLevel,
  bulkUnlockForGroup,
  formatLevel,
};
