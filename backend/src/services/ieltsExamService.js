const path = require('path');
const fs = require('fs');
const jwt = require('jsonwebtoken');
const config = require('../config');
const IeltsExam = require('../models/IeltsExam');
const IeltsSection = require('../models/IeltsSection');
const IeltsQuestion = require('../models/IeltsQuestion');
const { getUploadsRoot } = require('../config/paths');
const recycleBinService = require('./recycleBinService');

const notFound = (msg = 'Not found') =>
  Object.assign(new Error(msg), { statusCode: 404, code: 'NOT_FOUND' });

const formatExamBundle = async (exam, { includeAnswers = false, includeAudioPath = false, includeTranscript = false } = {}) => {
  const sections = await IeltsSection.find({ examId: exam._id }).sort({ order: 1 });
  const sectionIds = sections.map((s) => s._id);
  const questions = await IeltsQuestion.find({ sectionId: { $in: sectionIds } }).sort({ order: 1, number: 1 });
  const bySection = new Map();
  for (const q of questions) {
    const key = String(q.sectionId);
    if (!bySection.has(key)) bySection.set(key, []);
    bySection.get(key).push(q.toPublicJSON({ includeAnswers }));
  }

  return {
    ...exam.toPublicJSON(),
    sections: sections.map((s) => ({
      ...s.toPublicJSON({ includeAudioPath, includeTranscript: includeTranscript || includeAnswers }),
      questions: bySection.get(String(s._id)) || [],
    })),
  };
};

/** Auto-publish exams whose publishAt has passed */
const applyScheduledPublishes = async () => {
  const now = new Date();
  await IeltsExam.updateMany(
    {
      published: false,
      archived: { $ne: true },
      publishAt: { $ne: null, $lte: now },
    },
    { $set: { published: true } }
  );
};

const listExams = async ({
  subjectId,
  mode,
  publishedOnly = false,
  includeArchived = false,
} = {}) => {
  await applyScheduledPublishes();
  const filter = {};
  if (subjectId) filter.subjectId = subjectId;
  if (mode) filter.mode = mode;
  if (publishedOnly) {
    filter.published = true;
    filter.archived = { $ne: true };
  } else if (!includeArchived) {
    filter.archived = { $ne: true };
  }
  const exams = await IeltsExam.find(filter).sort({ updatedAt: -1 });
  return exams.map((e) => e.toPublicJSON());
};

const getExam = async (id, opts = {}) => {
  const exam = await IeltsExam.findById(id);
  if (!exam) throw notFound('Exam not found');
  return formatExamBundle(exam, opts);
};

const createExam = async (body, createdBy) => {
  const exam = await IeltsExam.create({
    subjectId: body.subjectId,
    title: body.title,
    description: body.description || '',
    mode: body.mode || 'full',
    trainingType: body.trainingType || 'academic',
    difficulty: body.difficulty || 'official',
    timers: body.timers || {},
    published: body.published === true,
    archived: body.archived === true,
    publishAt: body.publishAt ? new Date(body.publishAt) : null,
    createdBy,
  });
  return exam.toPublicJSON();
};

const updateExam = async (id, body) => {
  const exam = await IeltsExam.findById(id);
  if (!exam) throw notFound('Exam not found');
  const fields = [
    'title',
    'description',
    'mode',
    'trainingType',
    'difficulty',
    'published',
    'archived',
    'timers',
    'subjectId',
  ];
  for (const f of fields) {
    if (body[f] !== undefined) exam[f] = body[f];
  }
  if (body.publishAt !== undefined) {
    exam.publishAt = body.publishAt ? new Date(body.publishAt) : null;
  }
  await exam.save();
  return exam.toPublicJSON();
};

const removeExam = async (id, deletedBy) => {
  const exam = await IeltsExam.findById(id);
  if (!exam) throw notFound('Exam not found');
  const by = deletedBy ? String(deletedBy) : 'staff';
  await recycleBinService.softDelete('ieltsexams', id, {
    deletedBy: by,
    moduleType: 'ielts',
  });
  await IeltsSection.updateMany(
    { examId: id },
    { $set: { isDeleted: true, deletedAt: new Date(), deletedBy: by } }
  );
  await IeltsQuestion.updateMany(
    { examId: id },
    { $set: { isDeleted: true, deletedAt: new Date(), deletedBy: by } }
  );
  return { id, deleted: true };
};

