const IeltsExam = require('../models/IeltsExam');
const IeltsSection = require('../models/IeltsSection');
const IeltsQuestion = require('../models/IeltsQuestion');
const IeltsAttempt = require('../models/IeltsAttempt');
const IeltsWritingReview = require('../models/IeltsWritingReview');
const { scoreObjectiveQuestions, meanBand } = require('./ieltsScoringService');
const { formatExamBundle } = require('./ieltsExamService');

const notFound = (msg = 'Not found') =>
  Object.assign(new Error(msg), { statusCode: 404, code: 'NOT_FOUND' });
const forbidden = (msg = 'Forbidden') =>
  Object.assign(new Error(msg), { statusCode: 403, code: 'FORBIDDEN' });
const badRequest = (msg) =>
  Object.assign(new Error(msg), { statusCode: 400, code: 'VALIDATION_ERROR' });

const timerSecondsForExam = (exam) => {
  const t = exam.timers || {};
  if (exam.mode === 'listening') return (t.listeningMinutes || 40) * 60;
  if (exam.mode === 'reading') return (t.readingMinutes || 60) * 60;
  if (exam.mode === 'writing') return (t.writingMinutes || 60) * 60;
  return (
    ((t.listeningMinutes || 40) + (t.readingMinutes || 60) + (t.writingMinutes || 60)) * 60
  );
};

const startAttempt = async (studentId, examId) => {
  const exam = await IeltsExam.findById(examId);
  if (!exam || !exam.published) throw notFound('Published exam not found');

  const existing = await IeltsAttempt.findOne({
    studentId,
    examId,
    status: 'in_progress',
  });
  if (existing) {
    const bundle = await formatExamBundle(exam, { includeAnswers: false });
    return { attempt: existing.toPublicJSON(), exam: bundle };
  }

  const sections = await IeltsSection.find({ examId }).sort({ order: 1 });
  const attempt = await IeltsAttempt.create({
    studentId,
    examId,
    subjectId: exam.subjectId,
    status: 'in_progress',
    currentSectionId: sections[0]?._id || null,
    sectionStartedAt: new Date(),
    remainingSeconds: timerSecondsForExam(exam),
    startedAt: new Date(),
  });

  const bundle = await formatExamBundle(exam, { includeAnswers: false });
  return { attempt: attempt.toPublicJSON(), exam: bundle };
};

const getAttempt = async (attemptId, studentId, { asStaff = false } = {}) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (!asStaff && String(attempt.studentId) !== String(studentId)) throw forbidden();
  const exam = await IeltsExam.findById(attempt.examId);
  if (!exam) throw notFound('Exam not found');
  const includeAnswers = attempt.status !== 'in_progress' || asStaff;
  const bundle = await formatExamBundle(exam, { includeAnswers, includeAudioPath: asStaff });
  let writingReview = null;
  if (attempt.status !== 'in_progress') {
    writingReview = await IeltsWritingReview.findOne({ attemptId: attempt._id });
  }
  return {
    attempt: attempt.toPublicJSON({ includeKeys: includeAnswers }),
    exam: bundle,
    writingReview: writingReview ? writingReview.toPublicJSON() : null,
  };
};

const autosave = async (attemptId, studentId, body) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (String(attempt.studentId) !== String(studentId)) throw forbidden();
  if (attempt.status !== 'in_progress') throw badRequest('Attempt is locked');

  if (body.answers && typeof body.answers === 'object') {
    for (const [qid, val] of Object.entries(body.answers)) {
      attempt.answers.set(qid, val);
    }
  }
  if (body.flags && typeof body.flags === 'object') {
    for (const [qid, val] of Object.entries(body.flags)) {
      attempt.flags.set(qid, val === true);
    }
  }
  if (body.writingResponses && typeof body.writingResponses === 'object') {
    for (const [sid, text] of Object.entries(body.writingResponses)) {
      attempt.writingResponses.set(sid, String(text ?? ''));
    }
  }
  if (body.currentSectionId !== undefined) attempt.currentSectionId = body.currentSectionId;
  if (body.remainingSeconds !== undefined) attempt.remainingSeconds = body.remainingSeconds;
  if (body.audioPlayed === true) attempt.audioPlayed = true;
  attempt.autosaveAt = new Date();
  await attempt.save();
  return attempt.toPublicJSON();
};

