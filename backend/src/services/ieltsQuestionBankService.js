const IeltsQuestionBankItem = require('../models/IeltsQuestionBankItem');
const IeltsQuestionVersion = require('../models/IeltsQuestionVersion');
const IeltsQuestion = require('../models/IeltsQuestion');
const IeltsSection = require('../models/IeltsSection');

const notFound = (msg = 'Not found') =>
  Object.assign(new Error(msg), { statusCode: 404, code: 'NOT_FOUND' });

const badRequest = (msg) => Object.assign(new Error(msg), { statusCode: 400, code: 'BAD_REQUEST' });

const PAYLOAD_FIELDS = [
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
];

const extractPayload = (body = {}) => {
  const payload = {};
  for (const f of PAYLOAD_FIELDS) {
    if (body[f] !== undefined) payload[f] = body[f];
    else if (body.payload && body.payload[f] !== undefined) payload[f] = body.payload[f];
  }
  if (!payload.type && body.type) payload.type = body.type;
  if (payload.type == null) throw badRequest('Question type is required');
  if (payload.points == null) payload.points = 1;
  if (!payload.options) payload.options = [];
  if (!payload.answers) payload.answers = [];
  if (!payload.prompt) payload.prompt = '';
  if (!payload.metadata) payload.metadata = {};
  return payload;
};

const listBank = async ({ subjectId, skill, type, topic, status, q } = {}) => {
  const filter = {};
  if (subjectId) filter.subjectId = subjectId;
  if (skill) filter.skill = skill;
  if (type) filter.type = type;
  if (topic) filter.topic = topic;
  if (status) filter.status = status;
  else filter.status = { $ne: 'archived' };
  if (q && String(q).trim()) {
    filter.$or = [
      { title: new RegExp(String(q).trim(), 'i') },
      { tags: new RegExp(String(q).trim(), 'i') },
    ];
  }
  const items = await IeltsQuestionBankItem.find(filter).sort({ updatedAt: -1 }).limit(500);
  return items.map((i) => i.toPublicJSON());
};

const getBankItem = async (id, { includeVersions = true } = {}) => {
  const item = await IeltsQuestionBankItem.findById(id);
  if (!item) throw notFound('Bank item not found');
  const json = item.toPublicJSON();
  if (includeVersions) {
    const versions = await IeltsQuestionVersion.find({ bankItemId: id }).sort({ version: -1 });
    json.versions = versions.map((v) => v.toPublicJSON());
    const latest = versions[0];
    json.latestPayload = latest ? latest.payload : null;
  }
  return json;
};

const createBankItem = async (body, createdBy) => {
  const payload = extractPayload(body);
  const item = await IeltsQuestionBankItem.create({
    subjectId: body.subjectId || null,
    skill: body.skill || 'reading',
    type: payload.type,
    title: body.title || payload.prompt?.slice(0, 80) || 'Untitled',
    topic: body.topic || 'General',
    difficulty: body.difficulty || 'Medium',
    tags: Array.isArray(body.tags) ? body.tags : [],
    sourceId: body.sourceId || null,
    status: body.status || 'active',
    latestVersion: 1,
    createdBy: createdBy || null,
  });
  const version = await IeltsQuestionVersion.create({
    bankItemId: item._id,
    version: 1,
    payload,
    createdBy: createdBy || null,
  });
  return {
    ...item.toPublicJSON(),
    latestPayload: version.payload,
    versions: [version.toPublicJSON()],
  };
};

const updateBankItemMeta = async (id, body) => {
  const item = await IeltsQuestionBankItem.findById(id);
  if (!item) throw notFound('Bank item not found');
  const fields = ['title', 'topic', 'difficulty', 'tags', 'sourceId', 'status', 'skill', 'subjectId'];
  for (const f of fields) {
    if (body[f] !== undefined) item[f] = body[f];
  }
  await item.save();
  return item.toPublicJSON();
};

/** Create a new immutable version (does not mutate prior snapshots). */
const publishNewVersion = async (id, body, createdBy) => {
  const item = await IeltsQuestionBankItem.findById(id);
  if (!item) throw notFound('Bank item not found');
  const payload = extractPayload({ ...body, type: body.type || item.type });
  const next = (item.latestVersion || 1) + 1;
  const version = await IeltsQuestionVersion.create({
    bankItemId: item._id,
    version: next,
    payload,
    createdBy: createdBy || null,
  });
  item.latestVersion = next;
  item.type = payload.type;
  if (body.title !== undefined) item.title = body.title;
  await item.save();
  return version.toPublicJSON();
};

const getVersion = async (versionId) => {
  const version = await IeltsQuestionVersion.findById(versionId);
  if (!version) throw notFound('Version not found');
  return version.toPublicJSON();
};

/** Clone a frozen bank version into an exam section as a live question. */
const addVersionToSection = async (sectionId, versionId, overrides = {}) => {
  const section = await IeltsSection.findById(sectionId);
  if (!section) throw notFound('Section not found');
  const version = await IeltsQuestionVersion.findById(versionId);
  if (!version) throw notFound('Version not found');
  const p = version.payload || {};
  const count = await IeltsQuestion.countDocuments({ sectionId });
  const question = await IeltsQuestion.create({
    sectionId,
    examId: section.examId,
    order: overrides.order != null ? Number(overrides.order) : count,
    number: overrides.number != null ? Number(overrides.number) : count + 1,
    type: p.type,
    prompt: p.prompt || '',
    instruction: p.instruction || '',
    options: p.options || [],
    answers: p.answers || [],
    acceptedAnswers: p.acceptedAnswers || undefined,
    blanks: p.blanks || undefined,
    wordLimit: p.wordLimit || null,
    allowArticles: p.allowArticles === true,
    allowPlurals: p.allowPlurals === true,
    selectionMode: p.selectionMode || 'single',
    matchingStyle: p.matchingStyle || 'dropdown',
    contentHtml: p.contentHtml || '',
    layout: p.layout || 'default',
    points: p.points != null ? Number(p.points) : 1,
    metadata: p.metadata || {},
    bankVersionId: version._id,
  });
  return question.toPublicJSON({ includeAnswers: true });
};

/** Snapshot current exam question into the bank as v1. */
const importQuestionToBank = async (questionId, body = {}, createdBy) => {
  const question = await IeltsQuestion.findById(questionId);
  if (!question) throw notFound('Question not found');
  const payload = {};
  for (const f of PAYLOAD_FIELDS) {
    if (question[f] !== undefined) payload[f] = question[f];
  }
  return createBankItem(
    {
      subjectId: body.subjectId,
      skill: body.skill || 'reading',
      title: body.title || question.prompt?.slice(0, 80) || `Q${question.number}`,
      topic: body.topic || 'General',
      difficulty: body.difficulty || 'Medium',
      tags: body.tags || [],
      sourceId: body.sourceId || null,
      type: question.type,
      payload,
    },
    createdBy
  );
};

const removeBankItem = async (id, deletedBy) => {
  const item = await IeltsQuestionBankItem.findById(id);
  if (!item) throw notFound('Bank item not found');
  item.isDeleted = true;
  item.deletedAt = new Date();
  item.deletedBy = deletedBy ? String(deletedBy) : null;
  item.status = 'archived';
  await item.save();
  return { id, deleted: true };
};

module.exports = {
  listBank,
  getBankItem,
  createBankItem,
  updateBankItemMeta,
  publishNewVersion,
  getVersion,
  addVersionToSection,
  importQuestionToBank,
  removeBankItem,
};