const createSection = async (examId, body, file) => {
  const exam = await IeltsExam.findById(examId);
  if (!exam) throw notFound('Exam not found');
  const count = await IeltsSection.countDocuments({ examId });
  const section = await IeltsSection.create({
    examId,
    skill: body.skill,
    order: body.order != null ? Number(body.order) : count,
    title: body.title || '',
    instructions: body.instructions || '',
    part: body.part != null && body.part !== '' ? Number(body.part) : null,
    transcript: body.transcript || '',
    sourceId: body.sourceId || null,
    passage: body.passage || '',
    passageFormat: body.passageFormat === 'html' ? 'html' : 'plain',
    answerHighlights: body.answerHighlights || '',
    prompt: body.prompt || '',
    imageUrl: body.imageUrl || null,
    writingTask: body.writingTask || null,
    minWords: body.minWords != null ? Number(body.minWords) : body.skill === 'writing' ? (body.writingTask === 'task2' ? 250 : 150) : 0,
    speakingPrompt: body.speakingPrompt || body.prompt || '',
    speakingPart: body.speakingPart != null ? Number(body.speakingPart) : 2,
    audioFile: file ? path.basename(file.path) : body.audioFile || null,
  });
  return section.toPublicJSON({ includeAudioPath: true, includeTranscript: true });
};

const updateSection = async (sectionId, body, file) => {
  const section = await IeltsSection.findById(sectionId);
  if (!section) throw notFound('Section not found');
  const fields = [
    'skill',
    'order',
    'title',
    'instructions',
    'part',
    'transcript',
    'sourceId',
    'passage',
    'passageFormat',
    'answerHighlights',
    'prompt',
    'imageUrl',
    'writingTask',
    'minWords',
    'speakingPrompt',
    'speakingPart',
  ];
  for (const f of fields) {
    if (body[f] !== undefined) {
      if (f === 'part') {
        section.part = body.part === null || body.part === '' ? null : Number(body.part);
      } else if (f === 'sourceId') {
        section.sourceId = body.sourceId || null;
      } else if (f === 'passageFormat') {
        section.passageFormat = body.passageFormat === 'html' ? 'html' : 'plain';
      } else if (f === 'speakingPart') {
        section.speakingPart = body.speakingPart == null || body.speakingPart === ''
          ? 2
          : Number(body.speakingPart);
      } else {
        section[f] = body[f];
      }
    }
  }
  if (file) {
    if (section.audioFile) {
      const old = path.join(getUploadsRoot(), 'ielts', section.audioFile);
      if (fs.existsSync(old)) fs.unlinkSync(old);
    }
    section.audioFile = path.basename(file.path);
  }
  await section.save();
  return section.toPublicJSON({ includeAudioPath: true, includeTranscript: true });
};

const removeSection = async (sectionId, deletedBy) => {
  const section = await IeltsSection.findById(sectionId);
  if (!section) throw notFound('Section not found');
  section.isDeleted = true;
  section.deletedAt = new Date();
  section.deletedBy = deletedBy ? String(deletedBy) : null;
  await section.save();
  await IeltsQuestion.updateMany(
    { sectionId },
    { $set: { isDeleted: true, deletedAt: new Date(), deletedBy: section.deletedBy } }
  );
  return { id: sectionId, deleted: true };
};

