const NewsPost = require('../models/NewsPost');
const NewsReaction = require('../models/NewsReaction');
const NewsComment = require('../models/NewsComment');
const NewsCategory = require('../models/NewsCategory');
const Poll = require('../models/Poll');
const ExamGroup = require('../models/ExamGroup');
const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const { hasPermission } = require('../middleware/auth');
const notificationService = require('./notificationService');
const Settings = require('../models/Settings');

const badRequest = (message) => Object.assign(new Error(message), { statusCode: 400, code: 'BAD_REQUEST' });
const forbidden = (message) => Object.assign(new Error(message), { statusCode: 403, code: 'FORBIDDEN' });
const notFound = (message) => Object.assign(new Error(message), { statusCode: 404, code: 'NOT_FOUND' });

const actor = (req) => ({
  userId: req.user._id,
  userType: req.userType === 'student' ? 'student' : 'teacher',
  role: req.user.role || null,
  branchId: req.user.branchId || null,
  name: req.user.name || '',
});

const assertCanView = async (req) => {
  if (req.userType === 'student') return;
  if (req.user.role === 'founder') return;
  const ok = await hasPermission(req, 'canViewNewsFeed');
  if (!ok) throw forbidden('Missing permission: canViewNewsFeed');
};

const assertCanCreate = async (req) => {
  if (req.userType !== 'teacher') throw forbidden('Staff only');
  if (req.user.role === 'founder') return;
  const ok = await hasPermission(req, 'canCreateNews');
  if (!ok) throw forbidden('Missing permission: canCreateNews');
};

const assertCanManage = async (req, post) => {
  if (req.userType !== 'teacher') throw forbidden('Staff only');
  if (req.user.role === 'founder') return;
  if (await hasPermission(req, 'canManageNews')) return;
  if (await hasPermission(req, 'canModerateNews')) return;
  if (post && String(post.authorId) === String(req.user._id) && (await hasPermission(req, 'canCreateNews'))) {
    return;
  }
  throw forbidden('Missing permission to manage news');
};

const normalizeAudience = (raw = {}) => ({
  mode: raw.mode || 'everyone',
  roles: Array.isArray(raw.roles) ? raw.roles.map(String) : [],
  subjectIds: Array.isArray(raw.subjectIds) ? raw.subjectIds.filter(Boolean) : [],
  examGroupIds: Array.isArray(raw.examGroupIds) ? raw.examGroupIds.filter(Boolean) : [],
  branchIds: Array.isArray(raw.branchIds) ? raw.branchIds.filter(Boolean) : [],
});

const getViewerContext = async (req) => {
  const a = actor(req);
  let groupIds = [];
  let subjectIds = [];
  if (a.userType === 'student') {
    const groups = await ExamGroup.find({ students: a.userId }).select('_id subject').lean();
    groupIds = groups.map((g) => String(g._id));
    subjectIds = [...new Set(groups.map((g) => String(g.subject)).filter(Boolean))];
  } else if (a.userType === 'teacher' && a.role === 'teacher') {
    const groups = await ExamGroup.find({ teachers: a.userId }).select('_id subject').lean();
    groupIds = groups.map((g) => String(g._id));
    subjectIds = [...new Set(groups.map((g) => String(g.subject)).filter(Boolean))];
  }
  return { ...a, groupIds, subjectIds };
};

const matchesAudience = (audience, viewer) => {
  const aud = audience || { mode: 'everyone' };
  if (!aud.mode || aud.mode === 'everyone') return true;
  if (aud.mode === 'roles') {
    if (viewer.userType === 'student') return (aud.roles || []).includes('student');
    return (aud.roles || []).includes(viewer.role || 'teacher');
  }
  if (aud.mode === 'branches') {
    if (!viewer.branchId) return false;
    return (aud.branchIds || []).some((id) => String(id) === String(viewer.branchId));
  }
  if (aud.mode === 'groups') {
    const targets = (aud.examGroupIds || []).map(String);
    return targets.some((id) => viewer.groupIds.includes(id));
  }
  if (aud.mode === 'subjects') {
    const targets = (aud.subjectIds || []).map(String);
    return targets.some((id) => viewer.subjectIds.includes(id));
  }
  return true;
};

