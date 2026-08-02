const path = require('path');
const fs = require('fs');
const IeltsExam = require('../models/IeltsExam');
const IeltsSection = require('../models/IeltsSection');
const IeltsQuestion = require('../models/IeltsQuestion');
const IeltsAttempt = require('../models/IeltsAttempt');
const IeltsWritingReview = require('../models/IeltsWritingReview');
const IeltsSpeakingReview = require('../models/IeltsSpeakingReview');
const { scoreObjectiveQuestions, meanBand } = require('./ieltsScoringService');
const { formatExamBundle, applyScheduledPublishes } = require('./ieltsExamService');
const { UPLOAD_DIR: SPEAKING_UPLOAD_DIR } = require('../middleware/ieltsSpeakingUpload');

const SKILL_ORDER = ['listening', 'reading', 'writing', 'speaking'];

const notFound = (msg = 'Not found') =>
  Object.assign(new Error(msg), { statusCode: 404, code: 'NOT_FOUND' });
const forbidden = (msg = 'Forbidden') =>
  Object.assign(new Error(msg), { statusCode: 403, code: 'FORBIDDEN' });
const badRequest = (msg) =>
  Object.assign(new Error(msg), { statusCode: 400, code: 'VALIDATION_ERROR' });

const skillsPresent = (sections) => {
  const set = new Set(sections.map((s) => s.skill));
  return SKILL_ORDER.filter((s) => set.has(s));
};

const timerSecondsForSkill = (exam, skill) => {
  const t = exam.timers || {};
  if (skill === 'listening') return (t.listeningMinutes || 40) * 60;
  if (skill === 'reading') return (t.readingMinutes || 60) * 60;
  if (skill === 'writing') return (t.writingMinutes || 60) * 60;
  if (skill === 'speaking') return (t.speakingMinutes || 14) * 60;
  return ((t.listeningMinutes || 40) + (t.readingMinutes || 60) + (t.writingMinutes || 60)) * 60;
};

const timerSecondsForExam = (exam, sections = []) => {
  if (exam.mode === 'full') {
    const skills = skillsPresent(sections);
    const first = skills[0] || 'listening';
    return timerSecondsForSkill(exam, first);
  }
  if (['listening', 'reading', 'writing', 'speaking'].includes(exam.mode)) {
    return timerSecondsForSkill(exam, exam.mode);
  }
  return timerSecondsForSkill(exam, 'listening');
};

const firstSectionForSkill = (sections, skill) =>
  sections.find((s) => s.skill === skill) || sections[0] || null;

const hasWritingContent = (attempt) =>
  Boolean(attempt.writingResponses && [...attempt.writingResponses.values()].some((t) => String(t || '').trim()));

const hasSpeakingContent = (attempt) =>
  Boolean(
    attempt.speakingRecordings &&
      [...attempt.speakingRecordings.values()].some((r) => r && r.filePath)
  );

const needsManualReview = (sections, attempt) => {
  const hasWritingSections = sections.some((s) => s.skill === 'writing');
  const hasSpeakingSections = sections.some((s) => s.skill === 'speaking');
  return (hasWritingSections && hasWritingContent(attempt)) || (hasSpeakingSections && hasSpeakingContent(attempt));
};

const recomputeAttemptStatus = async (attempt, sections) => {
  const writingReview = await IeltsWritingReview.findOne({ attemptId: attempt._id });
  const speakingReview = await IeltsSpeakingReview.findOne({ attemptId: attempt._id });
  const needsWriting = sections.some((s) => s.skill === 'writing') && hasWritingContent(attempt);
  const needsSpeaking = sections.some((s) => s.skill === 'speaking') && hasSpeakingContent(attempt);
  const writingDone = !needsWriting || Boolean(writingReview);
  const speakingDone = !needsSpeaking || Boolean(speakingReview);
  attempt.status = writingDone && speakingDone ? 'scored' : 'submitted';
};

