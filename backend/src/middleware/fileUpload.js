const path = require('path');
const multer = require('multer');
const { ensureUploadDirs } = require('../config/paths');

const UPLOAD_ROOT = ensureUploadDirs();
const DOCX_DIR = path.join(UPLOAD_ROOT, 'imports');
const IMAGE_DIR = path.join(UPLOAD_ROOT, 'images');
const AUDIO_DIR = path.join(UPLOAD_ROOT, 'audio');
const COMMUNICATIONS_DIR = path.join(UPLOAD_ROOT, 'communications');
if (!require('fs').existsSync(COMMUNICATIONS_DIR)) {
  require('fs').mkdirSync(COMMUNICATIONS_DIR, { recursive: true });
}
const NEWS_DIR = path.join(UPLOAD_ROOT, 'news');
if (!require('fs').existsSync(NEWS_DIR)) {
  require('fs').mkdirSync(NEWS_DIR, { recursive: true });
}

const makeStorage = (folder, prefix) =>
  multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, folder),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname) || '';
      cb(null, `${prefix}-${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
    },
  });

const docxUpload = multer({
  storage: makeStorage(DOCX_DIR, 'import'),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(docx|txt|csv)$/i;
    if (allowed.test(file.originalname)) cb(null, true);
    else cb(new Error('Only .docx, .txt, or .csv files are allowed'));
  },
});

const imageUpload = multer({
  storage: makeStorage(IMAGE_DIR, 'image'),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(jpe?g|png|webp|gif)$/i;
    if (allowed.test(file.originalname) || file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only image files are allowed'));
  },
});

const audioUpload = multer({
  storage: makeStorage(AUDIO_DIR, 'audio'),
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(mp3|wav|ogg|m4a|aac|webm|mpeg)$/i;
    if (allowed.test(file.originalname) || file.mimetype.startsWith('audio/')) cb(null, true);
    else cb(new Error('Only audio files are allowed'));
  },
});

const ocrUpload = multer({
  storage: makeStorage(IMAGE_DIR, 'ocr'),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(jpe?g|png|webp|gif|bmp|tiff?)$/i;
    if (allowed.test(file.originalname) || file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only image files are allowed for OCR'));
  },
});

const communicationsUpload = multer({
  storage: makeStorage(COMMUNICATIONS_DIR, 'chat'),
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed =
      /\.(jpe?g|png|webp|gif|pdf|docx?|xlsx?|pptx?|mp3|wav|ogg|m4a|mp4|webm|mov|txt|zip)$/i;
    if (allowed.test(file.originalname) || file.mimetype.startsWith('image/') || file.mimetype.startsWith('audio/') || file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('File type not allowed'));
    }
  },
});

const newsUpload = multer({
  storage: makeStorage(NEWS_DIR, 'news'),
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(jpe?g|png|webp|gif|pdf|mp4|webm|mov|mp3|wav|m4a)$/i;
    if (
      allowed.test(file.originalname) ||
      file.mimetype.startsWith('image/') ||
      file.mimetype.startsWith('video/') ||
      file.mimetype.startsWith('audio/') ||
      file.mimetype === 'application/pdf'
    ) {
      cb(null, true);
    } else {
      cb(new Error('File type not allowed for news'));
    }
  },
});

module.exports = {
  UPLOAD_ROOT,
  DOCX_DIR,
  IMAGE_DIR,
  AUDIO_DIR,
  COMMUNICATIONS_DIR,
  NEWS_DIR,
  docxUpload,
  imageUpload,
  audioUpload,
  ocrUpload,
  communicationsUpload,
  newsUpload,
};
