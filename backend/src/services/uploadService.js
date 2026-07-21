const path = require('path');
const { assertMagicBytes } = require('../utils/fileMagic');

const buildPublicUrl = (subdir, filename) => `/api/v1/uploads/${subdir}/${filename}`;

const saveUploadedFile = (file, type) => {
  if (!file) {
    throw Object.assign(new Error('File is required'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }

  const kind = type === 'audio' ? 'audio' : 'image';
  assertMagicBytes(file.path, kind);

  const subdir = type === 'audio' ? 'audio' : 'images';
  return {
    filename: file.filename,
    originalName: file.originalname,
    mimeType: file.mimetype,
    size: file.size,
    url: buildPublicUrl(subdir, path.basename(file.filename)),
  };
};

module.exports = { buildPublicUrl, saveUploadedFile };
