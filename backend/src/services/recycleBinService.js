const RecycleBin = require('../models/RecycleBin');
const Snapshot = require('../models/Snapshot');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const { getBranchFilter, canAccessBranch } = require('../utils/branchFilter');
const {
  Word,
  Sentence,
  Language,
  Level,
  Lesson,
  ListeningExercise,
  VideoLesson,
} = require('../models');

const MODEL_MAP = {
  words: Word,
  sentences: Sentence,
  languages: Language,
  levels: Level,
  lessons: Lesson,
  listeningexercises: ListeningExercise,
  videolessons: VideoLesson,
};

const MODULE_BY_COLLECTION = {
  words: 'words',
  sentences: 'sentences',
  languages: 'words',
  levels: 'words',
  lessons: 'words',
  listeningexercises: 'listening',
  videolessons: 'video',
};

const inferLabel = (snapshot, collectionName) => {
  if (!snapshot) return collectionName;
  if (collectionName === 'words') return `${snapshot.english || ''} / ${snapshot.uzbek || ''}`.trim();
  if (collectionName === 'sentences') return snapshot.english || snapshot.sentence || 'Sentence';
  if (collectionName === 'languages' || collectionName === 'levels' || collectionName === 'lessons') {
    return snapshot.name || collectionName;
  }
  if (collectionName === 'listeningexercises') return snapshot.title || 'Listening exercise';
  if (collectionName === 'videolessons') return snapshot.title || 'Video lesson';
  return collectionName;
};

const getModel = (collectionName) => {
  const model = MODEL_MAP[collectionName];
  if (!model) {
    throw Object.assign(new Error(`Unsupported collection: ${collectionName}`), {
      statusCode: 400,
      code: 'BAD_REQUEST',
    });
  }
  return model;
};

const formatEntry = (doc) => ({
  id: doc._id,
  collectionName: doc.collectionName,
  documentId: doc.documentId,
  label: doc.label,
  moduleType: doc.moduleType,
  branchId: doc.branchId,
  cascadeGroupId: doc.cascadeGroupId,
  deletedBy: doc.deletedBy,
  deletedAt: doc.deletedAt,
  isImportant: doc.isImportant,
  restoredAt: doc.restoredAt,
  purgedAt: doc.purgedAt,
  createdAt: doc.createdAt,
});

const formatSnapshot = (doc) => ({
  id: doc._id,
  collectionName: doc.collectionName,
  documentId: doc.documentId,
  version: doc.version,
  changeType: doc.changeType,
  changedBy: doc.changedBy,
  createdAt: doc.createdAt,
  snapshot: doc.snapshot,
});

const nextSnapshotVersion = async (collectionName, documentId) => {
  const latest = await Snapshot.findOne({ collectionName, documentId }).sort({ version: -1 }).lean();
  return (latest?.version || 0) + 1;
};

const recordSnapshot = async ({ collectionName, documentId, snapshot, changedBy, changeType }) => {
  const version = await nextSnapshotVersion(collectionName, documentId);
  return Snapshot.create({
    collectionName,
    documentId,
    version,
    snapshot,
    changedBy: changedBy || 'system',
    changeType,
  });
};

