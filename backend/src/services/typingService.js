const mongoose = require('mongoose');
const Subject = require('../models/Subject');
const Student = require('../models/Student');
const TypingContent = require('../models/TypingContent');
const TypingResult = require('../models/TypingResult');
const TypingStudentStats = require('../models/TypingStudentStats');
const { awardXp, XP_REWARDS, getOrCreateProfile, formatProfile, getLevelInfo } = require('./gamificationService');
const { ensureSubjectLearningFields, isItTypingSubject } = require('../utils/learningModules');

const ALLOWED_DURATIONS = new Set([15, 30, 60, 120, 300, 0]);
const WORD_TARGET = 80;

const bad = (message, statusCode = 400, code = 'BAD_REQUEST') =>
  Object.assign(new Error(message), { statusCode, code });

const subjectHasTyping = (subject) => {
  const fields = ensureSubjectLearningFields(subject);
  return (fields.modules || []).some((m) => m.key === 'typing' && m.enabled !== false);
};

const assertTypingSubject = async (subjectId) => {
  if (!mongoose.isValidObjectId(subjectId)) throw bad('Invalid subjectId');
  const subject = await Subject.findById(subjectId);
  if (!subject) throw bad('Subject not found', 404, 'NOT_FOUND');
  if (!isItTypingSubject(subject.name) || !subjectHasTyping(subject)) {
    throw bad('Typing Speed Challenge is only available for IT subjects', 403, 'FORBIDDEN');
  }
  return subject;
};

const resolveStudentId = (req, bodyStudentId) => {
  if (req.userType === 'student') return String(req.user._id);
  if (bodyStudentId) return String(bodyStudentId);
  return null;
};

const utcDateString = (date = new Date()) => date.toISOString().slice(0, 10);

