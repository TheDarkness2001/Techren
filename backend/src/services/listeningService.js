const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const config = require('../config');
const ListeningExercise = require('../models/ListeningExercise');
const Lesson = require('../models/Lesson');
const Level = require('../models/Level');
const Student = require('../models/Student');
const StudentListeningProgress = require('../models/StudentListeningProgress');
const { analyzeListeningAnswer } = require('../utils/listeningValidator');
const { normalizeText } = require('../utils/textNormalizer');
const { getStudentGroupIds, isPracticeUnlockedForStudent } = require('./examGateService');
const { UPLOAD_DIR } = require('../middleware/audioUpload');

const AUDIO_MIME_TYPES = {
  '.mp3': 'audio/mpeg',
  '.mpeg': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.ogg': 'audio/ogg',
  '.m4a': 'audio/mp4',
  '.aac': 'audio/aac',
  '.webm': 'audio/webm',
};

const isRemoteAudioUrl = (audioFile) =>
  typeof audioFile === 'string' && (audioFile.startsWith('http://') || audioFile.startsWith('https://'));

const formatExercise = (doc, { includeScript = false } = {}) => {
  const base = {
    id: doc._id,
    title: doc.title,
    lessonId: doc.lessonId,
    order: doc.order,
    audioFile: doc.audioFile,
    hasAudio: Boolean(doc.audioFile),
  };
  if (includeScript) return { ...base, script: doc.script };
  return base;
};

const getOrCreateListeningLesson = async (levelId) => {
  let lesson = await Lesson.findOne({ levelId, type: 'listening' }).sort({ order: 1 });
  if (!lesson) {
    lesson = await Lesson.create({ name: 'Exercises', levelId, order: 1, type: 'listening' });
  }
  return lesson;
};

const buildFilter = async ({ lessonId, levelId }) => {
  if (lessonId) return { lessonId };
  if (levelId) {
    const lessons = await Lesson.find({ levelId, type: 'listening' }).select('_id');
    return { lessonId: { $in: lessons.map((l) => l._id) } };
  }
  return {};
};

const listExercises = async (query, { includeScript = false } = {}) => {
  const filter = await buildFilter(query);
  const exercises = await ListeningExercise.find(filter).sort({ order: 1, createdAt: 1 });
  return exercises.map((e) => formatExercise(e, { includeScript }));
};

