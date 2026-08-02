const Poll = require('../models/Poll');
const PollVote = require('../models/PollVote');
const NewsPost = require('../models/NewsPost');
const { hasPermission } = require('../middleware/auth');
const newsService = require('./newsService');

const badRequest = (message) => Object.assign(new Error(message), { statusCode: 400, code: 'BAD_REQUEST' });
const forbidden = (message) => Object.assign(new Error(message), { statusCode: 403, code: 'FORBIDDEN' });
const notFound = (message) => Object.assign(new Error(message), { statusCode: 404, code: 'NOT_FOUND' });

let pollEmitter = null;
const setPollEmitter = (fn) => {
  pollEmitter = fn;
};

const emitPoll = (pollId, event, payload) => {
  if (typeof pollEmitter === 'function') {
    pollEmitter(String(pollId), event, payload);
  }
};

const assertCanCreatePoll = async (req) => {
  if (req.userType !== 'teacher') throw forbidden('Staff only');
  if (req.user.role === 'founder') return;
  if (await hasPermission(req, 'canCreatePolls')) return;
  if (await hasPermission(req, 'canCreateNews')) return;
  if (req.user.role === 'teacher' && (await newsService.canTeachersCreatePolls())) return;
  throw forbidden('Missing permission: canCreatePolls');
};

const defaultOptionsForType = (pollType, options) => {
  if (Array.isArray(options) && options.length >= 2) {
    return options.map((o, i) => ({
      label: String(o.label || o).trim(),
      order: o.order != null ? o.order : i,
    }));
  }
  if (pollType === 'yes_no') {
    return [
      { label: 'Yes', order: 0 },
      { label: 'No', order: 1 },
    ];
  }
  if (pollType === 'true_false') {
    return [
      { label: 'True', order: 0 },
      { label: 'False', order: 1 },
    ];
  }
  if (pollType === 'rating') {
    return [1, 2, 3, 4, 5].map((n, i) => ({ label: String(n), order: i }));
  }
  if (pollType === 'emoji') {
    return ['😀', '🙂', '😐', '😕', '😡'].map((e, i) => ({ label: e, order: i }));
  }
  throw badRequest('Poll needs at least 2 options');
};

const createPollForPost = async (req, post, body = {}) => {
  await assertCanCreatePoll(req);
  const pollType = body.pollType || 'single';
  const options = defaultOptionsForType(pollType, body.options);
  const poll = await Poll.create({
    postId: post._id,
    question: String(body.question || post.title || 'Poll').trim(),
    pollType,
    options,
    allowChangeVote: !!body.allowChangeVote,
    resultsVisibility: body.resultsVisibility || 'immediate',
    startsAt: body.startsAt ? new Date(body.startsAt) : null,
    endsAt: body.endsAt ? new Date(body.endsAt) : null,
    status: post.status === 'published' ? 'published' : body.status || 'draft',
    audience: newsService.normalizeAudience(body.audience || post.audience),
    createdBy: req.user._id,
  });
  return poll;
};

const createPoll = async (req, body) => {
  await assertCanCreatePoll(req);
  const pollType = body.pollType || 'single';
  const options = defaultOptionsForType(pollType, body.options);
  const poll = await Poll.create({
    postId: body.postId || null,
    conversationId: body.conversationId || null,
    question: String(body.question || '').trim() || 'Poll',
    pollType,
    options,
    allowChangeVote: !!body.allowChangeVote,
    resultsVisibility: body.resultsVisibility || 'immediate',
    startsAt: body.startsAt ? new Date(body.startsAt) : null,
    endsAt: body.endsAt ? new Date(body.endsAt) : null,
    status: body.status || 'draft',
    audience: newsService.normalizeAudience(body.audience),
    createdBy: req.user._id,
  });
  if (body.postId) {
    await NewsPost.updateOne({ _id: body.postId }, { $set: { pollId: poll._id, type: 'poll_embed' } });
  }
  return formatPollWithResults(poll, req);
};