const startAttempt = async (studentId, examId) => {
  await applyScheduledPublishes();
  const exam = await IeltsExam.findById(examId);
  if (!exam || !exam.published || exam.archived) throw notFound('Published exam not found');

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
  const skills = skillsPresent(sections);
  let currentSkill = null;
  if (exam.mode === 'full') {
    currentSkill = skills[0] || null;
  } else if (['listening', 'reading', 'writing', 'speaking'].includes(exam.mode)) {
    currentSkill = exam.mode;
  }
  const startSection = currentSkill
    ? firstSectionForSkill(sections, currentSkill)
    : sections[0] || null;

  const attempt = await IeltsAttempt.create({
    studentId,
    examId,
    subjectId: exam.subjectId,
    status: 'in_progress',
    currentSkill,
    completedSkills: [],
    currentSectionId: startSection?._id || null,
    sectionStartedAt: new Date(),
    remainingSeconds: timerSecondsForExam(exam, sections),
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
  let speakingReview = null;
  if (attempt.status !== 'in_progress') {
    writingReview = await IeltsWritingReview.findOne({ attemptId: attempt._id });
    speakingReview = await IeltsSpeakingReview.findOne({ attemptId: attempt._id });
  }
  return {
    attempt: attempt.toPublicJSON({ includeKeys: includeAnswers }),
    exam: bundle,
    writingReview: writingReview ? writingReview.toPublicJSON() : null,
    speakingReview: speakingReview ? speakingReview.toPublicJSON() : null,
  };
};

const autosave = async (attemptId, studentId, body) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (String(attempt.studentId) !== String(studentId)) throw forbidden();
  if (attempt.status !== 'in_progress') throw badRequest('Attempt is locked');

  const exam = await IeltsExam.findById(attempt.examId);
  const sections = await IeltsSection.find({ examId: attempt.examId }).sort({ order: 1 });

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
  if (body.currentSectionId !== undefined) {
    // Full Mock: only allow switching sections within the current skill.
    if (exam?.mode === 'full' && attempt.currentSkill) {
      const target = sections.find((s) => String(s._id) === String(body.currentSectionId));
      if (target && target.skill !== attempt.currentSkill) {
        throw badRequest('Cannot switch to a different skill during Full Mock');
      }
      if (attempt.completedSkills?.includes(target?.skill)) {
        throw badRequest('This skill is already finished');
      }
    }
    attempt.currentSectionId = body.currentSectionId;
  }
  if (body.remainingSeconds !== undefined) attempt.remainingSeconds = body.remainingSeconds;
  if (body.audioPlayed === true) attempt.audioPlayed = true;
  if (body.audioPlayedBySection && typeof body.audioPlayedBySection === 'object') {
    if (!attempt.audioPlayedBySection) attempt.audioPlayedBySection = new Map();
    for (const [sid, played] of Object.entries(body.audioPlayedBySection)) {
      if (played === true) {
        attempt.audioPlayedBySection.set(sid, true);
        attempt.audioPlayed = true;
      }
    }
  }
  if (body.playedSectionId) {
    if (!attempt.audioPlayedBySection) attempt.audioPlayedBySection = new Map();
    attempt.audioPlayedBySection.set(String(body.playedSectionId), true);
    attempt.audioPlayed = true;
  }
  if (body.audioAnalytics && typeof body.audioAnalytics === 'object') {
    if (!attempt.audioAnalytics) attempt.audioAnalytics = new Map();
    for (const [sid, stats] of Object.entries(body.audioAnalytics)) {
      const prev = attempt.audioAnalytics.get(sid) || {};
      attempt.audioAnalytics.set(sid, {
        playCount: Number(stats.playCount ?? prev.playCount ?? 0),
        listenedSeconds: Number(stats.listenedSeconds ?? prev.listenedSeconds ?? 0),
        completed: Boolean(stats.completed ?? prev.completed),
      });
    }
  }
  if (body.timePerQuestion && typeof body.timePerQuestion === 'object') {
    if (!attempt.timePerQuestion) attempt.timePerQuestion = new Map();
    for (const [qid, secs] of Object.entries(body.timePerQuestion)) {
      attempt.timePerQuestion.set(qid, Number(secs) || 0);
    }
  }
  attempt.autosaveAt = new Date();
  await attempt.save();
  return attempt.toPublicJSON();
};

const advanceSkill = async (attemptId, studentId) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (String(attempt.studentId) !== String(studentId)) throw forbidden();
  if (attempt.status !== 'in_progress') throw badRequest('Attempt is locked');

  const exam = await IeltsExam.findById(attempt.examId);
  if (!exam) throw notFound('Exam not found');
  if (exam.mode !== 'full') throw badRequest('advance-skill is only for Full Mock exams');

  const sections = await IeltsSection.find({ examId: attempt.examId }).sort({ order: 1 });
  const skills = skillsPresent(sections);
  const current = attempt.currentSkill || skills[0];
  if (!current) throw badRequest('No skills in this exam');

  if (current === 'speaking') {
    const speakingSections = sections.filter((s) => s.skill === 'speaking');
    const missing = speakingSections.some((s) => {
      const rec = attempt.speakingRecordings?.get(String(s._id));
      return !(rec && rec.filePath);
    });
    if (missing) throw badRequest('Record your speaking response before continuing');
  }

  const completed = new Set(attempt.completedSkills || []);
  completed.add(current);
  attempt.completedSkills = [...completed];

  const next = skills.find((s) => !completed.has(s));
  if (!next) {
    attempt.currentSkill = current;
    attempt.remainingSeconds = 0;
    await attempt.save();
    return { attempt: attempt.toPublicJSON(), finishedSkills: true, nextSkill: null };
  }

  attempt.currentSkill = next;
  attempt.remainingSeconds = timerSecondsForSkill(exam, next);
  attempt.sectionStartedAt = new Date();
  const nextSection = firstSectionForSkill(sections, next);
  attempt.currentSectionId = nextSection?._id || null;
  await attempt.save();

  return {
    attempt: attempt.toPublicJSON(),
    finishedSkills: false,
    nextSkill: next,
  };
};

