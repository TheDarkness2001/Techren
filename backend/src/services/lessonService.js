const Lesson = require('../models/Lesson');
const Level = require('../models/Level');
const Word = require('../models/Word');
const StudentVocabProgress = require('../models/StudentVocabProgress');
const { checkVocabAnswer } = require('../utils/vocabAnswerChecker');
const {
  isStudentInClassWindow,
  getStudentGroupIds,
  isExamUnlockedForStudent,
  isPracticeUnlockedForStudent,
  hasTakenExamToday,
} = require('./examGateService');
const homeworkService = require('./homeworkService');

const formatLesson = (lesson, extras = {}) => ({
  id: lesson._id,
  name: lesson.name,
  levelId: lesson.levelId,
  order: lesson.order,
  wordCount: lesson.wordIds?.length ?? extras.wordCount ?? 0,
  maxWords: lesson.maxWords,
  type: lesson.type,
  examTimeLimit: lesson.examTimeLimit,
  minPassScore: lesson.minPassScore,
  examUnlockedFor: lesson.examUnlockedFor || [],
  directionMode: lesson.directionMode,
  ...extras,
});

const listLessons = async ({ levelId, type = 'words' }) => {
  const filter = { type };
  if (levelId) filter.levelId = levelId;
  const lessons = await Lesson.find(filter).sort({ order: 1 });
  return lessons.map((l) => formatLesson(l, { wordCount: l.wordIds.length }));
};

const getLesson = async (id) => {
  const lesson = await Lesson.findById(id);
  if (!lesson) throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  const words = await Word.find({ lessonId: lesson._id });
  return { ...formatLesson(lesson, { wordCount: words.length }), words: words.map((w) => ({ id: w._id, english: w.english, uzbek: w.uzbek })) };
};

const createLesson = async (data) => {
  const lesson = await Lesson.create({
    name: data.name.trim(),
    levelId: data.levelId,
    order: data.order || 1,
    maxWords: data.maxWords,
    type: data.type || 'words',
    examTimeLimit: data.examTimeLimit,
    minPassScore: data.minPassScore,
    directionMode: data.directionMode,
    examUnlockedFor: data.examUnlockedFor || [],
  });
  return formatLesson(lesson);
};

const updateLesson = async (id, data) => {
  const lesson = await Lesson.findByIdAndUpdate(id, data, { new: true, runValidators: true });
  if (!lesson) throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  return formatLesson(lesson, { wordCount: lesson.wordIds.length });
};

const removeLesson = async (id) => {
  const lesson = await Lesson.findById(id);
  if (!lesson) throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  await Word.deleteMany({ lessonId: lesson._id });
  await StudentVocabProgress.deleteMany({ lessonId: lesson._id });
  await lesson.deleteOne();
  return formatLesson(lesson);
};

const toggleExamLock = async (lessonId, groupId, unlock) => {
  const lesson = await Lesson.findById(lessonId);
  if (!lesson) throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  const ids = (lesson.examUnlockedFor || []).map(String);
  if (unlock && !ids.includes(String(groupId))) lesson.examUnlockedFor.push(groupId);
  else if (!unlock) lesson.examUnlockedFor = lesson.examUnlockedFor.filter((g) => String(g) !== String(groupId));
  await lesson.save();
  return formatLesson(lesson, { wordCount: lesson.wordIds.length });
};

const getStudentLessonTree = async (studentId) => {
  const groupIds = await getStudentGroupIds(studentId);
  const levels = await Level.find({ moduleType: 'words' });
  const lessons = await Lesson.find({ type: 'words' }).sort({ levelId: 1, order: 1 });
  const progressRecords = await StudentVocabProgress.find({ studentId });
  const progressMap = new Map(progressRecords.map((p) => [String(p.lessonId), p]));

  return levels
    .filter((level) => isPracticeUnlockedForStudent(level, groupIds))
    .map((level) => ({
      ...level.toObject(),
      id: level._id,
      lessons: lessons
        .filter((l) => String(l.levelId) === String(level._id))
        .map((lesson) => {
          const progress = progressMap.get(String(lesson._id));
          const status = progress?.status || (lesson.order === 1 ? 'available' : 'locked');
          return {
            ...formatLesson(lesson),
            status,
            bestExamScore: progress?.bestExamScore ?? 0,
            examUnlocked: isExamUnlockedForStudent(lesson, groupIds),
            practiceAttempts: progress?.practiceAttempts ?? 0,
          };
        }),
    }));
};