const createQuestion = async (sectionId, body) => {
  const section = await IeltsSection.findById(sectionId);
  if (!section) throw notFound('Section not found');
  const count = await IeltsQuestion.countDocuments({ sectionId });
  const question = await IeltsQuestion.create({
    sectionId,
    examId: section.examId,
    order: body.order != null ? Number(body.order) : count,
    number: body.number != null ? Number(body.number) : count + 1,
    type: body.type,
    prompt: body.prompt || '',
    instruction: body.instruction || '',
    options: body.options || [],
    answers: body.answers || [],
    acceptedAnswers: body.acceptedAnswers || undefined,
    blanks: body.blanks || undefined,
    wordLimit: body.wordLimit || null,
    allowArticles: body.allowArticles === true,
    allowPlurals: body.allowPlurals === true,
    selectionMode: body.selectionMode || 'single',
    matchingStyle: body.matchingStyle || 'dropdown',
    contentHtml: body.contentHtml || '',
    layout: body.layout || 'default',
    points: body.points != null ? Number(body.points) : 1,
    metadata: body.metadata || {},
    bankVersionId: body.bankVersionId || null,
  });
  return question.toPublicJSON({ includeAnswers: true });
};

const updateQuestion = async (questionId, body) => {
  const question = await IeltsQuestion.findById(questionId);
  if (!question) throw notFound('Question not found');
  const fields = [
    'order',
    'number',
    'type',
    'prompt',
    'instruction',
    'options',
    'answers',
    'acceptedAnswers',
    'blanks',
    'wordLimit',
    'allowArticles',
    'allowPlurals',
    'selectionMode',
    'matchingStyle',
    'contentHtml',
    'layout',
    'points',
    'metadata',
    'bankVersionId',
  ];
  for (const f of fields) {
    if (body[f] !== undefined) question[f] = body[f];
  }
  await question.save();
  return question.toPublicJSON({ includeAnswers: true });
};

const duplicateExam = async (examId, createdBy, { titleSuffix = ' (Copy)' } = {}) => {
  const exam = await IeltsExam.findById(examId);
  if (!exam) throw notFound('Exam not found');
  const clone = await IeltsExam.create({
    subjectId: exam.subjectId,
    title: `${exam.title}${titleSuffix}`,
    description: exam.description,
    mode: exam.mode,
    trainingType: exam.trainingType,
    difficulty: exam.difficulty,
    timers: exam.timers,
    published: false,
    archived: false,
    publishAt: null,
    createdBy,
  });
  const sections = await IeltsSection.find({ examId }).sort({ order: 1 });
  for (const s of sections) {
    const newSection = await IeltsSection.create({
      examId: clone._id,
      skill: s.skill,
      order: s.order,
      title: s.title,
      instructions: s.instructions,
      part: s.part,
      transcript: s.transcript,
      sourceId: s.sourceId,
      audioFile: s.audioFile,
      passage: s.passage,
      passageFormat: s.passageFormat,
      answerHighlights: s.answerHighlights,
      prompt: s.prompt,
      imageUrl: s.imageUrl,
      writingTask: s.writingTask,
      minWords: s.minWords,
      speakingPrompt: s.speakingPrompt,
      speakingPart: s.speakingPart,
    });
    const questions = await IeltsQuestion.find({ sectionId: s._id }).sort({ order: 1 });
    for (const q of questions) {
      await IeltsQuestion.create({
        sectionId: newSection._id,
        examId: clone._id,
        order: q.order,
        number: q.number,
        type: q.type,
        prompt: q.prompt,
        instruction: q.instruction,
        options: q.options,
        answers: q.answers,
        acceptedAnswers: q.acceptedAnswers,
        blanks: q.blanks,
        wordLimit: q.wordLimit,
        allowArticles: q.allowArticles,
        allowPlurals: q.allowPlurals,
        selectionMode: q.selectionMode,
        matchingStyle: q.matchingStyle,
        contentHtml: q.contentHtml,
        layout: q.layout,
        points: q.points,
        metadata: q.metadata,
        bankVersionId: q.bankVersionId,
      });
    }
  }
  return formatExamBundle(clone, { includeAnswers: true, includeAudioPath: true, includeTranscript: true });
};

