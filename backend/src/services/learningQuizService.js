const LearningQuiz = require('../models/LearningQuiz');
const LearningQuizAttempt = require('../models/LearningQuizAttempt');
const { getStudentGroupIds } = require('./examGateService');
const { softDelete } = require('./recycleBinService');

const notFound = (msg = 'Quiz not found') =>
  Object.assign(new Error(msg), { statusCode: 404, code: 'NOT_FOUND' });
const badRequest = (msg) => Object.assign(new Error(msg), { statusCode: 400, code: 'BAD_REQUEST' });
const forbidden = (msg) => Object.assign(new Error(msg), { statusCode: 403, code: 'FORBIDDEN' });

const normalizeAnswers = (list = []) =>
  list.map((a) => String(a || '').trim().toLowerCase()).filter(Boolean);

const formatQuestion = (q, { includeAnswers = false } = {}) => {
  const base = {
    id: String(q._id),
    type: q.type,
    prompt: q.prompt,
    options: q.options || [],
    points: q.points ?? 1,
  };
  if (!includeAnswers) return base;
  return {
    ...base,
    correctOptionIndex: q.correctOptionIndex ?? 0,
    answers: q.answers || [],
  };
};

const formatQuiz = (doc, { includeAnswers = false, unlocked = null } = {}) => ({
  id: String(doc._id),
  subjectId: String(doc.subjectId),
  title: doc.title,
  topic: doc.topic,
  level: doc.level,
  description: doc.description || '',
  published: !!doc.published,
  unlockedFor: (doc.unlockedFor || []).map((g) => String(g._id || g)),
  unlocked: unlocked == null ? undefined : !!unlocked,
  passingScore: doc.passingScore ?? 70,
  timeLimitMinutes: doc.timeLimitMinutes ?? 0,
  questionCount: (doc.questions || []).length,
  questions: (doc.questions || []).map((q) => formatQuestion(q, { includeAnswers })),
  createdBy: doc.createdBy ? String(doc.createdBy) : null,
  createdAt: doc.createdAt,
  updatedAt: doc.updatedAt,
});

const formatAttempt = (doc, { quiz = null } = {}) => ({
  id: String(doc._id),
  quizId: String(doc.quizId),
  subjectId: String(doc.subjectId),
  studentId: String(doc.studentId),
  status: doc.status,
  answers: doc.answers || [],
  scorePercent: doc.scorePercent ?? 0,
  pointsEarned: doc.pointsEarned ?? 0,
  pointsPossible: doc.pointsPossible ?? 0,
  passed: !!doc.passed,
  startedAt: doc.startedAt,
  submittedAt: doc.submittedAt,
  quiz: quiz ? formatQuiz(quiz, { includeAnswers: doc.status === 'submitted' }) : undefined,
});

const isUnlockedForGroups = (quiz, groupIds) =>
  (quiz.unlockedFor || []).some((g) => groupIds.includes(String(g._id || g)));

const sanitizeQuestions = (questions = []) => {
  if (!Array.isArray(questions)) throw badRequest('questions must be an array');
  return questions.map((raw, index) => {
    const type = raw.type === 'form_completion' ? 'form_completion' : 'mcq';
    const prompt = String(raw.prompt || '').trim();
    if (!prompt) throw badRequest(`Question ${index + 1}: prompt is required`);
    const points = Number(raw.points ?? 1);
    if (type === 'mcq') {
      const options = (raw.options || []).map((o) => String(o || '').trim()).filter(Boolean);
      if (options.length < 2) throw badRequest(`Question ${index + 1}: MCQ needs at least 2 options`);
      const correctOptionIndex = Number(raw.correctOptionIndex ?? 0);
      if (correctOptionIndex < 0 || correctOptionIndex >= options.length) {
        throw badRequest(`Question ${index + 1}: invalid correctOptionIndex`);
      }
      return { type, prompt, options, correctOptionIndex, answers: [], points };
    }
    const answers = normalizeAnswers(raw.answers || []);
    if (!answers.length) throw badRequest(`Question ${index + 1}: form_completion needs answers`);
    return { type, prompt, options: [], correctOptionIndex: 0, answers: raw.answers.map((a) => String(a).trim()), points };
  });
};

