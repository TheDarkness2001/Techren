const VideoLesson = require('../models/VideoLesson');
const StudentVideoProgress = require('../models/StudentVideoProgress');
const TopicTest = require('../models/TopicTest');
const ExamGroup = require('../models/ExamGroup');
const Language = require('../models/Language');
const Level = require('../models/Level');
const Subject = require('../models/Subject');
const { getStudentGroupIds } = require('./examGateService');

const getStudentAccessibleLanguageIds = async (studentId) => {
  const groups = await ExamGroup.find({ students: studentId })
    .populate('subject', 'name')
    .select('subject students')
    .lean();
  if (!groups.length) return [];
  const subjectNames = groups
    .map((g) => (g.subject?.name || '').toLowerCase().trim())
    .filter(Boolean);
  if (!subjectNames.length) return [];
  const languages = await Language.find({ moduleType: { $in: ['video', 'words'] } }).select('_id name').lean();
  return languages
    .filter((l) => subjectNames.includes((l.name || '').toLowerCase().trim()))
    .map((l) => l._id);
};

const formatVideo = (doc, progress = null) => ({
  id: doc._id,
  title: doc.title,
  description: doc.description || '',
  topic: doc.topic || '',
  thumbnail: doc.thumbnail || '',
  youtubeUrl: doc.youtubeUrl,
  youtubeVideoId: doc.youtubeVideoId,
  duration: doc.duration || 0,
  languageId: doc.languageId?._id || doc.languageId,
  languageName: doc.languageId?.name || '',
  levelId: doc.levelId?._id || doc.levelId,
  levelName: doc.levelId?.name || '',
  subjectId: doc.subjectId ? String(doc.subjectId._id || doc.subjectId) : null,
  order: doc.order ?? 1,
  difficulty: doc.difficulty || 'beginner',
  requireWatchPercent: doc.requireWatchPercent ?? 70,
  watchUnlockedFor: (doc.watchUnlockedFor || []).map((g) => String(g._id || g)),
  progress: progress
    ? {
        watchPercent: progress.watchPercent || 0,
        completed: !!progress.completed,
        completedAt: progress.completedAt,
        lastTimestamp: progress.lastTimestamp || 0,
        rewatchCount: progress.rewatchCount || 0,
      }
    : null,
});

const listVideoLessons = async (query, { userType, userId } = {}) => {
  const filter = { isActive: true };
  if (query.languageId) filter.languageId = query.languageId;
  if (query.levelId) filter.levelId = query.levelId;
  if (query.lessonId) filter.lessonId = query.lessonId;
  if (query.subjectId) filter.subjectId = query.subjectId;

  if (userType === 'student') {
    const allowedLangIds = await getStudentAccessibleLanguageIds(userId);
    if (!allowedLangIds.length) return [];
    if (filter.languageId) {
      if (!allowedLangIds.map(String).includes(String(filter.languageId))) return [];
    } else {
      filter.languageId = { $in: allowedLangIds };
    }
    const studentGroupIds = await getStudentGroupIds(userId);
    if (!studentGroupIds.length) return [];
    filter.watchUnlockedFor = { $in: studentGroupIds };
  }

  const videos = await VideoLesson.find(filter)
    .populate('languageId', 'name')
    .populate('levelId', 'name')
    .sort({ order: 1, createdAt: 1 })
    .lean();

  if (userType !== 'student' || !videos.length) {
    return videos.map((v) => formatVideo(v));
  }

  const videoIds = videos.map((v) => v._id);
  const progressDocs = await StudentVideoProgress.find({
    studentId: userId,
    videoLessonId: { $in: videoIds },
  }).lean();
  const progressMap = new Map(progressDocs.map((p) => [String(p.videoLessonId), p]));
  return videos.map((v) => formatVideo(v, progressMap.get(String(v._id)) || null));
};

