const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess, sendList, sendError } = require('../utils/apiResponse');
const newsService = require('../services/newsService');

const handle = (res, error) =>
  sendError(res, error.statusCode || 500, error.code || 'SERVER_ERROR', error.message);

exports.listCategories = asyncHandler(async (req, res) => {
  try {
    sendList(res, await newsService.listCategories());
  } catch (e) {
    handle(res, e);
  }
});

exports.listFeed = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.listFeed(req));
  } catch (e) {
    handle(res, e);
  }
});

exports.listAdmin = asyncHandler(async (req, res) => {
  try {
    sendList(res, await newsService.listAdmin(req));
  } catch (e) {
    handle(res, e);
  }
});

exports.getPost = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.getPost(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.createPost = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.createPost(req, req.body), 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.updatePost = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.updatePost(req, req.params.id, req.body));
  } catch (e) {
    handle(res, e);
  }
});

exports.deletePost = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.softDeletePost(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.publishPost = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.publishPost(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.unpublishPost = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.unpublishPost(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.pinPost = asyncHandler(async (req, res) => {
  try {
    const pinned = req.body?.pinned !== false;
    sendSuccess(res, await newsService.pinPost(req, req.params.id, pinned));
  } catch (e) {
    handle(res, e);
  }
});

exports.archivePost = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.archivePost(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.duplicatePost = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.duplicatePost(req, req.params.id), 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.react = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.react(req, req.params.id, req.body?.emoji || 'like'));
  } catch (e) {
    handle(res, e);
  }
});

exports.unreact = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.unreact(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.listComments = asyncHandler(async (req, res) => {
  try {
    sendList(res, await newsService.listComments(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.addComment = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.addComment(req, req.params.id, req.body?.body), 201);
  } catch (e) {
    handle(res, e);
  }
});

exports.recordView = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.recordView(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.recordClick = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.recordClick(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.fetchLinkPreview = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.fetchLinkPreview(req.body?.url || req.query.url));
  } catch (e) {
    handle(res, e);
  }
});

exports.registerForEvent = asyncHandler(async (req, res) => {
  try {
    sendSuccess(res, await newsService.registerForEvent(req, req.params.id));
  } catch (e) {
    handle(res, e);
  }
});

exports.upload = asyncHandler(async (req, res) => {
  try {
    if (!req.file) return sendError(res, 400, 'BAD_REQUEST', 'File required');
    const mime = req.file.mimetype || '';
    let kind = 'file';
    if (mime.startsWith('image/')) kind = 'image';
    else if (mime.startsWith('video/')) kind = 'video';
    else if (mime.startsWith('audio/')) kind = 'audio';
    sendSuccess(res, {
      url: `/api/v1/uploads/news/${req.file.filename}`,
      mime,
      name: req.file.originalname,
      size: req.file.size,
      kind,
    });
  } catch (e) {
    handle(res, e);
  }
});