const listQuizzes = async ({ subjectId, level, topic, userType, studentId }) => {
  if (!subjectId) throw badRequest('subjectId is required');
  const filter = { subjectId };
  if (level) filter.level = level;
  if (topic) filter.topic = new RegExp(String(topic).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  if (userType === 'student') filter.published = true;

  const docs = await LearningQuiz.find(filter).sort({ level: 1, topic: 1, createdAt: -1 });
  let groupIds = [];
  if (userType === 'student' && studentId) {
    groupIds = await getStudentGroupIds(studentId);
  }

  return docs.map((doc) => {
    const unlocked = userType === 'student' ? isUnlockedForGroups(doc, groupIds) : true;
    return formatQuiz(doc, {
      includeAnswers: userType !== 'student',
      unlocked,
    });
  });
};

const getQuiz = async (id, { userType, studentId, includeAnswers } = {}) => {
  const doc = await LearningQuiz.findById(id);
  if (!doc) throw notFound();

  let unlocked = true;
  if (userType === 'student') {
    if (!doc.published) throw notFound();
    const groupIds = await getStudentGroupIds(studentId);
    unlocked = isUnlockedForGroups(doc, groupIds);
    if (!unlocked) throw forbidden('This quiz is locked for your group. Ask your teacher to unlock it.');
  }

  const showAnswers = includeAnswers != null ? includeAnswers : userType !== 'student';
  return formatQuiz(doc, { includeAnswers: showAnswers, unlocked });
};

const createQuiz = async (payload, teacherId) => {
  const subjectId = payload.subjectId;
  if (!subjectId) throw badRequest('subjectId is required');
  const title = String(payload.title || '').trim();
  const topic = String(payload.topic || '').trim();
  const level = String(payload.level || '').trim();
  if (!title || !topic || !level) throw badRequest('title, topic, and level are required');

  const doc = await LearningQuiz.create({
    subjectId,
    title,
    topic,
    level,
    description: String(payload.description || '').trim(),
    published: !!payload.published,
    unlockedFor: payload.unlockedFor || [],
    passingScore: Number(payload.passingScore ?? 70),
    timeLimitMinutes: Number(payload.timeLimitMinutes ?? 0),
    questions: sanitizeQuestions(payload.questions || []),
    createdBy: teacherId,
  });
  return formatQuiz(doc, { includeAnswers: true, unlocked: true });
};

const updateQuiz = async (id, payload) => {
  const doc = await LearningQuiz.findById(id);
  if (!doc) throw notFound();

  if (payload.title != null) doc.title = String(payload.title).trim();
  if (payload.topic != null) doc.topic = String(payload.topic).trim();
  if (payload.level != null) doc.level = String(payload.level).trim();
  if (payload.description != null) doc.description = String(payload.description).trim();
  if (payload.published != null) doc.published = !!payload.published;
  if (payload.passingScore != null) doc.passingScore = Number(payload.passingScore);
  if (payload.timeLimitMinutes != null) doc.timeLimitMinutes = Number(payload.timeLimitMinutes);
  if (payload.questions != null) doc.questions = sanitizeQuestions(payload.questions);
  if (payload.unlockedFor != null) doc.unlockedFor = payload.unlockedFor;

  await doc.save();
  return formatQuiz(doc, { includeAnswers: true, unlocked: true });
};

const removeQuiz = async (id, { deletedBy } = {}) => {
  const doc = await LearningQuiz.findById(id);
  if (!doc) throw notFound();
  await softDelete('learningquizzes', id, { deletedBy, moduleType: 'quiz' });
  return { id };
};

const toggleUnlock = async (id, { groupId, unlock }) => {
  if (!groupId) throw badRequest('groupId is required');
  const doc = await LearningQuiz.findById(id);
  if (!doc) throw notFound();

  const gid = String(groupId);
  const current = (doc.unlockedFor || []).map((g) => String(g));
  if (unlock) {
    if (!current.includes(gid)) doc.unlockedFor.push(groupId);
  } else {
    doc.unlockedFor = doc.unlockedFor.filter((g) => String(g) !== gid);
  }
  await doc.save();
  return formatQuiz(doc, { includeAnswers: true, unlocked: true });
};

const scoreAnswer = (question, answer = {}) => {
  const points = question.points ?? 1;
  if (question.type === 'mcq') {
    const selected = answer.selectedOptionIndex;
    const correct = selected != null && Number(selected) === Number(question.correctOptionIndex);
    return { correct, pointsAwarded: correct ? points : 0 };
  }
  const expected = normalizeAnswers(question.answers || []);
  const given = normalizeAnswers(answer.textAnswers || []);
  const correct =
    expected.length > 0 &&
    expected.length === given.length &&
    expected.every((exp, i) => exp === given[i]);
  return { correct, pointsAwarded: correct ? points : 0 };
};

const startAttempt = async ({ quizId, studentId }) => {
  const quiz = await LearningQuiz.findById(quizId);
  if (!quiz || !quiz.published) throw notFound();

  const groupIds = await getStudentGroupIds(studentId);
  if (!isUnlockedForGroups(quiz, groupIds)) {
    throw forbidden('This quiz is locked for your group. Ask your teacher to unlock it.');
  }

  const existing = await LearningQuizAttempt.findOne({
    quizId,
    studentId,
    status: 'in_progress',
  }).sort({ createdAt: -1 });
  if (existing) {
    return formatAttempt(existing, { quiz });
  }

  const attempt = await LearningQuizAttempt.create({
    quizId: quiz._id,
    subjectId: quiz.subjectId,
    studentId,
    status: 'in_progress',
    pointsPossible: (quiz.questions || []).reduce((sum, q) => sum + (q.points ?? 1), 0),
  });
  return formatAttempt(attempt, { quiz });
};

const submitAttempt = async ({ attemptId, studentId, answers }) => {
  const attempt = await LearningQuizAttempt.findById(attemptId);
  if (!attempt || String(attempt.studentId) !== String(studentId)) throw notFound('Attempt not found');
  if (attempt.status === 'submitted') {
    const quiz = await LearningQuiz.findById(attempt.quizId);
    return formatAttempt(attempt, { quiz });
  }

  const quiz = await LearningQuiz.findById(attempt.quizId);
  if (!quiz) throw notFound();

  const answerMap = new Map();
  for (const a of answers || []) {
    answerMap.set(String(a.questionId), a);
  }

  let earned = 0;
  let possible = 0;
  const scored = (quiz.questions || []).map((q) => {
    const raw = answerMap.get(String(q._id)) || {};
    const result = scoreAnswer(q, raw);
    possible += q.points ?? 1;
    earned += result.pointsAwarded;
    return {
      questionId: q._id,
      selectedOptionIndex: raw.selectedOptionIndex ?? null,
      textAnswers: raw.textAnswers || [],
      correct: result.correct,
      pointsAwarded: result.pointsAwarded,
    };
  });

  const scorePercent = possible > 0 ? Math.round((earned / possible) * 100) : 0;
  attempt.answers = scored;
  attempt.pointsEarned = earned;
  attempt.pointsPossible = possible;
  attempt.scorePercent = scorePercent;
  attempt.passed = scorePercent >= (quiz.passingScore ?? 70);
  attempt.status = 'submitted';
  attempt.submittedAt = new Date();
  await attempt.save();

  return formatAttempt(attempt, { quiz });
};

const getAttempt = async ({ attemptId, userType, userId }) => {
  const attempt = await LearningQuizAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (userType === 'student' && String(attempt.studentId) !== String(userId)) {
    throw forbidden('Not your attempt');
  }
  const quiz = await LearningQuiz.findById(attempt.quizId);
  return formatAttempt(attempt, { quiz });
};

const history = async ({ studentId, subjectId }) => {
  const filter = { studentId, status: 'submitted' };
  if (subjectId) filter.subjectId = subjectId;
  const docs = await LearningQuizAttempt.find(filter).sort({ submittedAt: -1 }).limit(50);
  const quizIds = [...new Set(docs.map((d) => String(d.quizId)))];
  const quizzes = await LearningQuiz.find({ _id: { $in: quizIds } });
  const byId = new Map(quizzes.map((q) => [String(q._id), q]));
  return docs.map((d) => formatAttempt(d, { quiz: byId.get(String(d.quizId)) }));
};

module.exports = {
  listQuizzes,
  getQuiz,
  createQuiz,
  updateQuiz,
  removeQuiz,
  toggleUnlock,
  startAttempt,
  submitAttempt,
  getAttempt,
  history,
};
