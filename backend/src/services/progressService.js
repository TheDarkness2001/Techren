const mongoose = require('mongoose');
const Student = require('../models/Student');
const ExamGroup = require('../models/ExamGroup');
const ClassSchedule = require('../models/ClassSchedule');
const Lesson = require('../models/Lesson');
const Level = require('../models/Level');
const Language = require('../models/Language');
const Sentence = require('../models/Sentence');
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

const resolveTeacherGroupIds = async (req) => {
  const teacherId = req.user._id;
  const branch = getBranchFilter(req);
  const [byTeachers, bySchedule] = await Promise.all([
    ExamGroup.find({ teachers: teacherId, ...branch }).select('_id'),
    ClassSchedule.find({
      teacher: teacherId,
      ...branch,
      subjectGroup: { $ne: null },
    }).select('subjectGroup'),
  ]);

  const ids = new Set();
  for (const group of byTeachers) ids.add(String(group._id));
  for (const schedule of bySchedule) {
    if (schedule.subjectGroup) ids.add(String(schedule.subjectGroup));
  }
  return [...ids];
};

const assertTeacherCanAccessGroup = async (req, group) => {
  if (req.userType !== 'teacher') return;
  // Founder / admin / manager can view any group in scope — no schedule assignment required.
  if (['founder', 'admin', 'manager'].includes(req.user.role)) return;
  const teacherId = String(req.user._id);
  const listed = (group.teachers || []).some((t) => String(t._id || t) === teacherId);
  if (listed) return;
  const linked = await ClassSchedule.exists({
    teacher: teacherId,
    subjectGroup: group._id,
    ...getBranchFilter(req),
  });
  if (!linked) {
    throw Object.assign(new Error('You can only view progress for your own groups'), {
      statusCode: 403,
      code: 'FORBIDDEN',
    });
  }
};

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

const buildGroupProgressReport = async (group) => {
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

  const subject = group.subject;
  const subjectId = subject && typeof subject === 'object'
    ? subject._id || subject.id
    : subject;
  const subjectName = subject && typeof subject === 'object' ? subject.name : undefined;

  return {
    group: {
      id: group._id,
      groupName: group.groupName,
      studentCount: group.students.length,
      subjectId: subjectId || null,
      subjectName: subjectName || null,
    },
    aggregate,
    students: summaries,
  };
};