const formatPost = (doc, extras = {}) => {
  const o = doc.toObject ? doc.toObject() : doc;
  return {
    id: String(o._id),
    type: o.type,
    title: o.title,
    body: o.body || '',
    category: o.category || 'News',
    tags: o.tags || [],
    authorId: String(o.authorId),
    authorType: o.authorType || 'teacher',
    authorName: o.authorName || '',
    status: o.status,
    publishAt: o.publishAt,
    expiresAt: o.expiresAt,
    pinned: !!o.pinned,
    pinOrder: o.pinOrder || 0,
    commentsEnabled: o.commentsEnabled !== false,
    reactionsEnabled: o.reactionsEnabled !== false,
    audience: o.audience || { mode: 'everyone' },
    media: o.media || [],
    links: o.links || [],
    event: (() => {
      if (!o.event) return null;
      const regs = o.event.registrations || [];
      const viewer = extras.viewer;
      return {
        startsAt: o.event.startsAt || null,
        endsAt: o.event.endsAt || null,
        location: o.event.location || '',
        joinUrl: o.event.joinUrl || '',
        registrationUrl: o.event.registrationUrl || '',
        registrationCount: regs.length,
        registered: viewer
          ? regs.some(
              (r) => String(r.userId) === String(viewer.userId) && r.userType === viewer.userType
            )
          : false,
        registrations: regs.map((r) => ({
          userId: String(r.userId),
          userType: r.userType,
          name: r.name || '',
          at: r.at,
        })),
      };
    })(),
    pollId: o.pollId ? String(o.pollId) : null,
    showAsQuoteOfDay: !!o.showAsQuoteOfDay,
    quoteDate: o.quoteDate,
    stats: o.stats || {},
    createdAt: o.createdAt,
    updatedAt: o.updatedAt,
    myReaction: extras.myReaction || null,
    poll: extras.poll || null,
  };
};

const publishedFilter = (now = new Date()) => ({
  status: 'published',
  $and: [
    {
      $or: [{ publishAt: null }, { publishAt: { $lte: now } }],
    },
    {
      $or: [{ expiresAt: null }, { expiresAt: { $gt: now } }],
    },
  ],
});

const listCategories = async () => {
  const items = await NewsCategory.find({ active: true }).sort({ order: 1, name: 1 });
  return items.map((c) => ({
    id: String(c._id),
    name: c.name,
    slug: c.slug,
    order: c.order,
  }));
};

const listFeed = async (req) => {
  await assertCanView(req);
  await publishDueScheduled();
  const viewer = await getViewerContext(req);
  const limit = Math.min(Number(req.query.limit) || 20, 50);
  const cursor = req.query.cursor ? new Date(req.query.cursor) : null;
  const filter = { ...publishedFilter() };
  if (req.query.category) filter.category = String(req.query.category);
  if (req.query.type) filter.type = String(req.query.type);
  if (req.query.q) {
    const q = String(req.query.q).trim();
    filter.$or = [
      { title: { $regex: q, $options: 'i' } },
      { body: { $regex: q, $options: 'i' } },
      { tags: { $regex: q, $options: 'i' } },
    ];
  }
  if (cursor) {
    filter.$and = [...(filter.$and || []), { publishAt: { $lt: cursor } }];
  }

  const candidates = await NewsPost.find(filter)
    .sort({ pinned: -1, pinOrder: 1, publishAt: -1, createdAt: -1 })
    .limit(limit * 3);

  const matched = [];
  for (const post of candidates) {
    if (!matchesAudience(post.audience, viewer)) continue;
    matched.push(post);
    if (matched.length >= limit) break;
  }

  const postIds = matched.map((p) => p._id);
  const reactions = await NewsReaction.find({
    postId: { $in: postIds },
    userId: viewer.userId,
    userType: viewer.userType,
  }).lean();
  const reactionMap = Object.fromEntries(reactions.map((r) => [String(r.postId), r.emoji]));

  const pollIds = matched.map((p) => p.pollId).filter(Boolean);
  const polls = pollIds.length ? await Poll.find({ _id: { $in: pollIds } }) : [];
  const pollMap = Object.fromEntries(polls.map((p) => [String(p._id), p]));

  const pollService = require('./pollService');
  const items = [];
  for (const post of matched) {
    let pollPayload = null;
    if (post.pollId && pollMap[String(post.pollId)]) {
      pollPayload = await pollService.formatPollWithResults(pollMap[String(post.pollId)], req, {
        light: true,
      });
    }
    items.push(
      formatPost(post, {
        myReaction: reactionMap[String(post._id)] || null,
        poll: pollPayload,
        viewer,
      })
    );
  }

  const nextCursor =
    matched.length === limit && matched[matched.length - 1].publishAt
      ? matched[matched.length - 1].publishAt.toISOString()
      : null;

  const quote = await ensureQuoteOfDay();
  let quoteOfDay = null;
  if (quote && matchesAudience(quote.audience, viewer)) {
    quoteOfDay = formatPost(quote, {
      myReaction: reactionMap[String(quote._id)] || null,
      viewer,
    });
  }

  return { items, nextCursor, quoteOfDay };
};