const softDelete = async (collectionName, documentId, options = {}) => {
  const Model = getModel(collectionName);
  const doc = await Model.findById(documentId).setOptions({ includeDeleted: true });
  if (!doc) {
    throw Object.assign(new Error('Document not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (doc.isDeleted) {
    throw Object.assign(new Error('Document already deleted'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const snapshot = doc.toObject();
  const cascadeGroupId = options.cascadeGroupId || `cascade-${Date.now()}-${Math.floor(Math.random() * 10000)}`;
  const deletedBy = options.deletedBy || 'system';
  const moduleType = options.moduleType || MODULE_BY_COLLECTION[collectionName] || collectionName;
  const branchId = options.branchId
    || snapshot.branchId
    || null;

  doc.isDeleted = true;
  doc.deletedAt = new Date();
  doc.deletedBy = deletedBy;
  await doc.save();

  const entry = await RecycleBin.create({
    collectionName,
    documentId,
    snapshot,
    label: inferLabel(snapshot, collectionName),
    cascadeGroupId,
    deletedBy,
    deletedAt: new Date(),
    moduleType,
    isImportant: options.isImportant === true,
    branchId,
  });

  await recordSnapshot({
    collectionName,
    documentId,
    snapshot,
    changedBy: deletedBy,
    changeType: 'delete',
  });

  return formatEntry(entry.toObject());
};

const assertCanAccessEntry = (req, entry) => {
  if (!req || req.user?.role === 'founder') return;
  const branchId = entry.branchId || entry.snapshot?.branchId;
  // Global CMS (no branch) is visible to privileged staff on this route already.
  if (!branchId) return;
  if (!canAccessBranch(req, branchId)) {
    throw Object.assign(new Error('Forbidden'), { statusCode: 403, code: 'FORBIDDEN' });
  }
};

const listEntries = async (query = {}, req = null) => {
  const { page, limit, skip } = parsePagination(query);
  const filter = { purgedAt: null, restoredAt: null };
  if (query.collectionName) filter.collectionName = query.collectionName;
  if (query.moduleType) filter.moduleType = query.moduleType;
  if (query.isImportant === 'true') filter.isImportant = true;

  const branchFilter = req ? getBranchFilter(req) : {};
  if (branchFilter.branchId) {
    // Include global (no branch) CMS deletions plus this branch's items.
    filter.$and = [
      ...(filter.$and || []),
      {
        $or: [
          { branchId: branchFilter.branchId },
          { branchId: null },
          { branchId: { $exists: false } },
        ],
      },
    ];
  }

  if (query.search) {
    const term = String(query.search).trim();
    if (term) {
      filter.$or = [
        { label: { $regex: term, $options: 'i' } },
        { collectionName: { $regex: term, $options: 'i' } },
        { moduleType: { $regex: term, $options: 'i' } },
      ];
    }
  }

  const [items, total] = await Promise.all([
    RecycleBin.find(filter).sort({ deletedAt: -1 }).skip(skip).limit(limit),
    RecycleBin.countDocuments(filter),
  ]);

  return {
    items: items.map((item) => formatEntry(item.toObject())),
    meta: buildPaginationMeta(page, limit, total),
  };
};

const getSnapshotsForEntry = async (entryId, req = null) => {
  const entry = await RecycleBin.findById(entryId);
  if (!entry) {
    throw Object.assign(new Error('Recycle bin entry not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  assertCanAccessEntry(req, entry);

  const snapshots = await Snapshot.find({
    collectionName: entry.collectionName,
    documentId: entry.documentId,
  }).sort({ version: -1 });

  return {
    entry: formatEntry(entry.toObject()),
    snapshots: snapshots.map((s) => formatSnapshot(s.toObject())),
  };
};

const restoreDocument = async (entry) => {
  const Model = getModel(entry.collectionName);
  let doc = await Model.findById(entry.documentId).setOptions({ includeDeleted: true });

  const restoreData = { ...entry.snapshot };
  delete restoreData.__v;

  if (doc) {
    Object.assign(doc, restoreData);
    doc.isDeleted = false;
    doc.deletedAt = null;
    doc.deletedBy = null;
    await doc.save();
  } else {
    doc = await Model.create({
      ...restoreData,
      _id: entry.documentId,
      isDeleted: false,
      deletedAt: null,
      deletedBy: null,
    });
  }

  entry.restoredAt = new Date();
  await entry.save();
  return formatEntry(entry.toObject());
};

const restoreEntry = async (id, req = null) => {
  const entry = await RecycleBin.findById(id);
  if (!entry || entry.purgedAt) {
    throw Object.assign(new Error('Recycle bin entry not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  assertCanAccessEntry(req, entry);
  if (entry.restoredAt) {
    throw Object.assign(new Error('Item already restored'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const restored = [await restoreDocument(entry)];

  if (entry.cascadeGroupId) {
    const siblings = await RecycleBin.find({
      cascadeGroupId: entry.cascadeGroupId,
      _id: { $ne: entry._id },
      restoredAt: null,
      purgedAt: null,
    });
    for (const sibling of siblings) {
      assertCanAccessEntry(req, sibling);
      restored.push(await restoreDocument(sibling));
    }
  }

  return { restoredCount: restored.length, items: restored };
};

const purgeDocument = async (entry) => {
  const Model = getModel(entry.collectionName);
  await Model.deleteOne({ _id: entry.documentId });
  entry.purgedAt = new Date();
  await entry.save();
  return formatEntry(entry.toObject());
};

const purgeEntry = async (id, req = null) => {
  const entry = await RecycleBin.findById(id);
  if (!entry || entry.purgedAt) {
    throw Object.assign(new Error('Recycle bin entry not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  assertCanAccessEntry(req, entry);
  if (entry.isImportant) {
    throw Object.assign(new Error('Important items cannot be purged individually. Unmark first.'), {
      statusCode: 400,
      code: 'BAD_REQUEST',
    });
  }
  return purgeDocument(entry);
};

const purgeAll = async ({ olderThanDays = 30, moduleType } = {}, req = null) => {
  const cutoff = new Date(Date.now() - olderThanDays * 24 * 60 * 60 * 1000);
  const filter = {
    purgedAt: null,
    restoredAt: null,
    isImportant: { $ne: true },
    deletedAt: { $lt: cutoff },
  };
  if (moduleType) filter.moduleType = moduleType;

  const branchFilter = req ? getBranchFilter(req) : {};
  if (branchFilter.branchId) {
    filter.$or = [
      { branchId: branchFilter.branchId },
      { branchId: null },
      { branchId: { $exists: false } },
    ];
  }

  const entries = await RecycleBin.find(filter);
  const purged = [];
  for (const entry of entries) {
    purged.push(await purgeDocument(entry));
  }
  return { purgedCount: purged.length, items: purged };
};

const toggleImportant = async (id, req = null) => {
  const entry = await RecycleBin.findById(id);
  if (!entry || entry.purgedAt || entry.restoredAt) {
    throw Object.assign(new Error('Recycle bin entry not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  assertCanAccessEntry(req, entry);
  entry.isImportant = !entry.isImportant;
  await entry.save();
  return formatEntry(entry.toObject());
};

module.exports = {
  softDelete,
  listEntries,
  getSnapshotsForEntry,
  restoreEntry,
  purgeEntry,
  purgeAll,
  toggleImportant,
  inferLabel,
};
