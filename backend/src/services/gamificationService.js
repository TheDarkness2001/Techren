const StudentGamification = require('../models/StudentGamification');
const Achievement = require('../models/Achievement');
const StudentAchievement = require('../models/StudentAchievement');
const Student = require('../models/Student');
const { getFeatureFlag } = require('./settingsService');
const config = require('../config');
const { getTashkentParts } = require('../utils/classWindow');
const logger = require('../config/logger');

const LEVEL_STEP = 300;

const XP_REWARDS = {
  word_correct: 5,
  sentence_correct: 10,
  listening_passed: 25,
  listening_partial: 15,
  video_completed: 20,
};

const isEnabled = async () => {
  if (!config.features.gamificationEnabled) return false;
  return getFeatureFlag('gamificationEnabled') !== false;
};

const getLevelInfo = (totalXp) => {
  const level = Math.max(1, Math.floor(totalXp / LEVEL_STEP) + 1);
  const xpInLevel = totalXp % LEVEL_STEP;
  const xpToNextLevel = LEVEL_STEP - xpInLevel;
  return { level, xpInLevel, xpToNextLevel, levelCap: LEVEL_STEP };
};

const formatProfile = (doc, rank = null) => {
  const levelInfo = getLevelInfo(doc.totalXp);
  return {
    studentId: doc.studentId,
    totalXp: doc.totalXp,
    level: levelInfo.level,
    xpInLevel: levelInfo.xpInLevel,
    xpToNextLevel: levelInfo.xpToNextLevel,
    levelCap: levelInfo.levelCap,
    currentStreak: doc.currentStreak,
    longestStreak: doc.longestStreak,
    lastActivityDate: doc.lastActivityDate,
    moduleXp: doc.moduleXp || { words: 0, sentences: 0, listening: 0, video: 0 },
    rank,
  };
};

const getOrCreateProfile = async (studentId) => {
  let profile = await StudentGamification.findOne({ studentId });
  if (!profile) {
    profile = await StudentGamification.create({ studentId });
  }
  return profile;
};

const updateStreak = (profile, dateString) => {
  if (!profile.lastActivityDate) {
    profile.currentStreak = 1;
  } else if (profile.lastActivityDate === dateString) {
    // same day — no streak change
  } else {
    const last = new Date(`${profile.lastActivityDate}T12:00:00Z`);
    const today = new Date(`${dateString}T12:00:00Z`);
    const diffDays = Math.round((today - last) / (24 * 60 * 60 * 1000));
    if (diffDays === 1) {
      profile.currentStreak += 1;
    } else {
      profile.currentStreak = 1;
    }
  }
  profile.longestStreak = Math.max(profile.longestStreak, profile.currentStreak);
  profile.lastActivityDate = dateString;
};

const meetsCriteria = (profile, criteria) => {
  if (!criteria?.type) return false;
  switch (criteria.type) {
    case 'totalXp':
      return profile.totalXp >= (criteria.value || 0);
    case 'streak':
      return profile.currentStreak >= (criteria.value || 0) || profile.longestStreak >= (criteria.value || 0);
    case 'moduleXp': {
      const module = criteria.module || 'words';
      return (profile.moduleXp?.[module] || 0) >= (criteria.value || 0);
    }
    default:
      return false;
  }
};

const checkAchievements = async (studentId, profile) => {
  const achievements = await Achievement.find({ isActive: true });
  const unlocked = await StudentAchievement.find({ studentId }).select('achievementId');
  const unlockedIds = new Set(unlocked.map((u) => String(u.achievementId)));

  const newlyUnlocked = [];
  for (const achievement of achievements) {
    if (unlockedIds.has(String(achievement._id))) continue;
    if (!meetsCriteria(profile, achievement.criteria)) continue;

    await StudentAchievement.create({ studentId, achievementId: achievement._id });
    if (achievement.xpReward > 0) {
      profile.totalXp += achievement.xpReward;
      profile.level = getLevelInfo(profile.totalXp).level;
    }
    newlyUnlocked.push({
      code: achievement.code,
      title: achievement.title,
      xpReward: achievement.xpReward,
    });
  }

  if (newlyUnlocked.length) await profile.save();
  return newlyUnlocked;
};