const getGroupProgress = async (req, groupId) => {
  const group = await ExamGroup.findOne({ _id: groupId, ...getBranchFilter(req) })
    .populate('subject', 'name');
  if (!group) {
    throw Object.assign(new Error('Group not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  await assertTeacherCanAccessGroup(req, group);
  return buildGroupProgressReport(group);
};

const listMyGroupsProgress = async (req) => {
  if (req.userType !== 'teacher') {
    throw Object.assign(new Error('Only teachers can load their group progress'), {
      statusCode: 403,
      code: 'FORBIDDEN',
    });
  }

  const groupIds = await resolveTeacherGroupIds(req);
  if (groupIds.length === 0) {
    return { items: [] };
  }

  const groups = await ExamGroup.find({
    _id: { $in: groupIds },
    ...getBranchFilter(req),
  })
    .populate('subject', 'name')
    .sort({ groupName: 1 });

  const items = await Promise.all(groups.map((group) => buildGroupProgressReport(group)));
  return { items };
};

const escapeRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const findLanguagesForSubject = async (subjectName) => {
  const needle = (subjectName || '').trim();
  const modules = ['words', 'sentences'];

  if (!needle) {
    return Language.find({ moduleType: { $in: modules } }).sort({ name: 1 });
  }

  const exact = await Language.find({
    moduleType: { $in: modules },
    name: new RegExp(`^${escapeRegex(needle)}$`, 'i'),
  }).sort({ name: 1 });
  if (exact.length) return exact;

  const partial = await Language.find({
    moduleType: { $in: modules },
    name: new RegExp(escapeRegex(needle), 'i'),
  }).sort({ name: 1 });
  if (partial.length) return partial;

  // Subject may be "English" while CMS languages use the same name under both modules,
  // or content may live under a single shared language set — fall back to all.
  return Language.find({ moduleType: { $in: modules } }).sort({ name: 1 });
};

const listLessonOptions = async (req) => {
  const subjectName = req.query.subject || '';
  const languages = await findLanguagesForSubject(subjectName);
  if (!languages.length) return { items: [] };

  const languageIds = languages.map((l) => l._id);
  const levels = await Level.find({ languageId: { $in: languageIds } }).sort({ name: 1 });
  if (!levels.length) return { items: [] };

  const levelMap = new Map(levels.map((l) => [String(l._id), l]));
  const languageMap = new Map(languages.map((l) => [String(l._id), l]));
  const lessons = await Lesson.find({
    levelId: { $in: levels.map((l) => l._id) },
    type: { $in: ['words', 'sentences'] },
  }).sort({ order: 1, name: 1 });

  const items = lessons.map((lesson) => {
    const level = levelMap.get(String(lesson.levelId));
    const language = level ? languageMap.get(String(level.languageId)) : null;
    const levelName = level?.name || 'Level';
    return {
      id: String(lesson._id),
      label: lesson.name,
      name: lesson.name,
      levelId: String(lesson.levelId),
      levelName,
      languageId: language ? String(language._id) : null,
      languageName: language?.name || null,
      moduleType: lesson.type || 'words',
      order: lesson.order ?? 0,
    };
  });

  return { items };
};

const buildGroupLessonHeader = (group, lesson, extra = {}) => {
  const subject = group.subject;
  const subjectName = subject && typeof subject === 'object' ? subject.name : null;
  return {
    group: {
      id: group._id,
      groupName: group.groupName,
      studentCount: group.students.length,
      subjectName,
    },
    lesson: {
      id: lesson._id,
      name: lesson.name,
      type: lesson.type,
      order: lesson.order ?? 0,
      wordCount: lesson.wordIds?.length ?? 0,
      ...extra,
    },
  };
};

const getGroupLessonProgress = async (req, groupId, lessonId) => {
  const group = await ExamGroup.findOne({ _id: groupId, ...getBranchFilter(req) })
    .populate('subject', 'name');
  if (!group) {
    throw Object.assign(new Error('Group not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  await assertTeacherCanAccessGroup(req, group);

  const lesson = await Lesson.findById(lessonId);
  if (!lesson) {
    throw Object.assign(new Error('Lesson not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }

  const students = await Student.find({ _id: { $in: group.students } })
    .select('name studentId status profileImage')
    .sort({ name: 1 });

  if (lesson.type === 'sentences') {
    const sentences = await Sentence.find({ lessonId: lesson._id }).select('_id');
    const sentenceIds = sentences.map((s) => s._id);
    const progressRows = sentenceIds.length
      ? await StudentSentenceProgress.find({
          studentId: { $in: group.students },
          sentenceId: { $in: sentenceIds },
        })
      : [];

    const byStudent = new Map();
    for (const row of progressRows) {
      const key = String(row.studentId);
      if (!byStudent.has(key)) byStudent.set(key, { attempts: 0, correct: 0 });
      const entry = byStudent.get(key);
      entry.attempts += row.attempts || 0;
      entry.correct += row.correctCount || 0;
    }

    return {
      ...buildGroupLessonHeader(group, lesson, { sentenceCount: sentenceIds.length }),
      students: students.map((student) => {
        const stats = byStudent.get(String(student._id));
        const attempts = stats?.attempts ?? 0;
        const correct = stats?.correct ?? 0;
        const accuracy = attempts > 0 ? Math.round((correct / attempts) * 100) : 0;
        return {
          studentId: String(student._id),
          name: student.name,
          studentCode: student.studentId,
          status: attempts > 0 ? 'available' : 'locked',
          profileImage: student.profileImage || null,
          bestExamScore: accuracy,
          examAttempts: 0,
          practiceAttempts: attempts,
          practiceCorrect: correct,
          wordsMemorized: 0,
          wordsTotal: sentenceIds.length,
          lastExamDate: null,
          lastPracticeDate: null,
        };
      }),
    };
  }

  const records = await StudentVocabProgress.find({
    lessonId,
    studentId: { $in: group.students },
  });
  const recordMap = new Map(records.map((r) => [String(r.studentId), r]));
  const wordCount = lesson.wordIds?.length ?? 0;

  return {
    ...buildGroupLessonHeader(group, lesson),
    students: students.map((student) => {
      const record = recordMap.get(String(student._id));
      return {
        studentId: String(student._id),
        name: student.name,
        studentCode: student.studentId,
        status: record?.status || 'locked',
        profileImage: student.profileImage || null,
        bestExamScore: record?.bestExamScore ?? 0,
        examAttempts: record?.examAttempts ?? 0,
        practiceAttempts: record?.practiceAttempts ?? 0,
        practiceCorrect: record?.practiceCorrect ?? 0,
        wordsMemorized: record?.wordsMemorized ?? 0,
        wordsTotal: record?.wordsTotal ?? wordCount,
        lastExamDate: record?.lastExamDate || null,
        lastPracticeDate: record?.lastPracticeDate || null,
      };
    }),
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
  listMyGroupsProgress,
  listLessonOptions,
  getGroupLessonProgress,
  getLessonStudentProgress,
  getStudentVocabLessonDetails,
};