const listAdmin = async (req) => {
  if (req.userType !== 'teacher') throw forbidden('Staff only');
  await assertCanView(req);
  const filter = {};
  if (req.query.status) filter.status = String(req.query.status);
  if (req.query.category) filter.category = String(req.query.category);
  const items = await NewsPost.find(filter).sort({ updatedAt: -1 }).limit(200);
  return items.map((p) => formatPost(p));
};

const getPost = async (req, id) => {
  await assertCanView(req);
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  const viewer = await getViewerContext(req);
  const isStaff = req.userType === 'teacher';
  if (post.status !== 'published' && !isStaff) throw notFound('Post not found');
  if (post.status === 'published' && !matchesAudience(post.audience, viewer) && !isStaff) {
    throw forbidden('Not in audience');
  }
  const reaction = await NewsReaction.findOne({
    postId: post._id,
    userId: viewer.userId,
    userType: viewer.userType,
  });
  let poll = null;
  if (post.pollId) {
    const pollDoc = await Poll.findById(post.pollId);
    if (pollDoc) {
      const pollService = require('./pollService');
      poll = await pollService.formatPollWithResults(pollDoc, req, { light: false });
    }
  }
  return formatPost(post, { myReaction: reaction?.emoji || null, poll, viewer });
};

const createPost = async (req, body) => {
  await assertCanCreate(req);
  const a = actor(req);
  const status = body.status || 'draft';
  const post = await NewsPost.create({
    type: body.type || 'announcement',
    title: String(body.title || '').trim() || 'Untitled',
    body: body.body || '',
    category: body.category || 'News',
    tags: Array.isArray(body.tags) ? body.tags : [],
    authorId: a.userId,
    authorType: 'teacher',
    authorName: a.name,
    status,
    publishAt: body.publishAt ? new Date(body.publishAt) : status === 'published' ? new Date() : null,
    expiresAt: body.expiresAt ? new Date(body.expiresAt) : null,
    pinned: !!body.pinned,
    pinOrder: Number(body.pinOrder) || 0,
    commentsEnabled: body.commentsEnabled !== false,
    reactionsEnabled: body.reactionsEnabled !== false,
    audience: normalizeAudience(body.audience),
    media: Array.isArray(body.media) ? body.media : [],
    links: Array.isArray(body.links) ? body.links : [],
    event: body.event || null,
    showAsQuoteOfDay: !!body.showAsQuoteOfDay,
    quoteDate: body.quoteDate ? new Date(body.quoteDate) : null,
  });

  if (body.poll && typeof body.poll === 'object') {
    const pollService = require('./pollService');
    const poll = await pollService.createPollForPost(req, post, body.poll);
    post.pollId = poll._id;
    if (post.type === 'announcement') post.type = 'poll_embed';
    await post.save();
  }

  if (post.status === 'published') {
    await notifyAudience(post);
  }
  return getPost(req, post._id);
};

const updatePost = async (req, id, body) => {
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  await assertCanManage(req, post);

  const fields = [
    'type',
    'title',
    'body',
    'category',
    'tags',
    'status',
    'pinned',
    'pinOrder',
    'commentsEnabled',
    'reactionsEnabled',
    'media',
    'links',
    'event',
    'showAsQuoteOfDay',
  ];
  for (const key of fields) {
    if (body[key] !== undefined) post[key] = body[key];
  }
  if (body.publishAt !== undefined) post.publishAt = body.publishAt ? new Date(body.publishAt) : null;
  if (body.expiresAt !== undefined) post.expiresAt = body.expiresAt ? new Date(body.expiresAt) : null;
  if (body.quoteDate !== undefined) post.quoteDate = body.quoteDate ? new Date(body.quoteDate) : null;
  if (body.audience) post.audience = normalizeAudience(body.audience);
  await post.save();

  if (body.poll && post.pollId) {
    const pollService = require('./pollService');
    await pollService.updatePoll(req, String(post.pollId), body.poll);
  } else if (body.poll && !post.pollId) {
    const pollService = require('./pollService');
    const poll = await pollService.createPollForPost(req, post, body.poll);
    post.pollId = poll._id;
    await post.save();
  }

  return getPost(req, post._id);
};