const uploadSpeakingRecording = async (attemptId, studentId, sectionId, file, { durationSec } = {}) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (String(attempt.studentId) !== String(studentId)) throw forbidden();
  if (attempt.status !== 'in_progress') throw badRequest('Attempt is locked');
  if (!file) throw badRequest('Audio file is required');

  const section = await IeltsSection.findById(sectionId);
  if (!section || String(section.examId) !== String(attempt.examId)) {
    throw notFound('Speaking section not found');
  }
  if (section.skill !== 'speaking') throw badRequest('Section is not a speaking section');

  const exam = await IeltsExam.findById(attempt.examId);
  if (exam?.mode === 'full') {
    if (attempt.currentSkill !== 'speaking') {
      throw badRequest('Speaking is not the current Full Mock skill');
    }
    if (attempt.completedSkills?.includes('speaking')) {
      throw badRequest('Speaking skill already finished');
    }
  }

  if (!attempt.speakingRecordings) attempt.speakingRecordings = new Map();
  const existing = attempt.speakingRecordings.get(String(sectionId));
  if (existing?.filePath) {
    throw badRequest('Speaking already recorded for this topic (one recording only)');
  }

  const relative = path.join('speaking', path.basename(file.path)).replace(/\\/g, '/');
  attempt.speakingRecordings.set(String(sectionId), {
    filePath: relative,
    uploadedAt: new Date(),
    durationSec: durationSec != null ? Number(durationSec) : null,
  });
  attempt.autosaveAt = new Date();
  await attempt.save();
  return attempt.toPublicJSON();
};

const resolveSpeakingRecordingPath = async (attemptId, sectionId, requesterId, { asStaff = false } = {}) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (!asStaff && String(attempt.studentId) !== String(requesterId)) throw forbidden();

  const rec = attempt.speakingRecordings?.get(String(sectionId));
  if (!rec?.filePath) throw notFound('Speaking recording not found');

  const abs = path.join(SPEAKING_UPLOAD_DIR, path.basename(rec.filePath));
  if (!fs.existsSync(abs)) throw notFound('Speaking audio file missing');
  return { filePath: abs, attempt };
};

const submitAttempt = async (attemptId, studentId) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (String(attempt.studentId) !== String(studentId)) throw forbidden();
  if (attempt.status !== 'in_progress') throw badRequest('Already submitted');

  const exam = await IeltsExam.findById(attempt.examId);
  const sections = await IeltsSection.find({ examId: attempt.examId }).sort({ order: 1 });
  const questions = await IeltsQuestion.find({ examId: attempt.examId }).sort({ order: 1 });

  if (exam?.mode === 'full') {
    const skills = skillsPresent(sections);
    const completed = new Set(attempt.completedSkills || []);
    // Allow submit only when all skills except possibly the last finished via advance,
    // or when all skills are completed. If still mid-mock, require finishing skills first —
    // except timer expiry may call submit early: mark remaining as completed.
    for (const s of skills) completed.add(s);
    attempt.completedSkills = [...completed];
  }

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

  const listeningScore = scoreObjectiveQuestions(listeningQs, answersObj, {
    trainingType: exam?.trainingType || 'academic',
  });
  const readingScore = scoreObjectiveQuestions(readingQs, answersObj, {
    trainingType: exam?.trainingType || 'academic',
  });

  attempt.scores = {
    listeningRaw: listeningQs.length ? listeningScore.raw : null,
    listeningMax: listeningQs.length ? listeningScore.max : null,
    listeningBand: listeningQs.length ? listeningScore.band : null,
    readingRaw: readingQs.length ? readingScore.raw : null,
    readingMax: readingQs.length ? readingScore.max : null,
    readingBand: readingQs.length ? readingScore.band : null,
    writingBand: null,
    speakingBand: null,
    overallBand: meanBand(listeningScore.band, readingScore.band),
  };
  attempt.questionReview = [...listeningScore.review, ...readingScore.review];
  attempt.status = needsManualReview(sections, attempt) ? 'submitted' : 'scored';
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
    if (!hasWritingContent(a)) continue;
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

