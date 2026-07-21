const TopicTest = require('../models/TopicTest');
const StudentTestResult = require('../models/StudentTestResult');
const StudentVideoProgress = require('../models/StudentVideoProgress');
const VideoLesson = require('../models/VideoLesson');
const Student = require('../models/Student');
const { normalizeText } = require('../utils/textNormalizer');

const normalize = (s) =>
  normalizeText(String(s || ''))
    .toLowerCase()
    .replace(/[.,!?;:"']/g, '')
    .replace(/\s+/g, ' ')
    .trim();

const isAnswerCorrect = (question, userAnswer) => {
  const { type, correctAnswer: correct } = question;
  if (type === 'multiple-choice') return String(userAnswer).trim() === String(correct).trim();
  if (type === 'true-false') return String(userAnswer).toLowerCase() === String(correct).toLowerCase();
  const ua = normalize(userAnswer);
  if (Array.isArray(correct)) return correct.some((c) => normalize(c) === ua);
  return normalize(correct) === ua;
};

const stripAnswersForStudent = (test) => {
  if (!test) return null;
  const plain = test.toObject ? test.toObject() : { ...test };
  return {
    id: plain._id,
    videoLessonId: plain.videoLessonId,
    title: plain.title,
    practiceEnabled: plain.practiceEnabled,
    examEnabled: plain.examEnabled,
    timerSeconds: plain.timerSeconds,
    passingScore: plain.passingScore,
    randomizeQuestions: plain.randomizeQuestions,
    questions: (plain.questions || []).map((q) => ({
      id: q._id,
      type: q.type,
      question: q.question,
      options: q.options || [],
      points: q.points || 1,
    })),
  };
};

const formatTestForStaff = (test) => {
  if (!test) return null;
  const plain = test.toObject ? test.toObject() : { ...test };
  return {
    id: plain._id,
    videoLessonId: plain.videoLessonId,
    title: plain.title,
    practiceEnabled: plain.practiceEnabled,
    examEnabled: plain.examEnabled,
    timerSeconds: plain.timerSeconds,
    passingScore: plain.passingScore,
    randomizeQuestions: plain.randomizeQuestions,
    questions: plain.questions || [],
  };
};

const getTopicTest = async (videoLessonId, { userType, userId, mode, isStaff }) => {
  const test = await TopicTest.findOne({ videoLessonId });
  if (!test) return { test: null };

  if (userType === 'student' && mode === 'exam') {
    const video = await VideoLesson.findById(videoLessonId).lean();
    const progress = await StudentVideoProgress.findOne({ studentId: userId, videoLessonId }).lean();
    const needed = video?.requireWatchPercent ?? 70;
    const watched = progress?.watchPercent || 0;
    if (watched < needed) {
      throw Object.assign(
        new Error(`You must watch at least ${needed}% of the video before taking the exam.`),
        { statusCode: 403, code: 'WATCH_REQUIRED', watched }
      );
    }
  }

  if (isStaff && userType !== 'student') return { test: formatTestForStaff(test) };
  return { test: stripAnswersForStudent(test) };
};

const upsertTopicTest = async (videoLessonId, data) => {
  const questions = Array.isArray(data.questions) ? data.questions : [];
  for (const q of questions) {
    if (!q.type || !q.question || q.correctAnswer === undefined || q.correctAnswer === null) {
      throw Object.assign(new Error('Each question must have type, question, and correctAnswer'), {
        statusCode: 400,
        code: 'BAD_REQUEST',
      });
    }
  }
  const test = await TopicTest.findOneAndUpdate(
    { videoLessonId },
    { ...data, videoLessonId, questions },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );
  return formatTestForStaff(test);
};

const deleteTopicTest = async (videoLessonId) => {
  await TopicTest.deleteOne({ videoLessonId });
  return { deleted: true };
};

const submitTestAttempt = async (videoLessonId, studentId, { mode, answers = [], terminated = false, warnings = 0 }) => {
  if (!['practice', 'exam'].includes(mode)) {
    throw Object.assign(new Error('Invalid mode'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const test = await TopicTest.findOne({ videoLessonId });
  if (!test) throw Object.assign(new Error('Test not found'), { statusCode: 404, code: 'NOT_FOUND' });

  const answerMap = new Map(answers.map((a) => [String(a.questionId), a.answer]));
  let correctCount = 0;
  const answerLog = test.questions.map((q) => {
    const ua = answerMap.has(String(q._id)) ? answerMap.get(String(q._id)) : null;
    const ok = ua !== null && ua !== undefined && ua !== '' ? isAnswerCorrect(q, ua) : false;
    if (ok) correctCount += 1;
    return { questionId: q._id, userAnswer: ua, isCorrect: ok };
  });

  const totalQuestions = test.questions.length || 1;
  const score = Math.round((correctCount / totalQuestions) * 100);
  const passed = score >= (test.passingScore || 70);

  let result = await StudentTestResult.findOne({ studentId, topicTestId: test._id, mode });
  if (!result) {
    result = new StudentTestResult({ studentId, topicTestId: test._id, videoLessonId, mode });
  }
  result.score = score;
  result.totalQuestions = totalQuestions;
  result.correctCount = correctCount;
  result.bestScore = Math.max(result.bestScore || 0, score);
  result.attempts = (result.attempts || 0) + 1;
  result.passed = passed;
  result.warnings = warnings;
  result.terminated = !!terminated;
  result.answers = answerLog;
  result.completedAt = new Date();
  await result.save();

  const feedback = answerLog.map((a) => {
    const q = test.questions.find((x) => String(x._id) === String(a.questionId));
    return {
      questionId: a.questionId,
      isCorrect: a.isCorrect,
      userAnswer: a.userAnswer,
      correctAnswer: mode === 'practice' ? q?.correctAnswer : undefined,
      explanation: mode === 'practice' ? q?.explanation : undefined,
    };
  });

  return { score, correctCount, totalQuestions, passed, bestScore: result.bestScore, attempts: result.attempts, feedback };
};

const recordAntiCheatWarning = async (videoLessonId, warnings = 0) => ({
  terminate: warnings >= 3,
  videoLessonId,
});

const getTestLeaderboard = async (videoLessonId) => {
  const test = await TopicTest.findOne({ videoLessonId }).lean();
  if (!test) return { leaderboard: [] };

  const results = await StudentTestResult.find({ topicTestId: test._id, mode: 'exam' })
    .sort({ bestScore: -1, attempts: 1 })
    .limit(50)
    .lean();

  const studentIds = results.map((r) => r.studentId);
  const students = await Student.find({ _id: { $in: studentIds } }).select('name studentId profileImage');
  const info = new Map(students.map((s) => [String(s._id), s]));

  const leaderboard = results.map((r, i) => {
    const student = info.get(String(r.studentId));
    return {
      rank: i + 1,
      studentId: r.studentId,
      name: student?.name || '-',
      studentCode: student?.studentId || '',
      profileImage: student?.profileImage || null,
      bestScore: r.bestScore,
      attempts: r.attempts,
      passed: r.passed,
    };
  });

  return { leaderboard };
};

module.exports = {
  getTopicTest,
  upsertTopicTest,
  deleteTopicTest,
  submitTestAttempt,
  recordAntiCheatWarning,
  getTestLeaderboard,
};