const submitAttempt = async (attemptId, studentId) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (String(attempt.studentId) !== String(studentId)) throw forbidden();
  if (attempt.status !== 'in_progress') throw badRequest('Already submitted');

  const exam = await IeltsExam.findById(attempt.examId);
  const sections = await IeltsSection.find({ examId: attempt.examId }).sort({ order: 1 });
  const questions = await IeltsQuestion.find({ examId: attempt.examId }).sort({ order: 1 });

  const answersObj = {};
  if (attempt.answers) {
    for (const [k, v] of attempt.answers.entries()) answersObj[k] = v;
  }

  const listeningSectionIds = new Set(
    sections.filter((s) => s.skill === 'listening').map((s) => String(s._id))
  );
  const readingSectionIds = new Set(
    sections.filter((s) => s.skill === 'reading').map((s) => String(s._id))
  );

  const listeningQs = questions.filter((q) => listeningSectionIds.has(String(q.sectionId)));
  const readingQs = questions.filter((q) => readingSectionIds.has(String(q.sectionId)));

  const listeningScore = scoreObjectiveQuestions(listeningQs, answersObj);
  const readingScore = scoreObjectiveQuestions(readingQs, answersObj);

  const hasWriting = sections.some((s) => s.skill === 'writing');

  attempt.scores = {
    listeningRaw: listeningQs.length ? listeningScore.raw : null,
    listeningMax: listeningQs.length ? listeningScore.max : null,
    listeningBand: listeningQs.length ? listeningScore.band : null,
    readingRaw: readingQs.length ? readingScore.raw : null,
    readingMax: readingQs.length ? readingScore.max : null,
    readingBand: readingQs.length ? readingScore.band : null,
    writingBand: null,
    overallBand: meanBand(listeningScore.band, readingScore.band),
  };
  attempt.questionReview = [...listeningScore.review, ...readingScore.review];
  attempt.status = hasWriting ? 'submitted' : 'scored';
  attempt.submittedAt = new Date();
  attempt.remainingSeconds = 0;
  await attempt.save();

  return {
    attempt: attempt.toPublicJSON({ includeKeys: true }),
    exam: await formatExamBundle(exam, { includeAnswers: true }),
  };
};

const listHistory = async (studentId, { subjectId, page = 1, limit = 20 } = {}) => {
  const filter = { studentId, status: { $in: ['submitted', 'scored'] } };
  if (subjectId) filter.subjectId = subjectId;
  const skip = (Math.max(1, page) - 1) * limit;
  const [items, total] = await Promise.all([
    IeltsAttempt.find(filter).sort({ submittedAt: -1 }).skip(skip).limit(limit),
    IeltsAttempt.countDocuments(filter),
  ]);
  const examIds = [...new Set(items.map((a) => String(a.examId)))];
  const exams = await IeltsExam.find({ _id: { $in: examIds } });
  const examMap = new Map(exams.map((e) => [String(e._id), e.toPublicJSON()]));
  return {
    items: items.map((a) => ({
      ...a.toPublicJSON({ includeKeys: true }),
      exam: examMap.get(String(a.examId)) || null,
    })),
    meta: { page: Number(page), limit: Number(limit), total, totalPages: Math.ceil(total / limit) || 1 },
  };
};

const listWritingQueue = async ({ subjectId, page = 1, limit = 20 } = {}) => {
  const filter = { status: { $in: ['submitted', 'scored'] } };
  if (subjectId) filter.subjectId = subjectId;
  const attempts = await IeltsAttempt.find(filter).sort({ submittedAt: -1 }).limit(200);
  const withWriting = [];
  for (const a of attempts) {
    const hasText = a.writingResponses && [...a.writingResponses.values()].some((t) => String(t || '').trim());
    if (!hasText) continue;
    const review = await IeltsWritingReview.findOne({ attemptId: a._id });
    withWriting.push({
      attempt: a.toPublicJSON({ includeKeys: true }),
      writingReview: review ? review.toPublicJSON() : null,
      pending: !review,
    });
  }
  const pendingFirst = withWriting.sort((x, y) => Number(y.pending) - Number(x.pending));
  const start = (Math.max(1, page) - 1) * limit;
  const slice = pendingFirst.slice(start, start + limit);
  return {
    items: slice,
    meta: {
      page: Number(page),
      limit: Number(limit),
      total: pendingFirst.length,
      totalPages: Math.ceil(pendingFirst.length / limit) || 1,
    },
  };
};

const upsertWritingReview = async (attemptId, teacherId, body) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (attempt.status === 'in_progress') throw badRequest('Attempt not submitted');

  const criteria = {
    taskAchievement: Number(body.taskAchievement),
    coherenceCohesion: Number(body.coherenceCohesion),
    lexicalResource: Number(body.lexicalResource),
    grammaticalRange: Number(body.grammaticalRange),
  };
  for (const [k, v] of Object.entries(criteria)) {
    if (Number.isNaN(v) || v < 0 || v > 9) throw badRequest(`Invalid ${k}`);
  }
  const overallBand = IeltsWritingReview.computeOverall(criteria);

  let review = await IeltsWritingReview.findOne({ attemptId });
  if (!review) {
    review = new IeltsWritingReview({ attemptId, teacherId });
  }
  Object.assign(review, criteria, {
    teacherId,
    overallBand,
    comments: body.comments || '',
    corrections: body.corrections || '',
  });
  await review.save();

  attempt.scores.writingBand = overallBand;
  attempt.scores.overallBand = meanBand(
    attempt.scores.listeningBand,
    attempt.scores.readingBand,
    overallBand
  );
  attempt.status = 'scored';
  await attempt.save();

  return {
    writingReview: review.toPublicJSON(),
    attempt: attempt.toPublicJSON({ includeKeys: true }),
  };
};

module.exports = {
  startAttempt,
  getAttempt,
  autosave,
  submitAttempt,
  listHistory,
  listWritingQueue,
  upsertWritingReview,
};
