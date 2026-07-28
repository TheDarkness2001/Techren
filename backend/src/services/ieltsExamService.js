const path = require('path');
const fs = require('fs');
const IeltsExam = require('../models/IeltsExam');
const IeltsSection = require('../models/IeltsSection');
const IeltsQuestion = require('../models/IeltsQuestion');
const { getUploadsRoot } = require('../config/paths');

const notFound = (msg = 'Not found') =>
  Object.assign(new Error(msg), { statusCode: 404, code: 'NOT_FOUND' });

const formatExamBundle = async (exam, { includeAnswers = false, includeAudioPath = false } = {}) => {
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
      ...s.toPublicJSON({ includeAudioPath }),
      questions: bySection.get(String(s._id)) || [],
    })),
  };
};

const listExams = async ({ subjectId, mode, publishedOnly = false } = {}) => {
  const filter = {};
  if (subjectId) filter.subjectId = subjectId;
  if (mode) filter.mode = mode;
  if (publishedOnly) filter.published = true;
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
    createdBy,
  });
  return exam.toPublicJSON();
};

const updateExam = async (id, body) => {
  const exam = await IeltsExam.findById(id);
  if (!exam) throw notFound('Exam not found');
  const fields = ['title', 'description', 'mode', 'trainingType', 'difficulty', 'published', 'timers', 'subjectId'];
  for (const f of fields) {
    if (body[f] !== undefined) exam[f] = body[f];
  }
  await exam.save();
  return exam.toPublicJSON();
};

const removeExam = async (id, deletedBy) => {
  const exam = await IeltsExam.findById(id);
  if (!exam) throw notFound('Exam not found');
  exam.isDeleted = true;
  exam.deletedAt = new Date();
  exam.deletedBy = deletedBy ? String(deletedBy) : null;
  await exam.save();
  await IeltsSection.updateMany(
    { examId: id },
    { $set: { isDeleted: true, deletedAt: new Date(), deletedBy: exam.deletedBy } }
  );
  await IeltsQuestion.updateMany(
    { examId: id },
    { $set: { isDeleted: true, deletedAt: new Date(), deletedBy: exam.deletedBy } }
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
    passage: body.passage || '',
    prompt: body.prompt || '',
    imageUrl: body.imageUrl || null,
    writingTask: body.writingTask || null,
    minWords: body.minWords != null ? Number(body.minWords) : body.skill === 'writing' ? (body.writingTask === 'task2' ? 250 : 150) : 0,
    audioFile: file ? path.basename(file.path) : body.audioFile || null,
  });
  return section.toPublicJSON({ includeAudioPath: true });
};

const updateSection = async (sectionId, body, file) => {
  const section = await IeltsSection.findById(sectionId);
  if (!section) throw notFound('Section not found');
  const fields = ['skill', 'order', 'title', 'instructions', 'passage', 'prompt', 'imageUrl', 'writingTask', 'minWords'];
  for (const f of fields) {
    if (body[f] !== undefined) section[f] = body[f];
  }
  if (file) {
    if (section.audioFile) {
      const old = path.join(getUploadsRoot(), 'ielts', section.audioFile);
      if (fs.existsSync(old)) fs.unlinkSync(old);
    }
    section.audioFile = path.basename(file.path);
  }
  await section.save();
  return section.toPublicJSON({ includeAudioPath: true });
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
    options: body.options || [],
    answers: body.answers || [],
    points: body.points != null ? Number(body.points) : 1,
    metadata: body.metadata || {},
  });
  return question.toPublicJSON({ includeAnswers: true });
};

const updateQuestion = async (questionId, body) => {
  const question = await IeltsQuestion.findById(questionId);
  if (!question) throw notFound('Question not found');
  const fields = ['order', 'number', 'type', 'prompt', 'options', 'answers', 'points', 'metadata'];
  for (const f of fields) {
    if (body[f] !== undefined) question[f] = body[f];
  }
  await question.save();
  return question.toPublicJSON({ includeAnswers: true });
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
  formatExamBundle,
  resolveAudioPath,
};