const awardXp = async (studentId, { module, amount, reason }) => {
  if (!studentId || amount <= 0) return null;
  if (!(await isEnabled())) return null;

  try {
    const profile = await getOrCreateProfile(studentId);
    const parts = getTashkentParts();

    profile.totalXp += amount;
    if (module && profile.moduleXp[module] !== undefined) {
      profile.moduleXp[module] += amount;
    }
    profile.level = getLevelInfo(profile.totalXp).level;
    updateStreak(profile, parts.dateString);
    await profile.save();

    const achievements = await checkAchievements(studentId, profile);
    return { xpAwarded: amount, reason, module, achievements, profile: formatProfile(profile.toObject()) };
  } catch (error) {
    logger.warn(`awardXp failed: ${error.message}`);
    return null;
  }
};

const resolveStudentId = (req, queryStudentId) => {
  if (req.userType === 'student') return String(req.user._id);
  return queryStudentId || null;
};

const getProfile = async (req, query = {}) => {
  const studentId = resolveStudentId(req, query.studentId);
  if (!studentId) {
    throw Object.assign(new Error('studentId is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  if (req.userType === 'student' && String(studentId) !== String(req.user._id)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }

  const student = await Student.findById(studentId);
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const profile = await getOrCreateProfile(studentId);
  const higherRanked = await StudentGamification.countDocuments({ totalXp: { $gt: profile.totalXp } });
  return {
    ...formatProfile(profile.toObject(), higherRanked + 1),
    studentName: student.name,
    enabled: await isEnabled(),
  };
};

const getAchievements = async (req, query = {}) => {
  const studentId = resolveStudentId(req, query.studentId);
  if (!studentId) {
    throw Object.assign(new Error('studentId is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const [catalog, unlocked] = await Promise.all([
    Achievement.find({ isActive: true }).sort({ category: 1, xpReward: 1 }),
    StudentAchievement.find({ studentId }).populate('achievementId'),
  ]);

  const unlockedMap = new Map(
    unlocked.map((u) => [String(u.achievementId?._id || u.achievementId), u.unlockedAt])
  );

  return catalog.map((a) => ({
    id: a._id,
    code: a.code,
    title: a.title,
    description: a.description,
    icon: a.icon,
    category: a.category,
    xpReward: a.xpReward,
    unlocked: unlockedMap.has(String(a._id)),
    unlockedAt: unlockedMap.get(String(a._id)) || null,
  }));
};

const getLeaderboard = async (req, query = {}) => {
  const limit = Math.min(Number(query.limit) || 50, 50);
  const profiles = await StudentGamification.find({ totalXp: { $gt: 0 } })
    .sort({ totalXp: -1 })
    .limit(limit)
    .lean();

  const studentIds = profiles.map((p) => p.studentId);
  const students = await Student.find({ _id: { $in: studentIds } }).select('name studentId profileImage');
  const studentMap = new Map(students.map((s) => [String(s._id), s]));

  return profiles.map((p, index) => ({
    rank: index + 1,
    studentId: p.studentId,
    name: studentMap.get(String(p.studentId))?.name || 'Student',
    studentCode: studentMap.get(String(p.studentId))?.studentId || '',
    profileImage: studentMap.get(String(p.studentId))?.profileImage || null,
    totalXp: p.totalXp,
    level: getLevelInfo(p.totalXp).level,
    currentStreak: p.currentStreak,
  }));
};

const getRecommendations = async (req, query = {}) => {
  const studentId = resolveStudentId(req, query.studentId);
  if (!studentId) {
    throw Object.assign(new Error('studentId is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const profile = await getOrCreateProfile(studentId);
  const modules = ['words', 'sentences', 'listening', 'video'];
  const moduleXp = profile.moduleXp || {};

  const sorted = [...modules].sort((a, b) => (moduleXp[a] || 0) - (moduleXp[b] || 0));
  const weakest = sorted[0];
  const labels = {
    words: 'Vocabulary (Words)',
    sentences: 'Sentence practice',
    listening: 'Listening exercises',
    video: 'Video lessons',
  };

  return {
    recommendedModule: weakest,
    title: labels[weakest],
    reason: (moduleXp[weakest] || 0) === 0
      ? 'You have not earned XP in this module yet'
      : 'This is your lowest XP module — extra practice here will balance your progress',
    moduleXp,
  };
};

module.exports = {
  XP_REWARDS,
  isEnabled,
  awardXp,
  getProfile,
  getAchievements,
  getLeaderboard,
  getRecommendations,
  getOrCreateProfile,
  formatProfile,
};