const getVideoLessonById = async (id, { userType, userId } = {}) => {
  const video = await VideoLesson.findById(id)
    .populate('languageId', 'name')
    .populate('levelId', 'name')
    .lean();
  if (!video || !video.isActive) {
    throw Object.assign(new Error('Video lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  if (userType === 'student') {
    const groupIds = await getStudentGroupIds(userId);
    const unlocked = (video.watchUnlockedFor || []).some((g) => groupIds.includes(String(g)));
    if (!unlocked) {
      throw Object.assign(new Error('This video is locked for your group'), {
        statusCode: 403,
        code: 'FORBIDDEN',
      });
    }
  }

  const test = await TopicTest.findOne({ videoLessonId: id }).lean();
  let progress = null;
  if (userType === 'student') {
    progress = await StudentVideoProgress.findOne({ studentId: userId, videoLessonId: id }).lean();
  }

  return {
    videoLesson: formatVideo(video, progress),
    hasTest: !!(test?.questions?.length),
    testMeta: test
      ? {
          id: test._id,
          title: test.title,
          practiceEnabled: test.practiceEnabled,
          examEnabled: test.examEnabled,
          timerSeconds: test.timerSeconds,
          passingScore: test.passingScore,
          questionCount: test.questions.length,
        }
      : null,
    progress: progress
      ? {
          watchPercent: progress.watchPercent || 0,
          completed: !!progress.completed,
          completedAt: progress.completedAt,
          lastTimestamp: progress.lastTimestamp || 0,
        }
      : null,
  };
};

const createVideoLesson = async (data, createdBy) => {
  if (!data.youtubeUrl?.trim()) {
    throw Object.assign(new Error('YouTube URL is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const videoId = VideoLesson.extractYouTubeId(data.youtubeUrl);
  if (!videoId) {
    throw Object.assign(new Error('Invalid YouTube URL'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  if (!data.languageId || !data.levelId) {
    throw Object.assign(new Error('languageId and levelId are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }
  const video = await VideoLesson.create({
    title: data.title,
    description: data.description || '',
    topic: data.topic || '',
    youtubeUrl: data.youtubeUrl.trim(),
    languageId: data.languageId,
    levelId: data.levelId,
    lessonId: data.lessonId || null,
    subjectId: data.subjectId || null,
    order: Number(data.order) || 1,
    difficulty: data.difficulty || 'beginner',
    requireWatchPercent: data.requireWatchPercent ?? 70,
    watchUnlockedFor: data.watchUnlockedFor || [],
    createdBy,
  });
  const populated = await VideoLesson.findById(video._id)
    .populate('languageId', 'name')
    .populate('levelId', 'name')
    .lean();
  return formatVideo(populated);
};

const updateVideoLesson = async (id, data) => {
  const video = await VideoLesson.findById(id);
  if (!video) throw Object.assign(new Error('Video lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  const allowed = [
    'title', 'description', 'topic', 'youtubeUrl', 'duration', 'difficulty',
    'requireWatchPercent', 'order', 'subjectId', 'isActive', 'thumbnail',
  ];
  for (const key of allowed) {
    if (data[key] !== undefined) video[key] = data[key];
  }
  await video.save();
  const populated = await VideoLesson.findById(video._id)
    .populate('languageId', 'name')
    .populate('levelId', 'name')
    .lean();
  return formatVideo(populated);
};

const softDeleteVideoLesson = async (id) => {
  const video = await VideoLesson.findById(id);
  if (!video) throw Object.assign(new Error('Video lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  video.isActive = false;
  await video.save();
  return formatVideo(video.toObject());
};

const trackWatchProgress = async (studentId, id, { watchPercent, lastTimestamp, delta, newSession }) => {
  const video = await VideoLesson.findById(id).lean();
  if (!video?.isActive) {
    throw Object.assign(new Error('Video lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  let progress = await StudentVideoProgress.findOne({ studentId, videoLessonId: id });
  if (!progress) progress = new StudentVideoProgress({ studentId, videoLessonId: id });

  if (typeof watchPercent === 'number') {
    progress.watchPercent = Math.max(progress.watchPercent || 0, Math.min(100, watchPercent));
  }
  if (typeof lastTimestamp === 'number') progress.lastTimestamp = lastTimestamp;
  if (typeof delta === 'number' && delta > 0) progress.totalWatchTime = (progress.totalWatchTime || 0) + delta;
  if (newSession) progress.rewatchCount = (progress.rewatchCount || 0) + 1;
  progress.lastAccessAt = new Date();

  const threshold = video.requireWatchPercent || 70;
  if (!progress.completed && progress.watchPercent >= threshold) {
    progress.completed = true;
    progress.completedAt = new Date();
  }
  await progress.save();
  return progress;
};

const markAsCompleted = async (studentId, id) => {
  let progress = await StudentVideoProgress.findOne({ studentId, videoLessonId: id });
  if (!progress) progress = new StudentVideoProgress({ studentId, videoLessonId: id });
  progress.completed = true;
  progress.completedAt = new Date();
  progress.watchPercent = Math.max(progress.watchPercent || 0, 100);
  progress.lastAccessAt = new Date();
  await progress.save();

  const gamificationService = require('./gamificationService');
  await gamificationService.awardXp(studentId, {
    module: 'video',
    amount: gamificationService.XP_REWARDS.video_completed,
    reason: 'video_completed',
  });

  return progress;
};

const toggleWatchUnlock = async (id, groupId, unlock) => {
  if (!groupId) throw Object.assign(new Error('groupId is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  const video = await VideoLesson.findById(id);
  if (!video) throw Object.assign(new Error('Video not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const alreadyUnlocked = (video.watchUnlockedFor || []).some((g) => String(g) === String(groupId));
  const shouldUnlock = typeof unlock === 'boolean' ? unlock : !alreadyUnlocked;

  if (!shouldUnlock) {
    video.watchUnlockedFor = (video.watchUnlockedFor || []).filter((g) => String(g) !== String(groupId));
    await video.save();
    return { video: formatVideo(video.toObject()), message: 'Video locked for this group' };
  }

  await VideoLesson.updateMany(
    { levelId: video.levelId, _id: { $ne: video._id }, watchUnlockedFor: groupId },
    { $pull: { watchUnlockedFor: groupId } }
  );
  if (!alreadyUnlocked) {
    video.watchUnlockedFor = [...(video.watchUnlockedFor || []), groupId];
  }
  await video.save();
  return {
    video: formatVideo(video.toObject()),
    message: 'Video unlocked (other classes in this level locked for the group)',
  };
};

const ensureVideoTreeForSubject = async (subjectId, { createIfMissing = true } = {}) => {
  const subject = await Subject.findById(subjectId).lean();
  if (!subject) {
    throw Object.assign(new Error('Subject not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  const name = subject.name.trim();
  let language = await Language.findOne({ name, moduleType: 'video' });
  if (!language && createIfMissing) {
    language = await Language.create({ name, moduleType: 'video' });
  }
  if (!language) {
    return {
      language: null,
      subjectId: String(subject._id),
      subjectName: subject.name,
      levels: [],
    };
  }
  const levels = await Level.find({ languageId: language._id, moduleType: 'video' }).sort({ order: 1, name: 1 });
  return {
    language: { id: language._id, name: language.name, moduleType: language.moduleType },
    subjectId: String(subject._id),
    subjectName: subject.name,
    levels: levels.map((l) => ({
      id: l._id,
      name: l.name,
      languageId: l.languageId,
      classesCount: l.classesCount ?? 11,
      moduleType: l.moduleType,
      order: l.order ?? 0,
    })),
  };
};

const createVideoLevel = async ({ subjectId, name, classesCount = 11 }) => {
  const tree = await ensureVideoTreeForSubject(subjectId);
  const level = await Level.create({
    name: String(name).trim(),
    languageId: tree.language.id,
    classesCount: Number(classesCount) || 11,
    moduleType: 'video',
    order: (tree.levels?.length || 0) + 1,
  });
  return {
    id: level._id,
    name: level.name,
    languageId: level.languageId,
    classesCount: level.classesCount,
    moduleType: level.moduleType,
    order: level.order,
  };
};

module.exports = {
  listVideoLessons,
  getVideoLessonById,
  createVideoLesson,
  updateVideoLesson,
  softDeleteVideoLesson,
  trackWatchProgress,
  markAsCompleted,
  toggleWatchUnlock,
  ensureVideoTreeForSubject,
  createVideoLevel,
};
