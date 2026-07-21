const VideoLesson = require('../models/VideoLesson');
const StudentVideoProgress = require('../models/StudentVideoProgress');
const TopicTest = require('../models/TopicTest');
const StudentTestResult = require('../models/StudentTestResult');
const ExamGroup = require('../models/ExamGroup');
const Language = require('../models/Language');
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
  const languages = await Language.find({}).select('_id name').lean();
  return languages
    .filter((l) => subjectNames.includes((l.name || '').toLowerCase().trim()))
    .map((l) => l._id);
};

const formatVideo = (doc, progress = null) => ({
  id: doc._id,
  title: doc.title,
  description: doc.description || '',
  thumbnail: doc.thumbnail || '',
  youtubeUrl: doc.youtubeUrl,
  youtubeVideoId: doc.youtubeVideoId,
  duration: doc.duration || 0,
  languageId: doc.languageId?._id || doc.languageId,
  languageName: doc.languageId?.name || '',
  levelId: doc.levelId?._id || doc.levelId,
  levelName: doc.levelId?.name || '',
  difficulty: doc.difficulty || 'beginner',
  topic: doc.topic || '',
  requireWatchPercent: doc.requireWatchPercent ?? 70,
  watchUnlockedFor: doc.watchUnlockedFor || [],
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
    .sort({ createdAt: -1 })
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
  const video = await VideoLesson.create({ ...data, createdBy });
  return formatVideo(video.toObject());
};

const updateVideoLesson = async (id, data) => {
  const video = await VideoLesson.findById(id);
  if (!video) throw Object.assign(new Error('Video lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  Object.assign(video, data);
  await video.save();
  return formatVideo(video.toObject());
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

const toggleWatchUnlock = async (id, groupId) => {
  if (!groupId) throw Object.assign(new Error('groupId is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  const video = await VideoLesson.findById(id);
  if (!video) throw Object.assign(new Error('Video not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const alreadyUnlocked = (video.watchUnlockedFor || []).some((g) => String(g) === String(groupId));
  if (alreadyUnlocked) {
    video.watchUnlockedFor = (video.watchUnlockedFor || []).filter((g) => String(g) !== String(groupId));
    await video.save();
    return { video: formatVideo(video.toObject()), message: 'Video locked for this group' };
  }

  await VideoLesson.updateMany(
    { levelId: video.levelId, _id: { $ne: video._id }, watchUnlockedFor: groupId },
    { $pull: { watchUnlockedFor: groupId } }
  );
  video.watchUnlockedFor = [...(video.watchUnlockedFor || []), groupId];
  await video.save();
  return { video: formatVideo(video.toObject()), message: 'Video unlocked (previous video in this level auto-locked)' };
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
};