const getExamWords = async (studentId, lessonId) => {
  const timeCheck = await isStudentInClassWindow(studentId);
  if (!timeCheck.allowed) {
    throw Object.assign(new Error(timeCheck.reason), { statusCode: 403, code: 'OUTSIDE_CLASS_HOURS' });
  }

  const lesson = await Lesson.findById(lessonId);
  if (!lesson) throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const groupIds = await getStudentGroupIds(studentId);
  if (!isExamUnlockedForStudent(lesson, groupIds)) {
    throw Object.assign(new Error('This exam is currently locked by your teacher.'), { statusCode: 403, code: 'EXAM_LOCKED' });
  }

  const progress = await StudentVocabProgress.findOne({ studentId, lessonId });
  if (hasTakenExamToday(progress)) {
    throw Object.assign(new Error('You can only take this exam once per day. Please try again tomorrow.'), { statusCode: 403, code: 'DAILY_LIMIT' });
  }

  if (!lesson.wordIds.length) {
    throw Object.assign(new Error('No words in this lesson'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const words = await Word.find({ _id: { $in: lesson.wordIds } });
  return {
    examWords: words.map((word) => homeworkService.formatWordPrompt(word, homeworkService.pickDirection(lesson))),
    timeLimit: lesson.examTimeLimit,
    minPassScore: lesson.minPassScore,
  };
};

const submitExam = async (studentId, lessonId, answers) => {
  if (!Array.isArray(answers)) {
    throw Object.assign(new Error('Answers array is required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const lesson = await Lesson.findById(lessonId);
  if (!lesson) throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const words = await Word.find({ _id: { $in: answers.map((a) => a.wordId) } });
  const wordMap = new Map(words.map((w) => [String(w._id), w]));

  let correctCount = 0;
  const checkedAnswers = answers.map((ans) => {
    const word = wordMap.get(String(ans.wordId));
    if (!word) return { ...ans, isCorrect: false, correctAnswer: '' };
    const result = checkVocabAnswer(word, ans);
    if (result.isCorrect) correctCount += 1;
    return { ...ans, ...result };
  });

  const totalQuestions = answers.length;
  const score = totalQuestions > 0 ? Math.round((correctCount / totalQuestions) * 100) : 0;
  const passed = score >= lesson.minPassScore;

  let progress = await StudentVocabProgress.findOne({ studentId, lessonId });
  if (!progress) progress = new StudentVocabProgress({ studentId, lessonId });

  progress.examAttempts += 1;
  if (score > progress.bestExamScore) progress.bestExamScore = score;
  progress.lastExamDate = new Date();
  progress.wordsTotal = totalQuestions;
  progress.wordsMemorized = correctCount;

  if (passed && progress.status !== 'passed') {
    progress.status = 'passed';
    const nextLesson = await Lesson.findOne({ levelId: lesson.levelId, order: lesson.order + 1 });
    if (nextLesson) {
      await StudentVocabProgress.findOneAndUpdate(
        { studentId, lessonId: nextLesson._id },
        { $setOnInsert: { status: 'available', unlockedAt: new Date() } },
        { upsert: true }
      );
    }
  }

  await progress.save();

  return { score, correctCount, totalQuestions, passed, checkedAnswers, minPassScore: lesson.minPassScore };
};

const updatePracticeStats = async (studentId, lessonId, { attempts = 0, correct = 0 }) => {
  let progress = await StudentVocabProgress.findOne({ studentId, lessonId });
  if (!progress) {
    progress = new StudentVocabProgress({ studentId, lessonId, status: 'available', unlockedAt: new Date() });
  }
  progress.practiceAttempts += attempts;
  progress.practiceCorrect += correct;
  progress.lastPracticeDate = new Date();
  await progress.save();
  return progress;
};

module.exports = {
  listLessons,
  getLesson,
  createLesson,
  updateLesson,
  removeLesson,
  toggleExamLock,
  getStudentLessonTree,
  getExamWords,
  submitExam,
  updatePracticeStats,
};