const listSpeakingQueue = async ({ subjectId, page = 1, limit = 20 } = {}) => {
  const filter = { status: { $in: ['submitted', 'scored'] } };
  if (subjectId) filter.subjectId = subjectId;
  const attempts = await IeltsAttempt.find(filter).sort({ submittedAt: -1 }).limit(200);
  const withSpeaking = [];
  for (const a of attempts) {
    if (!hasSpeakingContent(a)) continue;
    const review = await IeltsSpeakingReview.findOne({ attemptId: a._id });
    withSpeaking.push({
      attempt: a.toPublicJSON({ includeKeys: true }),
      speakingReview: review ? review.toPublicJSON() : null,
      pending: !review,
    });
  }
  const pendingFirst = withSpeaking.sort((x, y) => Number(y.pending) - Number(x.pending));
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

  const sections = await IeltsSection.find({ examId: attempt.examId });
  attempt.scores.writingBand = overallBand;
  const speakingReview = await IeltsSpeakingReview.findOne({ attemptId });
  attempt.scores.overallBand = meanBand(
    attempt.scores.listeningBand,
    attempt.scores.readingBand,
    overallBand,
    speakingReview ? speakingReview.overallBand : attempt.scores.speakingBand
  );
  await recomputeAttemptStatus(attempt, sections);
  await attempt.save();

  return {
    writingReview: review.toPublicJSON(),
    attempt: attempt.toPublicJSON({ includeKeys: true }),
  };
};

const upsertSpeakingReview = async (attemptId, teacherId, body) => {
  const attempt = await IeltsAttempt.findById(attemptId);
  if (!attempt) throw notFound('Attempt not found');
  if (attempt.status === 'in_progress') throw badRequest('Attempt not submitted');
  if (!hasSpeakingContent(attempt)) throw badRequest('No speaking recording on this attempt');

  const criteria = {
    fluencyCoherence: Number(body.fluencyCoherence),
    lexicalResource: Number(body.lexicalResource),
    grammaticalRange: Number(body.grammaticalRange),
    pronunciation: Number(body.pronunciation),
  };
  for (const [k, v] of Object.entries(criteria)) {
    if (Number.isNaN(v) || v < 0 || v > 9) throw badRequest(`Invalid ${k}`);
  }
  const overallBand = IeltsSpeakingReview.computeOverall(criteria);

  let review = await IeltsSpeakingReview.findOne({ attemptId });
  if (!review) {
    review = new IeltsSpeakingReview({ attemptId, teacherId });
  }
  Object.assign(review, criteria, {
    teacherId,
    overallBand,
    comments: body.comments || '',
  });
  await review.save();

  const sections = await IeltsSection.find({ examId: attempt.examId });
  attempt.scores.speakingBand = overallBand;
  attempt.scores.overallBand = meanBand(
    attempt.scores.listeningBand,
    attempt.scores.readingBand,
    attempt.scores.writingBand,
    overallBand
  );
  await recomputeAttemptStatus(attempt, sections);
  await attempt.save();

  return {
    speakingReview: review.toPublicJSON(),
    attempt: attempt.toPublicJSON({ includeKeys: true }),
  };
};

module.exports = {
  SKILL_ORDER,
  startAttempt,
  getAttempt,
  autosave,
  advanceSkill,
  uploadSpeakingRecording,
  resolveSpeakingRecordingPath,
  submitAttempt,
  listHistory,
  listWritingQueue,
  listSpeakingQueue,
  upsertWritingReview,
  upsertSpeakingReview,
};