const duplicateSection = async (sectionId) => {
  const section = await IeltsSection.findById(sectionId);
  if (!section) throw notFound('Section not found');
  const count = await IeltsSection.countDocuments({ examId: section.examId });
  const newSection = await IeltsSection.create({
    examId: section.examId,
    skill: section.skill,
    order: count,
    title: `${section.title || 'Section'} (Copy)`,
    instructions: section.instructions,
    part: section.part,
    transcript: section.transcript,
    sourceId: section.sourceId,
    audioFile: section.audioFile,
    passage: section.passage,
    passageFormat: section.passageFormat,
    answerHighlights: section.answerHighlights,
    prompt: section.prompt,
    imageUrl: section.imageUrl,
    writingTask: section.writingTask,
    minWords: section.minWords,
    speakingPrompt: section.speakingPrompt,
    speakingPart: section.speakingPart,
  });
  const questions = await IeltsQuestion.find({ sectionId }).sort({ order: 1 });
  for (const q of questions) {
    await IeltsQuestion.create({
      sectionId: newSection._id,
      examId: section.examId,
      order: q.order,
      number: q.number,
      type: q.type,
      prompt: q.prompt,
      instruction: q.instruction,
      options: q.options,
      answers: q.answers,
      acceptedAnswers: q.acceptedAnswers,
      blanks: q.blanks,
      wordLimit: q.wordLimit,
      allowArticles: q.allowArticles,
      allowPlurals: q.allowPlurals,
      selectionMode: q.selectionMode,
      matchingStyle: q.matchingStyle,
      contentHtml: q.contentHtml,
      layout: q.layout,
      points: q.points,
      metadata: q.metadata,
      bankVersionId: q.bankVersionId,
    });
  }
  return formatExamBundle(await IeltsExam.findById(section.examId), {
    includeAnswers: true,
    includeAudioPath: true,
    includeTranscript: true,
  });
};

const exportExamJson = async (examId) => {
  const exam = await IeltsExam.findById(examId);
  if (!exam) throw notFound('Exam not found');
  const bundle = await formatExamBundle(exam, {
    includeAnswers: true,
    includeAudioPath: true,
    includeTranscript: true,
  });
  return {
    schema: 'techren.ielts.exam.v1',
    exportedAt: new Date().toISOString(),
    exam: bundle,
  };
};

const importExamJson = async (payload, createdBy, { subjectId, strictReading = true } = {}) => {
  const { isReadingGeneratorPayload, mapReadingGeneratorToExam } = require('./ieltsReadingGeneratorImport');

  let data = payload.exam || payload;
  if (isReadingGeneratorPayload(payload)) {
    data = mapReadingGeneratorToExam(payload, { subjectId, strict: strictReading !== false });
  }

  if (!data || !data.title) {
    throw Object.assign(new Error('Invalid exam import payload'), {
      statusCode: 400,
      code: 'BAD_REQUEST',
    });
  }
  if (!subjectId && !data.subjectId) {
    throw Object.assign(new Error('subjectId is required to import an exam'), {
      statusCode: 400,
      code: 'BAD_REQUEST',
    });
  }

  const exam = await IeltsExam.create({
    subjectId: subjectId || data.subjectId,
    title: data.title,
    description: data.description || '',
    mode: data.mode || 'full',
    trainingType: data.trainingType || 'academic',
    difficulty: data.difficulty || 'official',
    timers: data.timers || {},
    published: false,
    archived: false,
    createdBy,
  });
  for (const [si, s] of (data.sections || []).entries()) {
    const newSection = await IeltsSection.create({
      examId: exam._id,
      skill: s.skill || 'reading',
      order: s.order != null ? s.order : si,
      title: s.title || '',
      instructions: s.instructions || '',
      part: s.part ?? null,
      transcript: s.transcript || '',
      sourceId: s.sourceId || null,
      audioFile: s.audioFile || null,
      passage: s.passage || '',
      passageFormat: s.passageFormat === 'html' ? 'html' : 'plain',
      answerHighlights: s.answerHighlights || '',
      prompt: s.prompt || '',
      imageUrl: s.imageUrl || null,
      writingTask: s.writingTask || null,
      minWords: s.minWords || 0,
      speakingPrompt: s.speakingPrompt || '',
      speakingPart: s.speakingPart != null ? Number(s.speakingPart) : 2,
    });
    for (const [qi, q] of (s.questions || []).entries()) {
      await IeltsQuestion.create({
        sectionId: newSection._id,
        examId: exam._id,
        order: q.order != null ? q.order : qi,
        number: q.number != null ? q.number : qi + 1,
        type: q.type,
        prompt: q.prompt || '',
        instruction: q.instruction || '',
        options: q.options || [],
        answers: q.answers || [],
        acceptedAnswers: q.acceptedAnswers || undefined,
        blanks: q.blanks || undefined,
        wordLimit: q.wordLimit || null,
        allowArticles: q.allowArticles === true,
        allowPlurals: q.allowPlurals === true,
        selectionMode: q.selectionMode || 'single',
        matchingStyle: q.matchingStyle || 'dropdown',
        contentHtml: q.contentHtml || '',
        layout: q.layout || 'default',
        points: q.points != null ? q.points : 1,
        metadata: q.metadata || {},
        bankVersionId: q.bankVersionId || null,
      });
    }
  }
  return formatExamBundle(exam, { includeAnswers: true, includeAudioPath: true, includeTranscript: true });
};