const hashSeed = (text) => {
  let hash = 0;
  const s = String(text);
  for (let i = 0; i < s.length; i += 1) {
    hash = (hash << 5) - hash + s.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
};

const shuffleWithSeed = (items, seed) => {
  const arr = [...items];
  let s = seed || 1;
  for (let i = arr.length - 1; i > 0; i -= 1) {
    s = (s * 1664525 + 1013904223) >>> 0;
    const j = s % (i + 1);
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
};

const pickWords = (pools, count, seed) => {
  const flat = pools.flatMap((p) => p.words || []).filter(Boolean);
  if (!flat.length) return [];
  const shuffled = shuffleWithSeed(flat, seed);
  const out = [];
  while (out.length < count) {
    out.push(...shuffled);
  }
  return out.slice(0, count);
};

const buildPrompt = async ({ mode, difficulty, isDaily }) => {
  const day = utcDateString();
  const seed = hashSeed(`${day}:${mode}:${difficulty}:${isDaily ? 'daily' : 'practice'}`);

  if (mode === 'code') {
    const snippets = await TypingContent.find({ kind: 'code', published: true }).lean();
    if (!snippets.length) throw bad('No code snippets seeded yet', 404, 'NOT_FOUND');
    const pick = snippets[seed % snippets.length];
    return {
      contentId: String(pick._id),
      mode: 'code',
      difficulty: pick.difficulty || 'medium',
      language: pick.language || 'javascript',
      title: pick.title,
      text: pick.code || '',
      words: [],
    };
  }

  const kind = mode === 'programming' || isDaily ? 'programming' : 'english';
  const diff = isDaily ? 'medium' : difficulty;
  let pools = await TypingContent.find({ kind, difficulty: diff, published: true }).lean();
  if (!pools.length) {
    pools = await TypingContent.find({ kind, published: true }).lean();
  }
  if (!pools.length) throw bad(`No ${kind} word lists seeded yet`, 404, 'NOT_FOUND');

  const words = pickWords(pools, WORD_TARGET, seed);
  return {
    contentId: pools[0] ? String(pools[0]._id) : null,
    mode: kind,
    difficulty: diff,
    language: null,
    title: isDaily ? 'Daily Challenge' : pools[0].title,
    text: words.join(' '),
    words,
  };
};

const clamp = (n, min, max) => Math.max(min, Math.min(max, n));

const sanitizeMetrics = (body) => {
  const wpm = clamp(Number(body.wpm) || 0, 0, 400);
  const rawWpm = clamp(Number(body.rawWpm) || wpm, 0, 500);
  const accuracy = clamp(Number(body.accuracy) || 0, 0, 100);
  const correctChars = Math.max(0, Math.floor(Number(body.correctChars) || 0));
  const incorrectChars = Math.max(0, Math.floor(Number(body.incorrectChars) || 0));
  const totalChars = Math.max(0, Math.floor(Number(body.totalChars) || correctChars + incorrectChars));
  const mistakes = Math.max(0, Math.floor(Number(body.mistakes) || incorrectChars));
  const wordsTyped = Math.max(0, Math.floor(Number(body.wordsTyped) || 0));
  const correctWords = Math.max(0, Math.floor(Number(body.correctWords) || 0));
  const wrongWords = Math.max(0, Math.floor(Number(body.wrongWords) || 0));
  const elapsedSec = Math.max(0, Math.floor(Number(body.elapsedSec) || 0));
  return {
    wpm,
    rawWpm,
    accuracy,
    correctChars,
    incorrectChars,
    totalChars,
    mistakes,
    wordsTyped,
    correctWords,
    wrongWords,
    elapsedSec,
  };
};

const computeXp = ({ accuracy, wpm, bestWpm, isDaily }) => {
  let xp = XP_REWARDS.typing_complete || 10;
  const reasons = ['Complete test'];
  if (accuracy >= 95) {
    xp += XP_REWARDS.typing_accuracy_95 || 20;
    reasons.push('Accuracy ≥ 95%');
  }
  if (wpm > bestWpm && wpm > 0) {
    xp += XP_REWARDS.typing_new_record || 20;
    reasons.push('New WPM record');
  }
  if (isDaily) {
    xp += XP_REWARDS.typing_daily || 30;
    reasons.push('Daily challenge');
  }
  return { xp, reasons };
};

const getOrCreateStats = async (studentId, subjectId) => {
  let stats = await TypingStudentStats.findOne({ studentId, subjectId });
  if (!stats) {
    stats = await TypingStudentStats.create({ studentId, subjectId });
  }
  return stats;
};

const typingLevelFromXp = (totalXp) => {
  // Plan: L1=0, L2=100, L3=250, then +150, +200, +250... thresholds
  // Use: thresholds [0, 100, 250] then grow by 150 + 50*(n-3)
  let level = 1;
  let need = 0;
  let nextGap = 100;
  let xp = Math.max(0, totalXp || 0);
  while (xp >= need + nextGap) {
    need += nextGap;
    level += 1;
    if (level === 2) nextGap = 150; // to reach L3 at 250
    else if (level >= 3) nextGap = 150 + 50 * (level - 2);
  }
  const xpInLevel = xp - need;
  const xpToNextLevel = nextGap - xpInLevel;
  return { level, xpInLevel, xpToNextLevel, levelCap: nextGap };
};

const start = async (req, body = {}) => {
  const subjectId = body.subjectId || req.query.subjectId;
  await assertTypingSubject(subjectId);

  const mode = ['english', 'programming', 'code'].includes(body.mode) ? body.mode : 'programming';
  const difficulty = ['easy', 'medium', 'hard', 'expert'].includes(body.difficulty)
    ? body.difficulty
    : 'medium';
  const durationSec = ALLOWED_DURATIONS.has(Number(body.durationSec))
    ? Number(body.durationSec)
    : 60;
  const unlimited = durationSec === 0 || body.unlimited === true;
  const isDaily = body.isDaily === true;

  const prompt = await buildPrompt({
    mode: isDaily ? 'programming' : mode,
    difficulty: isDaily ? 'medium' : difficulty,
    isDaily,
  });

  return {
    session: {
      subjectId: String(subjectId),
      mode: isDaily ? 'programming' : mode,
      difficulty: isDaily ? 'medium' : difficulty,
      durationSec: isDaily ? 60 : unlimited ? 0 : durationSec,
      unlimited: isDaily ? false : unlimited,
      isDaily,
      startedAt: new Date().toISOString(),
    },
    prompt,
  };
};

const finish = async (req, body = {}) => {
  const subjectId = body.subjectId;
  await assertTypingSubject(subjectId);
  const studentId = resolveStudentId(req, body.studentId);

  const mode = ['english', 'programming', 'code'].includes(body.mode) ? body.mode : 'programming';
  const difficulty = ['easy', 'medium', 'hard', 'expert'].includes(body.difficulty)
    ? body.difficulty
    : 'medium';
  const durationSec = Number(body.durationSec) || 0;
  const unlimited = body.unlimited === true || durationSec === 0;
  const isDaily = body.isDaily === true;
  const metrics = sanitizeMetrics(body);

  // Staff preview practice — return result without persisting XP / leaderboard.
  if (!studentId) {
    const { xp, reasons } = computeXp({
      accuracy: metrics.accuracy,
      wpm: metrics.wpm,
      bestWpm: 0,
      isDaily: false,
    });
    return {
      result: {
        id: null,
        wpm: metrics.wpm,
        rawWpm: metrics.rawWpm,
        accuracy: metrics.accuracy,
        correctWords: metrics.correctWords,
        wrongWords: metrics.wrongWords,
        totalChars: metrics.totalChars,
        correctChars: metrics.correctChars,
        incorrectChars: metrics.incorrectChars,
        mistakes: metrics.mistakes,
        wordsTyped: metrics.wordsTyped,
        xpEarned: 0,
        xpReasons: ['Staff preview — results are not saved'],
        mode,
        difficulty,
        isDaily,
        improvementVsLast: 0,
        previousWpm: 0,
      },
      rank: null,
      level: 1,
      totalXp: 0,
      currentStreak: 0,
      achievements: [],
      stats: {
        bestWpm: metrics.wpm,
        averageWpm: metrics.wpm,
        averageAccuracy: metrics.accuracy,
        testsCompleted: 0,
      },
      staffPreview: true,
      previewXpWouldEarn: xp,
      previewXpReasons: reasons,
    };
  }

  const student = await Student.findById(studentId);
  if (!student) throw bad('Student not found', 404, 'NOT_FOUND');

  const stats = await getOrCreateStats(studentId, subjectId);
  const previousWpm = stats.lastWpm || 0;
  const { xp, reasons } = computeXp({
    accuracy: metrics.accuracy,
    wpm: metrics.wpm,
    bestWpm: stats.bestWpm || 0,
    isDaily,
  });

  const result = await TypingResult.create({
    studentId,
    subjectId,
    mode,
    difficulty,
    durationSec,
    unlimited,
    ...metrics,
    xpEarned: xp,
    isDaily,
    contentId: body.contentId || null,
  });

  const testsCompleted = stats.testsCompleted + 1;
  const totalWpmSum = stats.averageWpm * stats.testsCompleted + metrics.wpm;
  const totalAccSum = stats.averageAccuracy * stats.testsCompleted + metrics.accuracy;
  stats.testsCompleted = testsCompleted;
  stats.averageWpm = Math.round((totalWpmSum / testsCompleted) * 10) / 10;
  stats.averageAccuracy = Math.round((totalAccSum / testsCompleted) * 10) / 10;
  stats.bestWpm = Math.max(stats.bestWpm, metrics.wpm);
  stats.wordsTyped += metrics.wordsTyped;
  stats.charactersTyped += metrics.totalChars;
  stats.timePracticedSec += metrics.elapsedSec || durationSec || 0;
  stats.lastResultId = result._id;
  stats.lastWpm = metrics.wpm;
  stats.modeCounts[mode] = (stats.modeCounts[mode] || 0) + 1;
  const counts = stats.modeCounts;
  stats.favoriteMode = ['english', 'programming', 'code'].sort(
    (a, b) => (counts[b] || 0) - (counts[a] || 0)
  )[0];
  if (isDaily) {
    const day = utcDateString();
    if (!stats.dailyCompletions.includes(day)) {
      stats.dailyCompletions = [...stats.dailyCompletions.slice(-60), day];
    }
  }
  await stats.save();

  const xpResult = await awardXp(studentId, {
    module: 'typing',
    amount: xp,
    reason: reasons.join(', '),
  });

  const profile = xpResult?.profile || formatProfile((await getOrCreateProfile(studentId)).toObject());
  const typingLevel = typingLevelFromXp(profile.totalXp);

  const improvement = Math.round((metrics.wpm - previousWpm) * 10) / 10;

  return {
    result: {
      id: String(result._id),
      wpm: metrics.wpm,
      rawWpm: metrics.rawWpm,
      accuracy: metrics.accuracy,
      correctWords: metrics.correctWords,
      wrongWords: metrics.wrongWords,
      totalChars: metrics.totalChars,
      correctChars: metrics.correctChars,
      incorrectChars: metrics.incorrectChars,
      mistakes: metrics.mistakes,
      wordsTyped: metrics.wordsTyped,
      xpEarned: xp,
      xpReasons: reasons,
      mode,
      difficulty,
      isDaily,
      improvementVsLast: improvement,
      previousWpm,
    },
    rank: profile.rank || null,
    level: typingLevel.level,
    totalXp: profile.totalXp,
    currentStreak: profile.currentStreak,
    achievements: xpResult?.achievements || [],
    stats: {
      bestWpm: stats.bestWpm,
      averageWpm: stats.averageWpm,
      averageAccuracy: stats.averageAccuracy,
      testsCompleted: stats.testsCompleted,
    },
  };
};

const dashboard = async (req, query = {}) => {
  const subjectId = query.subjectId;
  await assertTypingSubject(subjectId);
  const studentId = resolveStudentId(req, query.studentId);

  const leaderboardSize = await TypingStudentStats.countDocuments({
    subjectId,
    bestWpm: { $gt: 0 },
  });
  const testsTotal = await TypingResult.countDocuments({ subjectId });

  // Staff opening IT → Typing without a student profile.
  if (!studentId) {
    return {
      subjectId: String(subjectId),
      staffView: true,
      level: 1,
      xp: 0,
      xpInLevel: 0,
      xpToNextLevel: 100,
      currentRank: null,
      leaderboardSize,
      bestWpm: 0,
      averageWpm: 0,
      accuracy: 0,
      currentStreak: 0,
      longestStreak: 0,
      timePracticedSec: 0,
      wordsTyped: 0,
      testsCompleted: testsTotal,
      favoriteMode: null,
      dailyChallengeCompleted: false,
      settings: {},
      message: 'Staff view — open Practice to try a session. Student XP and ranks appear on student accounts.',
    };
  }

  const [stats, profileDoc, bestRank] = await Promise.all([
    getOrCreateStats(studentId, subjectId),
    getOrCreateProfile(studentId),
    (async () => {
      const mine = await TypingStudentStats.findOne({ studentId, subjectId }).lean();
      if (!mine || !mine.bestWpm) return { rank: null, total: leaderboardSize };
      const better = await TypingStudentStats.countDocuments({
        subjectId,
        bestWpm: { $gt: mine.bestWpm },
      });
      return { rank: better + 1, total: leaderboardSize };
    })(),
  ]);

  const profile = formatProfile(profileDoc.toObject(), bestRank.rank);
  const typingLevel = typingLevelFromXp(profile.totalXp);
  const day = utcDateString();
  const dailyDone = (stats.dailyCompletions || []).includes(day);

  return {
    subjectId: String(subjectId),
    staffView: false,
    level: typingLevel.level,
    xp: profile.totalXp,
    xpInLevel: typingLevel.xpInLevel,
    xpToNextLevel: typingLevel.xpToNextLevel,
    currentRank: bestRank.rank,
    leaderboardSize: bestRank.total,
    bestWpm: stats.bestWpm,
    averageWpm: stats.averageWpm,
    accuracy: stats.averageAccuracy,
    currentStreak: profile.currentStreak,
    longestStreak: profile.longestStreak,
    timePracticedSec: stats.timePracticedSec,
    wordsTyped: stats.wordsTyped,
    testsCompleted: stats.testsCompleted,
    favoriteMode: stats.favoriteMode,
    dailyChallengeCompleted: dailyDone,
    settings: stats.settings,
  };
};

const leaderboard = async (req, query = {}) => {
  const subjectId = query.subjectId;
  await assertTypingSubject(subjectId);
  const period = query.period === 'weekly' ? 'weekly' : 'all';
  const limit = Math.min(50, Math.max(1, Number(query.limit) || 20));

  if (period === 'weekly') {
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const rows = await TypingResult.aggregate([
      { $match: { subjectId: new mongoose.Types.ObjectId(subjectId), createdAt: { $gte: since } } },
      {
        $group: {
          _id: '$studentId',
          bestWpm: { $max: '$wpm' },
          avgAccuracy: { $avg: '$accuracy' },
          tests: { $sum: 1 },
        },
      },
      { $sort: { bestWpm: -1 } },
      { $limit: limit },
    ]);
    const students = await Student.find({ _id: { $in: rows.map((r) => r._id) } })
      .select('name profileImage')
      .lean();
    const byId = new Map(students.map((s) => [String(s._id), s]));
    const profiles = await Promise.all(rows.map((r) => getOrCreateProfile(r._id)));
    const profileById = new Map(profiles.map((p) => [String(p.studentId), p]));

    return {
      period,
      items: rows.map((r, i) => {
        const s = byId.get(String(r._id));
        const p = profileById.get(String(r._id));
        return {
          rank: i + 1,
          studentId: String(r._id),
          name: s?.name || 'Student',
          avatar: s?.profileImage || null,
          level: getLevelInfo(p?.totalXp || 0).level,
          wpm: Math.round(r.bestWpm),
          accuracy: Math.round((r.avgAccuracy || 0) * 10) / 10,
          tests: r.tests,
        };
      }),
    };
  }

  const rows = await TypingStudentStats.find({ subjectId, bestWpm: { $gt: 0 } })
    .sort({ bestWpm: -1 })
    .limit(limit)
    .lean();
  const students = await Student.find({ _id: { $in: rows.map((r) => r.studentId) } })
    .select('name profileImage')
    .lean();
  const byId = new Map(students.map((s) => [String(s._id), s]));
  const profiles = await Promise.all(rows.map((r) => getOrCreateProfile(r.studentId)));
  const profileById = new Map(profiles.map((p) => [String(p.studentId), p]));

  return {
    period,
    items: rows.map((r, i) => {
      const s = byId.get(String(r.studentId));
      const p = profileById.get(String(r.studentId));
      return {
        rank: i + 1,
        studentId: String(r.studentId),
        name: s?.name || 'Student',
        avatar: s?.profileImage || null,
        level: getLevelInfo(p?.totalXp || 0).level,
        wpm: r.bestWpm,
        accuracy: r.averageAccuracy,
        tests: r.testsCompleted,
      };
    }),
  };
};

const daily = async (req, query = {}) => {
  const subjectId = query.subjectId;
  await assertTypingSubject(subjectId);
  let dailyDone = false;
  if (req.userType === 'student') {
    const stats = await getOrCreateStats(req.user._id, subjectId);
    dailyDone = (stats.dailyCompletions || []).includes(utcDateString());
  }
  const prompt = await buildPrompt({ mode: 'programming', difficulty: 'medium', isDaily: true });
  return {
    date: utcDateString(),
    durationSec: 60,
    mode: 'programming',
    difficulty: 'medium',
    completed: dailyDone,
    prompt,
  };
};

const history = async (req, query = {}) => {
  const subjectId = query.subjectId;
  await assertTypingSubject(subjectId);
  const studentId = resolveStudentId(req, query.studentId);
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(50, Math.max(1, Number(query.limit) || 20));
  if (!studentId) {
    return { items: [], page, limit, total: 0, staffView: true };
  }
  const filter = { studentId, subjectId };
  const [items, total] = await Promise.all([
    TypingResult.find(filter)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean(),
    TypingResult.countDocuments(filter),
  ]);
  return {
    items: items.map((r) => ({
      id: String(r._id),
      mode: r.mode,
      difficulty: r.difficulty,
      wpm: r.wpm,
      accuracy: r.accuracy,
      xpEarned: r.xpEarned,
      isDaily: r.isDaily,
      createdAt: r.createdAt,
    })),
    page,
    limit,
    total,
  };
};

const listContent = async (query = {}) => {
  const filter = {};
  if (query.kind) filter.kind = query.kind;
  if (query.difficulty) filter.difficulty = query.difficulty;
  const items = await TypingContent.find(filter).sort({ kind: 1, difficulty: 1, title: 1 }).lean();
  return items.map((c) => ({
    id: String(c._id),
    kind: c.kind,
    title: c.title,
    difficulty: c.difficulty,
    language: c.language,
    wordCount: (c.words || []).length,
    codePreview: c.code ? String(c.code).slice(0, 80) : '',
    published: c.published,
  }));
};

module.exports = {
  start,
  finish,
  dashboard,
  leaderboard,
  daily,
  history,
  listContent,
  isItTypingSubject,
  assertTypingSubject,
  typingLevelFromXp,
};