const updatePoll = async (req, id, body) => {
  const poll = await Poll.findById(id);
  if (!poll) throw notFound('Poll not found');
  await assertCanCreatePoll(req);

  if (body.question !== undefined) poll.question = String(body.question).trim();
  if (body.pollType !== undefined) poll.pollType = body.pollType;
  if (body.allowChangeVote !== undefined) poll.allowChangeVote = !!body.allowChangeVote;
  if (body.resultsVisibility !== undefined) poll.resultsVisibility = body.resultsVisibility;
  if (body.startsAt !== undefined) poll.startsAt = body.startsAt ? new Date(body.startsAt) : null;
  if (body.endsAt !== undefined) poll.endsAt = body.endsAt ? new Date(body.endsAt) : null;
  if (body.status !== undefined) poll.status = body.status;
  if (body.audience) poll.audience = newsService.normalizeAudience(body.audience);
  if (Array.isArray(body.options) && body.options.length >= 2) {
    poll.options = body.options.map((o, i) => ({
      _id: o.id || o._id,
      label: String(o.label || o).trim(),
      order: o.order != null ? o.order : i,
    }));
  }
  await poll.save();
  return formatPollWithResults(poll, req);
};

const closePoll = async (req, id) => {
  const poll = await Poll.findById(id);
  if (!poll) throw notFound('Poll not found');
  await assertCanCreatePoll(req);
  poll.status = 'closed';
  await poll.save();
  const payload = await formatPollWithResults(poll, req);
  emitPoll(poll._id, 'poll-closed', payload);
  return payload;
};

const reopenPoll = async (req, id) => {
  const poll = await Poll.findById(id);
  if (!poll) throw notFound('Poll not found');
  await assertCanCreatePoll(req);
  poll.status = 'published';
  await poll.save();
  return formatPollWithResults(poll, req);
};

const duplicatePoll = async (req, id) => {
  const poll = await Poll.findById(id);
  if (!poll) throw notFound('Poll not found');
  await assertCanCreatePoll(req);
  const copy = await Poll.create({
    postId: null,
    question: `${poll.question} (copy)`,
    pollType: poll.pollType,
    options: poll.options.map((o, i) => ({ label: o.label, order: i })),
    allowChangeVote: poll.allowChangeVote,
    resultsVisibility: poll.resultsVisibility,
    status: 'draft',
    audience: poll.audience,
    createdBy: req.user._id,
  });
  return formatPollWithResults(copy, req);
};

const isPollOpen = (poll, now = new Date()) => {
  if (poll.status === 'closed' || poll.status === 'archived' || poll.status === 'draft') return false;
  if (poll.startsAt && now < poll.startsAt) return false;
  if (poll.endsAt && now > poll.endsAt) return false;
  return poll.status === 'published' || poll.status === 'scheduled';
};

const tallyVotes = async (poll) => {
  const votes = await PollVote.find({ pollId: poll._id }).lean();
  const counts = {};
  for (const opt of poll.options) {
    counts[String(opt._id)] = 0;
  }
  for (const vote of votes) {
    for (const oid of vote.optionIds || []) {
      const key = String(oid);
      if (counts[key] != null) counts[key] += 1;
    }
  }
  return { votes, counts, totalVoters: votes.length };
};

const canSeeResults = (poll, hasVoted, now = new Date()) => {
  const vis = poll.resultsVisibility || 'immediate';
  if (vis === 'after_close') {
    return poll.status === 'closed' || (poll.endsAt && now > poll.endsAt);
  }
  if (vis === 'immediate' || vis === 'percent_only' || vis === 'counts' || vis === 'anonymous') {
    return true;
  }
  if (vis === 'voters') return hasVoted || poll.status === 'closed';
  return hasVoted;
};