const exportExamCsvRows = async (examId) => {
  const exam = await IeltsExam.findById(examId);
  if (!exam) throw notFound('Exam not found');
  const sections = await IeltsSection.find({ examId }).sort({ order: 1 });
  const questions = await IeltsQuestion.find({ examId }).sort({ order: 1, number: 1 });
  const sectionMap = new Map(sections.map((s) => [String(s._id), s]));
  const rows = [
    [
      'sectionId',
      'skill',
      'sectionTitle',
      'questionNumber',
      'type',
      'prompt',
      'instruction',
      'options',
      'answers',
      'wordLimit',
      'points',
    ].join(','),
  ];
  const esc = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`;
  for (const q of questions) {
    const s = sectionMap.get(String(q.sectionId));
    rows.push(
      [
        esc(q.sectionId),
        esc(s?.skill),
        esc(s?.title),
        esc(q.number),
        esc(q.type),
        esc(q.prompt),
        esc(q.instruction),
        esc((q.options || []).join('|')),
        esc((q.answers || []).join('|')),
        esc(q.wordLimit),
        esc(q.points),
      ].join(',')
    );
  }
  return rows.join('\n');
};

const removeQuestion = async (questionId, deletedBy) => {
  const question = await IeltsQuestion.findById(questionId);
  if (!question) throw notFound('Question not found');
  question.isDeleted = true;
  question.deletedAt = new Date();
  question.deletedBy = deletedBy ? String(deletedBy) : null;
  await question.save();
  return { id: questionId, deleted: true };
};

const resolveAudioPath = async (sectionId) => {
  const section = await IeltsSection.findById(sectionId);
  if (!section || !section.audioFile) throw notFound('Audio not found');
  const filePath = path.join(getUploadsRoot(), 'ielts', section.audioFile);
  if (!fs.existsSync(filePath)) throw notFound('Audio file missing');
  return { section, filePath };
};

const createAudioAccessToken = (userId, sectionId) =>
  jwt.sign({ id: userId, sectionId, scope: 'ielts-audio' }, config.jwt.secret, { expiresIn: '30m' });

const verifyAudioAccessToken = (token, sectionId) => {
  const decoded = jwt.verify(token, config.jwt.secret);
  if (decoded.scope !== 'ielts-audio' || String(decoded.sectionId) !== String(sectionId)) {
    throw new Error('Invalid audio token');
  }
  return decoded;
};

module.exports = {
  listExams,
  getExam,
  createExam,
  updateExam,
  removeExam,
  createSection,
  updateSection,
  removeSection,
  createQuestion,
  updateQuestion,
  removeQuestion,
  duplicateExam,
  duplicateSection,
  exportExamJson,
  importExamJson,
  exportExamCsvRows,
  applyScheduledPublishes,
  formatExamBundle,
  resolveAudioPath,
  createAudioAccessToken,
  verifyAudioAccessToken,
};