const softDeletePost = async (req, id) => {
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  await assertCanManage(req, post);
  post.isDeleted = true;
  post.deletedAt = new Date();
  post.deletedBy = String(req.user._id);
  post.status = 'archived';
  await post.save();
  return { ok: true };
};

const publishPost = async (req, id) => {
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  await assertCanManage(req, post);
  const wasPublished = post.status === 'published';
  post.status = 'published';
  if (!post.publishAt) post.publishAt = new Date();
  await post.save();
  if (post.pollId) {
    await Poll.updateOne({ _id: post.pollId }, { $set: { status: 'published' } });
  }
  if (!wasPublished) await notifyAudience(post);
  return getPost(req, post._id);
};

const unpublishPost = async (req, id) => {
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  await assertCanManage(req, post);
  post.status = 'draft';
  await post.save();
  return getPost(req, post._id);
};

const pinPost = async (req, id, pinned = true) => {
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  await assertCanManage(req, post);
  post.pinned = !!pinned;
  await post.save();
  return getPost(req, post._id);
};

const archivePost = async (req, id) => {
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  await assertCanManage(req, post);
  post.status = 'archived';
  post.pinned = false;
  await post.save();
  return getPost(req, post._id);
};

const duplicatePost = async (req, id) => {
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  await assertCanCreate(req);
  const a = actor(req);
  const copy = await NewsPost.create({
    type: post.type,
    title: `${post.title} (copy)`,
    body: post.body,
    category: post.category,
    tags: post.tags,
    authorId: a.userId,
    authorName: a.name,
    status: 'draft',
    audience: post.audience,
    media: post.media,
    links: post.links,
    event: post.event,
    commentsEnabled: post.commentsEnabled,
    reactionsEnabled: post.reactionsEnabled,
    showAsQuoteOfDay: false,
  });
  return getPost(req, copy._id);
};

const react = async (req, id, emoji) => {
  await assertCanView(req);
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  if (!post.reactionsEnabled) throw forbidden('Reactions disabled');
  const a = actor(req);
  const allowed = NewsReaction.REACTION_EMOJIS || ['like', 'love', 'celebrate', 'fire', 'helpful'];
  if (!allowed.includes(emoji)) throw badRequest('Invalid reaction');

  const existing = await NewsReaction.findOne({ postId: post._id, userId: a.userId, userType: a.userType });
  const counts = post.stats?.reactionCounts || {};
  if (existing) {
    if (counts[existing.emoji] > 0) counts[existing.emoji] -= 1;
    existing.emoji = emoji;
    await existing.save();
  } else {
    await NewsReaction.create({ postId: post._id, userId: a.userId, userType: a.userType, emoji });
  }
  counts[emoji] = (counts[emoji] || 0) + 1;
  post.stats = post.stats || {};
  post.stats.reactionCounts = counts;
  post.markModified('stats');
  await post.save();
  return getPost(req, post._id);
};

const unreact = async (req, id) => {
  await assertCanView(req);
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  const a = actor(req);
  const existing = await NewsReaction.findOneAndDelete({
    postId: post._id,
    userId: a.userId,
    userType: a.userType,
  });
  if (existing && post.stats?.reactionCounts?.[existing.emoji] > 0) {
    post.stats.reactionCounts[existing.emoji] -= 1;
    post.markModified('stats');
    await post.save();
  }
  return getPost(req, post._id);
};

const listComments = async (req, id) => {
  await assertCanView(req);
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  const items = await NewsComment.find({ postId: post._id }).sort({ createdAt: 1 }).limit(200);
  return items.map((c) => ({
    id: String(c._id),
    postId: String(c.postId),
    parentId: c.parentId ? String(c.parentId) : null,
    authorId: String(c.authorId),
    authorType: c.authorType,
    authorName: c.authorName,
    body: c.body,
    createdAt: c.createdAt,
  }));
};

const addComment = async (req, id, body) => {
  await assertCanView(req);
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  if (!post.commentsEnabled) throw forbidden('Comments disabled');
  const text = String(body || '').trim();
  if (!text) throw badRequest('Comment required');
  const a = actor(req);
  const comment = await NewsComment.create({
    postId: post._id,
    authorId: a.userId,
    authorType: a.userType,
    authorName: a.name,
    body: text,
    parentId: req.body?.parentId || null,
  });
  post.stats = post.stats || {};
  post.stats.commentCount = (post.stats.commentCount || 0) + 1;
  post.markModified('stats');
  await post.save();
  return {
    id: String(comment._id),
    postId: String(comment.postId),
    parentId: comment.parentId ? String(comment.parentId) : null,
    authorId: String(comment.authorId),
    authorType: comment.authorType,
    authorName: comment.authorName,
    body: comment.body,
    createdAt: comment.createdAt,
  };
};