const getRandomExercise = async (query) => {
  const filter = await buildFilter(query);
  const count = await ListeningExercise.countDocuments(filter);
  if (count === 0) {
    throw Object.assign(new Error('No listening exercises available'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  const random = Math.floor(Math.random() * count);
  const exercise = await ListeningExercise.findOne(filter).skip(random);
  return formatExercise(exercise);
};

const createExercise = async (data, file) => {
  if (!data.title?.trim() || !data.script?.trim()) {
    throw Object.assign(new Error('Title and script are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  if (!file && !data.audioFile) {
    throw Object.assign(new Error('Audio file is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  let lessonId = data.lessonId;
  if (!lessonId && data.levelId) {
    const lesson = await getOrCreateListeningLesson(data.levelId);
    lessonId = lesson._id;
  }
  if (!lessonId) {
    throw Object.assign(new Error('Level ID or lesson ID is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const exercise = await ListeningExercise.create({
    title: normalizeText(data.title),
    script: normalizeText(data.script),
    audioFile: file ? file.filename : data.audioFile,
    lessonId,
    order: data.order || 1,
  });
  return formatExercise(exercise, { includeScript: true });
};

const updateExercise = async (id, data, file) => {
  const exercise = await ListeningExercise.findById(id);
  if (!exercise) throw Object.assign(new Error('Exercise not found'), { statusCode: 404, code: 'NOT_FOUND' });

  if (data.title?.trim()) exercise.title = normalizeText(data.title);
  if (data.script?.trim()) exercise.script = normalizeText(data.script);
  if (data.order !== undefined) exercise.order = data.order;
  if (file) {
    if (!isRemoteAudioUrl(exercise.audioFile)) {
      const oldPath = path.join(UPLOAD_DIR, exercise.audioFile);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }
    exercise.audioFile = file.filename;
  }
  await exercise.save();
  return formatExercise(exercise, { includeScript: true });
};

const removeExercise = async (id) => {
  const exercise = await ListeningExercise.findById(id);
  if (!exercise) throw Object.assign(new Error('Exercise not found'), { statusCode: 404, code: 'NOT_FOUND' });
  if (!isRemoteAudioUrl(exercise.audioFile)) {
    const audioPath = path.join(UPLOAD_DIR, exercise.audioFile);
    if (fs.existsSync(audioPath)) fs.unlinkSync(audioPath);
  }
  await StudentListeningProgress.deleteMany({ listeningId: id });
  await exercise.deleteOne();
  return formatExercise(exercise);
};

const checkAnswer = async (studentId, { listeningId, answer }) => {
  if (!listeningId) {
    throw Object.assign(new Error('Listening ID is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const exercise = await ListeningExercise.findById(listeningId);
  if (!exercise) throw Object.assign(new Error('Listening exercise not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const analysis = analyzeListeningAnswer(exercise.script, answer != null ? String(answer) : '');
  if (analysis.error === 'INVALID TRANSCRIPT') {
    throw Object.assign(new Error('INVALID TRANSCRIPT'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  if (studentId) {
    let progress = await StudentListeningProgress.findOne({ studentId, listeningId });
    if (!progress) progress = new StudentListeningProgress({ studentId, listeningId });
    progress.attempts += 1;
    progress.lastAccuracy = analysis.accuracyPercent;
    progress.bestAccuracy = Math.max(progress.bestAccuracy, analysis.accuracyPercent);
    progress.lastPracticeDate = new Date();
    await progress.save();

    const gamificationService = require('./gamificationService');
    if (analysis.passed || analysis.resultTier === 'passed') {
      await gamificationService.awardXp(studentId, {
        module: 'listening',
        amount: gamificationService.XP_REWARDS.listening_passed,
        reason: 'listening_passed',
      });
    } else if (analysis.resultTier === 'partial') {
      await gamificationService.awardXp(studentId, {
        module: 'listening',
        amount: gamificationService.XP_REWARDS.listening_partial,
        reason: 'listening_partial',
      });
    }
  }

  return {
    accuracyPercent: analysis.accuracyPercent,
    correctWords: analysis.correctWords,
    totalWords: analysis.totalWords,
    missingWords: analysis.showMissingWords ? analysis.missingWords : [],
    missingCount: analysis.showMissingWords ? analysis.missingCount : 0,
    resultTier: analysis.resultTier,
    tier: analysis.resultTier,
    taskFailed: analysis.taskFailed,
    passed: analysis.passed,
    tryAgain: analysis.tryAgain,
    showMissingWords: analysis.showMissingWords,
    isCorrect: analysis.isCorrect,
    formattedResult: analysis.formattedResult,
  };
};

const getProgress = async (studentId) => {
  const progress = await StudentListeningProgress.find({ studentId });
  const totalAttempts = progress.reduce((sum, p) => sum + p.attempts, 0);
  const avgBestAccuracy = progress.length > 0
    ? Math.round(progress.reduce((sum, p) => sum + p.bestAccuracy, 0) / progress.length)
    : 0;
  return { progress, totalAttempts, avgBestAccuracy };
};

const getLeaderboard = async (req) => {
  const records = await StudentListeningProgress.find().lean();
  const studentMap = new Map();

  for (const record of records) {
    const sid = String(record.studentId);
    if (!studentMap.has(sid)) studentMap.set(sid, { studentId: sid, totalAttempts: 0, totalExercises: 0, bestSum: 0 });
    const entry = studentMap.get(sid);
    entry.totalAttempts += record.attempts || 0;
    entry.totalExercises += 1;
    entry.bestSum += record.bestAccuracy || 0;
  }

  const students = await Student.find({ _id: { $in: [...studentMap.keys()] } }).select('name studentId profileImage');
  const info = new Map(students.map((s) => [String(s._id), s]));

  const allRanked = [...studentMap.values()]
    .map((s) => ({
      studentId: s.studentId,
      name: info.get(s.studentId)?.name || 'Unknown',
      studentCode: info.get(s.studentId)?.studentId || '',
      profileImage: info.get(s.studentId)?.profileImage || null,
      totalAttempts: s.totalAttempts,
      avgBestAccuracy: s.totalExercises > 0 ? Math.round(s.bestSum / s.totalExercises) : 0,
    }))
    .filter((s) => s.totalAttempts > 0)
    .sort((a, b) => b.avgBestAccuracy - a.avgBestAccuracy || b.totalAttempts - a.totalAttempts);

  const leaderboard = allRanked.slice(0, 10).map((s, i) => ({ ...s, rank: i + 1 }));

  let currentStudent = null;
  if (req.userType === 'student' && req.user?._id) {
    const sid = String(req.user._id);
    const idx = allRanked.findIndex((s) => s.studentId === sid);
    if (idx >= 0) currentStudent = { ...allRanked[idx], rank: idx + 1, totalStudents: allRanked.length };
  }

  return { leaderboard, currentStudent };
};

const getStudentLevelTree = async (studentId) => {
  const groupIds = await getStudentGroupIds(studentId);
  const levels = await Level.find({ moduleType: 'listening' });
  const lessons = await Lesson.find({ type: 'listening' });
  const lessonIds = lessons.map((l) => l._id);
  const exercises = await ListeningExercise.find({ lessonId: { $in: lessonIds } }).sort({ order: 1 });
  const lessonLevelMap = new Map(lessons.map((l) => [String(l._id), String(l.levelId)]));

  const exercisesByLevel = new Map();
  for (const exercise of exercises) {
    const levelId = lessonLevelMap.get(String(exercise.lessonId));
    if (!levelId) continue;
    if (!exercisesByLevel.has(levelId)) exercisesByLevel.set(levelId, []);
    exercisesByLevel.get(levelId).push(formatExercise(exercise));
  }

  return levels
    .filter((level) => isPracticeUnlockedForStudent(level, groupIds))
    .map((level) => ({
      id: level._id,
      name: level.name,
      exercises: exercisesByLevel.get(String(level._id)) || [],
    }));
};

const getAudioStreamMeta = async (id) => {
  const exercise = await ListeningExercise.findById(id).select('audioFile');
  if (!exercise?.audioFile) {
    throw Object.assign(new Error('Audio not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return exercise;
};

const resolveAudioPath = (audioFile) => {
  if (isRemoteAudioUrl(audioFile)) return { remote: true, url: audioFile };
  const audioPath = path.join(UPLOAD_DIR, audioFile);
  if (!fs.existsSync(audioPath)) {
    throw Object.assign(new Error('Audio file missing. Please re-upload this exercise.'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  const ext = path.extname(audioFile).toLowerCase();
  return { remote: false, path: audioPath, mimeType: AUDIO_MIME_TYPES[ext] || 'audio/mpeg' };
};

const createAudioAccessToken = (userId, exerciseId) =>
  jwt.sign({ id: userId, exerciseId, scope: 'listening-audio' }, config.jwt.secret, { expiresIn: '15m' });

const verifyAudioAccessToken = (token, exerciseId) => {
  const decoded = jwt.verify(token, config.jwt.secret);
  if (decoded.scope !== 'listening-audio' || String(decoded.exerciseId) !== String(exerciseId)) {
    throw new Error('Invalid audio token');
  }
  return decoded;
};

module.exports = {
  listExercises,
  getRandomExercise,
  createExercise,
  updateExercise,
  removeExercise,
  checkAnswer,
  getProgress,
  getLeaderboard,
  getStudentLevelTree,
  getAudioStreamMeta,
  resolveAudioPath,
  createAudioAccessToken,
  verifyAudioAccessToken,
  isRemoteAudioUrl,
};