const formatPollWithResults = async (poll, req, { light = false } = {}) => {
  const a = newsService.actor(req);
  const myVote = await PollVote.findOne({
    pollId: poll._id,
    userId: a.userId,
    userType: a.userType,
  }).lean();
  const { counts, totalVoters } = await tallyVotes(poll);
  const open = isPollOpen(poll);
  const showResults = canSeeResults(poll, !!myVote);

  const options = (poll.options || [])
    .slice()
    .sort((x, y) => (x.order || 0) - (y.order || 0))
    .map((o) => {
      const id = String(o._id);
      const count = counts[id] || 0;
      const percent = totalVoters > 0 ? Math.round((count / totalVoters) * 1000) / 10 : 0;
      const row = { id, label: o.label, order: o.order || 0 };
      if (showResults) {
        if (poll.resultsVisibility === 'percent_only') {
          row.percent = percent;
        } else {
          row.count = count;
          row.percent = percent;
        }
      }
      return row;
    });

  return {
    id: String(poll._id),
    postId: poll.postId ? String(poll.postId) : null,
    question: poll.question,
    pollType: poll.pollType,
    options,
    allowChangeVote: !!poll.allowChangeVote,
    resultsVisibility: poll.resultsVisibility,
    startsAt: poll.startsAt,
    endsAt: poll.endsAt,
    status: poll.status,
    open,
    totalVoters: showResults ? totalVoters : null,
    myOptionIds: myVote ? (myVote.optionIds || []).map(String) : [],
    hasVoted: !!myVote,
    light,
  };
};

const getResults = async (req, id) => {
  const poll = await Poll.findById(id);
  if (!poll) throw notFound('Poll not found');
  return formatPollWithResults(poll, req);
};

const vote = async (req, id, optionIds) => {
  await newsService.assertCanView(req);
  const poll = await Poll.findById(id);
  if (!poll) throw notFound('Poll not found');
  if (!isPollOpen(poll)) throw forbidden('Poll is closed');

  const viewer = await newsService.getViewerContext(req);
  if (!newsService.matchesAudience(poll.audience, viewer)) {
    throw forbidden('Not in poll audience');
  }

  const ids = Array.isArray(optionIds) ? optionIds.map(String) : [String(optionIds)].filter(Boolean);
  if (!ids.length) throw badRequest('Select an option');

  const validIds = new Set((poll.options || []).map((o) => String(o._id)));
  for (const oid of ids) {
    if (!validIds.has(oid)) throw badRequest('Invalid option');
  }

  if (
    poll.pollType === 'single' ||
    poll.pollType === 'yes_no' ||
    poll.pollType === 'true_false' ||
    poll.pollType === 'rating' ||
    poll.pollType === 'emoji'
  ) {
    if (ids.length !== 1) throw badRequest('Select exactly one option');
  }

  const a = newsService.actor(req);
  const existing = await PollVote.findOne({ pollId: poll._id, userId: a.userId, userType: a.userType });
  if (existing && !poll.allowChangeVote) throw forbidden('Already voted');

  if (existing) {
    existing.optionIds = ids;
    await existing.save();
  } else {
    await PollVote.create({
      pollId: poll._id,
      userId: a.userId,
      userType: a.userType,
      optionIds: ids,
    });
  }

  const payload = await formatPollWithResults(poll, req);
  emitPoll(poll._id, 'poll-results', payload);
  emitPoll(poll._id, 'poll-vote', {
    pollId: String(poll._id),
    userId: String(a.userId),
    userType: a.userType,
  });
  return payload;
};

const exportResultsCsv = async (req, id) => {
  const poll = await Poll.findById(id);
  if (!poll) throw notFound('Poll not found');
  await assertCanCreatePoll(req).catch(async () => {
    if (!(await hasPermission(req, 'canManageNews')) && !(await hasPermission(req, 'canModerateNews'))) {
      throw forbidden('Cannot export poll results');
    }
  });
  const results = await formatPollWithResults(poll, req, { light: false });
  const esc = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`;
  const lines = ['option,votes,percent'];
  const opts = results.options || [];
  const total = opts.reduce((n, o) => n + (o.count || 0), 0) || 1;
  for (const o of opts) {
    const votes = o.count || 0;
    lines.push([esc(o.label), votes, ((votes / total) * 100).toFixed(1)].join(','));
  }
  lines.push(`total,${opts.reduce((n, o) => n + (o.count || 0), 0)},100`);
  return {
    filename: `poll-${String(poll._id)}-results.csv`,
    csv: `${lines.join('\n')}\n`,
  };
};

module.exports = {
  setPollEmitter,
  createPoll,
  createPollForPost,
  updatePoll,
  closePoll,
  reopenPoll,
  duplicatePoll,
  vote,
  getResults,
  formatPollWithResults,
  exportResultsCsv,
};