const recordView = async (req, id) => {
  await assertCanView(req);
  await NewsPost.updateOne({ _id: id }, { $inc: { 'stats.views': 1 } });
  return { ok: true };
};

const recordClick = async (req, id) => {
  await assertCanView(req);
  await NewsPost.updateOne({ _id: id }, { $inc: { 'stats.clicks': 1 } });
  return { ok: true };
};

const publishDueScheduled = async () => {
  const now = new Date();
  await NewsPost.updateMany(
    {
      status: 'scheduled',
      publishAt: { $lte: now },
      isDeleted: { $ne: true },
    },
    { $set: { status: 'published' } }
  );
};

/** Pick / assign today's Quote of the Day from the QOTD pool. */
const ensureQuoteOfDay = async () => {
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setDate(end.getDate() + 1);

  const today = await NewsPost.findOne({
    ...publishedFilter(),
    showAsQuoteOfDay: true,
    quoteDate: { $gte: start, $lt: end },
  }).sort({ publishAt: -1 });
  if (today) return today;

  // Auto-rotate: prefer unused (null quoteDate), else oldest previously used.
  let candidate = await NewsPost.findOne({
    ...publishedFilter(),
    showAsQuoteOfDay: true,
    $or: [{ quoteDate: null }, { quoteDate: { $exists: false } }],
  }).sort({ publishAt: 1 });

  if (!candidate) {
    candidate = await NewsPost.findOne({
      ...publishedFilter(),
      showAsQuoteOfDay: true,
      quoteDate: { $lt: start },
    }).sort({ quoteDate: 1, publishAt: 1 });
  }

  // Legacy fallback: motivation/quote without the flag
  if (!candidate) {
    candidate = await NewsPost.findOne({
      ...publishedFilter(),
      type: { $in: ['quote', 'motivation'] },
      $or: [{ quoteDate: null }, { quoteDate: { $lt: start } }],
    }).sort({ quoteDate: 1, publishAt: 1 });
  }

  if (!candidate) return null;
  candidate.quoteDate = start;
  if (!candidate.showAsQuoteOfDay) candidate.showAsQuoteOfDay = true;
  await candidate.save();
  return candidate;
};

const fetchLinkPreview = async (url) => {
  const target = String(url || '').trim();
  if (!/^https?:\/\//i.test(target)) throw badRequest('Valid http(s) URL required');
  const https = require('https');
  const http = require('http');
  const lib = target.startsWith('https') ? https : http;
  const html = await new Promise((resolve, reject) => {
    const req = lib.get(
      target,
      { timeout: 8000, headers: { 'User-Agent': 'TechRenBot/1.0' } },
      (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          fetchLinkPreview(res.headers.location).then(resolve).catch(reject);
          return;
        }
        let data = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          data += chunk;
          if (data.length > 200000) {
            res.destroy();
            resolve(data);
          }
        });
        res.on('end', () => resolve(data));
      }
    );
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Preview timeout'));
    });
  });
  if (typeof html === 'object' && html.url) return html;
  const pick = (prop) => {
    const re = new RegExp(
      `<meta[^>]+(?:property|name)=["']${prop}["'][^>]+content=["']([^"']+)["']|<meta[^>]+content=["']([^"']+)["'][^>]+(?:property|name)=["']${prop}["']`,
      'i'
    );
    const m = String(html).match(re);
    return m ? m[1] || m[2] || '' : '';
  };
  const titleMatch = String(html).match(/<title[^>]*>([^<]+)<\/title>/i);
  return {
    url: target,
    provider: (() => {
      try {
        return new URL(target).hostname;
      } catch (_) {
        return '';
      }
    })(),
    previewTitle: pick('og:title') || (titleMatch ? titleMatch[1].trim() : ''),
    previewImage: pick('og:image'),
    previewDesc: pick('og:description') || pick('description'),
  };
};

const registerForEvent = async (req, id) => {
  await assertCanView(req);
  const post = await NewsPost.findById(id);
  if (!post) throw notFound('Post not found');
  if (!post.event) throw badRequest('Not an event post');
  const a = actor(req);
  post.event = post.event || {};
  const regs = post.event.registrations || [];
  const already = regs.some(
    (r) => String(r.userId) === String(a.userId) && r.userType === a.userType
  );
  if (!already) {
    regs.push({ userId: a.userId, userType: a.userType, name: a.name, at: new Date() });
    // store on Mixed-like path via markModified — event schema may not have registrations
    post.set('event.registrations', regs);
    post.markModified('event');
    await post.save();
  }
  return getPost(req, id);
};

