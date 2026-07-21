const mongoose = require('mongoose');
const Student = require('../models/Student');
const ExamGroup = require('../models/ExamGroup');
const Lesson = require('../models/Lesson');
const HomeworkProgress = require('../models/HomeworkProgress');
const StudentVocabProgress = require('../models/StudentVocabProgress');
const StudentSentenceProgress = require('../models/StudentSentenceProgress');
const StudentListeningProgress = require('../models/StudentListeningProgress');
const StudentVideoProgress = require('../models/StudentVideoProgress');
const homeworkService = require('./homeworkService');
const sentenceService = require('./sentenceService');
const listeningService = require('./listeningService');
const gamificationService = require('./gamificationService');
const { getBranchFilter } = require('../utils/branchFilter');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

const resolveStudentId = async (req, studentId) => {
  if (req.userType === 'student') {
    return req.user._id;
  }

  if (!studentId) {
    throw Object.assign(new Error('studentId is required'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  const student = await Student.findOne({ _id: studentId, ...getBranchFilter(req) });
  if (!student) {
    throw Object.assign(new Error('Student not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  return student._id;
};

const summarizeSentenceProgress = async (studentId) => {
  const data = await sentenceService.getProgress(studentId);
  return {
    totalAttempts: data.totalAttempts,
    totalCorrect: data.totalCorrect,
    accuracy: data.accuracy,
    exercisesPracticed: data.items?.length ?? 0,
  };
};

const summarizeListeningProgress = async (studentId) => {
  const data = await listeningService.getProgress(studentId);
  return {
    totalAttempts: data.totalAttempts,
    avgBestAccuracy: data.avgBestAccuracy,
    exercisesPracticed: data.progress?.length ?? 0,
  };
};

const summarizeVideoProgress = async (studentId) => {
  const records = await StudentVideoProgress.find({ studentId });
  const completed = records.filter((r) => r.completed).length;
  const avgWatch = records.length > 0
    ? Math.round(records.reduce((sum, r) => sum + (r.watchPercent || 0), 0) / records.length)
    : 0;
  return {
    videosStarted: records.length,
    videosCompleted: completed,
    avgWatchPercent: avgWatch,
  };
};

const summarizeVocabLessons = async (studentId) => {
  const records = await StudentVocabProgress.find({ studentId });
  const passed = records.filter((r) => r.status === 'passed').length;
  const inProgress = records.filter((r) => r.status === 'available').length;
  return {
    lessonsTracked: records.length,
    lessonsPassed: passed,
    lessonsInProgress: inProgress,
    bestExamScores: records
      .filter((r) => r.bestExamScore > 0)
      .sort((a, b) => b.bestExamScore - a.bestExamScore)
      .slice(0, 5)
      .map((r) => ({
        lessonId: r.lessonId,
        bestExamScore: r.bestExamScore,
        practiceAttempts: r.practiceAttempts,
      })),
  };
};

const getOverview = async (req, studentIdParam) => {
  const studentId = await resolveStudentId(req, studentIdParam);
  const student = await Student.findById(studentId).select('name studentId email status branchId profileImage');

  const [words, sentences, listening, video, vocabLessons] = await Promise.all([
    homeworkService.getProgress(studentId),
    summarizeSentenceProgress(studentId),
    summarizeListeningProgress(studentId),
    summarizeVideoProgress(studentId),
    summarizeVocabLessons(studentId),
  ]);

  let gamification = null;
  try {
    const enabled = await gamificationService.isEnabled();
    if (enabled) {
      const profile = await gamificationService.getOrCreateProfile(studentId);
      gamification = gamificationService.formatProfile(profile);
    }
  } catch {
    gamification = null;
  }

  return {
    student: {
      id: student._id,
      name: student.name,
      studentCode: student.studentId,
      email: student.email,
      status: student.status,
      profileImage: student.profileImage,
    },
    modules: {
      words,
      sentences,
      listening,
      video,
      vocabLessons,
    },
    gamification,
  };
};

const buildStudentSummary = async (student) => {
  const studentId = student._id;
  const [words, sentences, listening, video, vocabLessons, gamificationDoc] = await Promise.all([
    HomeworkProgress.findOne({ studentId }).lean(),
    StudentSentenceProgress.find({ studentId }).lean(),
    StudentListeningProgress.find({ studentId }).lean(),
    StudentVideoProgress.find({ studentId }).lean(),
    StudentVocabProgress.find({ studentId }).lean(),
    gamificationService.getOrCreateProfile(studentId).catch(() => null),
  ]);

  const sentenceAttempts = sentences.reduce((sum, p) => sum + (p.attempts || 0), 0);
  const sentenceCorrect = sentences.reduce((sum, p) => sum + (p.correctCount || 0), 0);
  const listeningAttempts = listening.reduce((sum, p) => sum + (p.attempts || 0), 0);
  const videosCompleted = video.filter((v) => v.completed).length;

  return {
    studentId: String(studentId),
    name: student.name,
    studentCode: student.studentId,
    status: student.status,
    profileImage: student.profileImage,
    wordsAccuracy: words?.totalAttempts > 0
      ? Math.round((words.correctAnswers / words.totalAttempts) * 100)
      : 0,
    wordsAttempts: words?.totalAttempts ?? 0,
    sentencesAccuracy: sentenceAttempts > 0 ? Math.round((sentenceCorrect / sentenceAttempts) * 100) : 0,
    listeningExercises: listening.length,
    videosCompleted,
    lessonsPassed: vocabLessons.filter((v) => v.status === 'passed').length,
    totalXp: gamificationDoc?.totalXp ?? 0,
    level: gamificationDoc ? gamificationService.formatProfile(gamificationDoc).level : 1,
  };
};

const listStudentsProgress = async (req) => {
  const { page, limit, skip } = parsePagination(req.query);
  const filter = { ...getBranchFilter(req) };
  if (req.query.status) filter.status = req.query.status;
  if (req.query.search) {
    filter.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { email: { $regex: req.query.search, $options: 'i' } },
      { studentId: { $regex: req.query.search, $options: 'i' } },
    ];
  }

  const [students, total] = await Promise.all([
    Student.find(filter).sort({ name: 1 }).skip(skip).limit(limit),
    Student.countDocuments(filter),
  ]);

  const items = await Promise.all(students.map((s) => buildStudentSummary(s)));
  return { items, meta: buildPaginationMeta(page, limit, total) };
};

const getGroupProgress = async (req, groupId) => {
  const group = await ExamGroup.findOne({ _id: groupId, ...getBranchFilter(req) });
  if (!group) {
    throw Object.assign(new Error('Group not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const students = await Student.find({ _id: { $in: group.students } }).sort({ name: 1 });
  const summaries = await Promise.all(students.map((s) => buildStudentSummary(s)));

  const aggregate = {
    studentCount: summaries.length,
    avgWordsAccuracy: summaries.length > 0
      ? Math.round(summaries.reduce((sum, s) => sum + s.wordsAccuracy, 0) / summaries.length)
      : 0,
    avgSentencesAccuracy: summaries.length > 0
      ? Math.round(summaries.reduce((sum, s) => sum + s.sentencesAccuracy, 0) / summaries.length)
      : 0,
    totalLessonsPassed: summaries.reduce((sum, s) => sum + s.lessonsPassed, 0),
    totalXp: summaries.reduce((sum, s) => sum + s.totalXp, 0),
  };

  return {
    group: { id: group._id, groupName: group.groupName, studentCount: group.students.length },
    aggregate,
    students: summaries,
  };
};

const getLessonStudentProgress = async (req, lessonId) => {
  const lesson = await Lesson.findById(lessonId);
  if (!lesson) {
    throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const records = await StudentVocabProgress.find({ lessonId }).sort({ bestExamScore: -1 });
  const studentIds = records.map((r) => r.studentId);
  const students = await Student.find({ _id: { $in: studentIds }, ...getBranchFilter(req) }).select('name studentId status');
  const studentMap = new Map(students.map((s) => [String(s._id), s]));

  const items = records
    .filter((r) => studentMap.has(String(r.studentId)))
    .map((r) => {
      const student = studentMap.get(String(r.studentId));
      return {
        studentId: r.studentId,
        name: student.name,
        studentCode: student.studentId,
        status: r.status,
        bestExamScore: r.bestExamScore,
        examAttempts: r.examAttempts,
        practiceAttempts: r.practiceAttempts,
        practiceCorrect: r.practiceCorrect,
        lastExamDate: r.lastExamDate,
        lastPracticeDate: r.lastPracticeDate,
      };
    });

  return {
    lesson: { id: lesson._id, name: lesson.name, type: lesson.type, wordCount: lesson.wordIds?.length ?? 0 },
    students: items,
  };
};

const getStudentVocabLessonDetails = async (req, studentIdParam) => {
  const studentId = await resolveStudentId(req, studentIdParam);
  const records = await StudentVocabProgress.find({ studentId }).sort({ updatedAt: -1 });
  const lessonIds = records.map((r) => r.lessonId);
  const lessons = await Lesson.find({ _id: { $in: lessonIds } }).select('name order type');
  const lessonMap = new Map(lessons.map((l) => [String(l._id), l]));

  return {
    studentId: String(studentId),
    lessons: records.map((r) => {
      const lesson = lessonMap.get(String(r.lessonId));
      return {
        lessonId: r.lessonId,
        lessonName: lesson?.name ?? 'Lesson',
        lessonOrder: lesson?.order ?? 0,
        status: r.status,
        bestExamScore: r.bestExamScore,
        examAttempts: r.examAttempts,
        practiceAttempts: r.practiceAttempts,
        practiceCorrect: r.practiceCorrect,
        wordsMemorized: r.wordsMemorized,
        wordsTotal: r.wordsTotal,
      };
    }),
  };
};

module.exports = {
  getOverview,
  listStudentsProgress,
  getGroupProgress,
  getLessonStudentProgress,
  getStudentVocabLessonDetails,
};
