const IeltsSource = require('../models/IeltsSource');

const notFound = (msg = 'Source not found') =>
  Object.assign(new Error(msg), { statusCode: 404, code: 'NOT_FOUND' });

const listSources = async ({
  subjectId,
  kind,
  topic,
  status,
  q,
  includeArchived = false,
} = {}) => {
  const filter = {};
  if (subjectId) filter.subjectId = subjectId;
  if (kind) filter.kind = kind;
  if (topic) filter.topic = topic;
  if (status) {
    filter.status = status;
  } else if (!includeArchived) {
    filter.status = { $ne: 'archived' };
  }
  if (q && String(q).trim()) {
    const rx = new RegExp(String(q).trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
    filter.$or = [{ title: rx }, { author: rx }, { notes: rx }, { tags: rx }];
  }
  const items = await IeltsSource.find(filter).sort({ updatedAt: -1 }).limit(500);
  return items.map((s) => s.toPublicJSON());
};

const getSource = async (id) => {
  const source = await IeltsSource.findById(id);
  if (!source) throw notFound();
  return source.toPublicJSON();
};

const createSource = async (body, createdBy) => {
  const source = await IeltsSource.create({
    subjectId: body.subjectId || null,
    title: body.title,
    author: body.author || '',
    publisher: body.publisher || '',
    publication: body.publication || '',
    originalUrl: body.originalUrl || '',
    license: body.license || '',
    copyrightStatus: body.copyrightStatus || 'unknown',
    difficulty: body.difficulty || 'Medium',
    topic: body.topic || 'General',
    cefrLevel: body.cefrLevel || '',
    wordCount: body.wordCount != null ? Number(body.wordCount) : 0,
    durationSeconds: body.durationSeconds != null ? Number(body.durationSeconds) : 0,
    language: body.language || 'en',
    country: body.country || '',
    kind: body.kind || 'other',
    tags: Array.isArray(body.tags) ? body.tags : [],
    notes: body.notes || '',
    status: body.status || 'active',
    createdBy: createdBy || null,
  });
  return source.toPublicJSON();
};

const updateSource = async (id, body) => {
  const source = await IeltsSource.findById(id);
  if (!source) throw notFound();
  const fields = [
    'subjectId',
    'title',
    'author',
    'publisher',
    'publication',
    'originalUrl',
    'license',
    'copyrightStatus',
    'difficulty',
    'topic',
    'cefrLevel',
    'wordCount',
    'durationSeconds',
    'language',
    'country',
    'kind',
    'tags',
    'notes',
    'status',
  ];
  for (const f of fields) {
    if (body[f] !== undefined) source[f] = body[f];
  }
  if (body.title !== undefined || body.notes !== undefined) {
    source.version = (source.version || 1) + 1;
  }
  await source.save();
  return source.toPublicJSON();
};

const removeSource = async (id, deletedBy) => {
  const source = await IeltsSource.findById(id);
  if (!source) throw notFound();
  source.isDeleted = true;
  source.deletedAt = new Date();
  source.deletedBy = deletedBy ? String(deletedBy) : null;
  source.status = 'archived';
  await source.save();
  return { id, deleted: true };
};

module.exports = {
  listSources,
  getSource,
  createSource,
  updateSource,
  removeSource,
  TOPICS: IeltsSource.TOPICS,
  DIFFICULTIES: IeltsSource.DIFFICULTIES,
};