const resolveAudienceUsers = async (post) => {
  const aud = post.audience || { mode: 'everyone' };
  let students = [];
  let teachers = [];

  if (aud.mode === 'everyone') {
    students = await Student.find({ status: { $ne: 'inactive' } }).select('_id branchId').lean();
    teachers = await Teacher.find({}).select('_id role branchId').lean();
  } else if (aud.mode === 'roles') {
    if ((aud.roles || []).includes('student')) {
      students = await Student.find({ status: { $ne: 'inactive' } }).select('_id branchId').lean();
    }
    const staffRoles = (aud.roles || []).filter((r) => r !== 'student');
    if (staffRoles.length) {
      teachers = await Teacher.find({ role: { $in: staffRoles } }).select('_id role branchId').lean();
    }
  } else if (aud.mode === 'branches') {
    students = await Student.find({
      branchId: { $in: aud.branchIds || [] },
      status: { $ne: 'inactive' },
    })
      .select('_id branchId')
      .lean();
    teachers = await Teacher.find({ branchId: { $in: aud.branchIds || [] } })
      .select('_id role branchId')
      .lean();
  } else if (aud.mode === 'groups') {
    const groups = await ExamGroup.find({ _id: { $in: aud.examGroupIds || [] } })
      .select('students teachers')
      .lean();
    const studentIds = new Set();
    const teacherIds = new Set();
    for (const g of groups) {
      (g.students || []).forEach((s) => studentIds.add(String(s)));
      (g.teachers || []).forEach((t) => teacherIds.add(String(t)));
    }
    students = [...studentIds].map((id) => ({ _id: id }));
    teachers = [...teacherIds].map((id) => ({ _id: id }));
  } else if (aud.mode === 'subjects') {
    const groups = await ExamGroup.find({ subject: { $in: aud.subjectIds || [] } })
      .select('students teachers')
      .lean();
    const studentIds = new Set();
    const teacherIds = new Set();
    for (const g of groups) {
      (g.students || []).forEach((s) => studentIds.add(String(s)));
      (g.teachers || []).forEach((t) => teacherIds.add(String(t)));
    }
    students = [...studentIds].map((id) => ({ _id: id }));
    teachers = [...teacherIds].map((id) => ({ _id: id }));
  }

  return { students, teachers };
};

const notifyAudience = async (post) => {
  try {
    const { students, teachers } = await resolveAudienceUsers(post);
    const title = post.title || 'Campus news';
    const body = (post.body || '').replace(/<[^>]+>/g, '').slice(0, 140) || 'New post published';
    const data = { postId: String(post._id), type: post.type };

    for (const s of students.slice(0, 2000)) {
      try {
        await notificationService.createInAppNotification({
          userId: s._id,
          userType: 'student',
          studentId: s._id,
          title,
          body,
          eventType: 'news_published',
          data: { ...data, screen: 'news' },
          branchId: s.branchId,
          push: true,
        });
      } catch (_) {
        /* non-fatal */
      }
    }
    for (const t of teachers.slice(0, 500)) {
      try {
        await notificationService.createInAppNotification({
          userId: t._id,
          userType: 'teacher',
          title,
          body,
          eventType: 'news_published',
          data: { ...data, screen: 'news' },
          branchId: t.branchId,
          push: true,
        });
      } catch (_) {
        /* non-fatal */
      }
    }
  } catch (_) {
    /* non-fatal */
  }
};

const canTeachersCreatePolls = async () => {
  const settings = await Settings.findById('global');
  return settings?.featureFlags?.teachersCanCreatePolls === true;
};

module.exports = {
  listCategories,
  listFeed,
  listAdmin,
  getPost,
  createPost,
  updatePost,
  softDeletePost,
  publishPost,
  unpublishPost,
  pinPost,
  archivePost,
  duplicatePost,
  react,
  unreact,
  listComments,
  addComment,
  recordView,
  recordClick,
  fetchLinkPreview,
  registerForEvent,
  assertCanCreate,
  assertCanManage,
  assertCanView,
  matchesAudience,
  getViewerContext,
  canTeachersCreatePolls,
  formatPost,
  normalizeAudience,
  actor,
};
