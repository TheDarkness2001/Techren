const fs = require('fs');
const path = require('path');
const mammoth = require('mammoth');
const homeworkService = require('./homeworkService');
const sentenceService = require('./sentenceService');
const { IMAGE_DIR } = require('../middleware/fileUpload');
const { parsePairsFromText, parseStructuredImport } = require('../utils/importParser');
const { buildPublicUrl } = require('./uploadService');

const extFromContentType = (contentType) => {
  if (contentType === 'image/png') return '.png';
  if (contentType === 'image/gif') return '.gif';
  if (contentType === 'image/webp') return '.webp';
  if (contentType === 'image/jpeg' || contentType === 'image/jpg') return '.jpg';
  return '.img';
};

const saveEmbeddedImage = async (image) => {
  const buffer = await image.read();
  const ext = extFromContentType(image.contentType);
  const filename = `image-${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
  fs.writeFileSync(path.join(IMAGE_DIR, filename), buffer);
  return {
    filename,
    contentType: image.contentType,
    url: buildPublicUrl('images', filename),
  };
};

const parseDocxFile = async (filePath) => {
  const ext = path.extname(filePath).toLowerCase();

  if (ext === '.txt') {
    const rawText = fs.readFileSync(filePath, 'utf8');
    const parsed = parsePairsFromText(rawText);
    return {
      ...parsed,
      images: [],
      source: 'txt',
      rawTextPreview: rawText.slice(0, 500),
    };
  }

  const images = [];
  const imageMetaBySrc = {};

  const htmlResult = await mammoth.convertToHtml(
    { path: filePath },
    {
      convertImage: mammoth.images.imgElement(async (image) => {
        const saved = await saveEmbeddedImage(image);
        images.push(saved);
        imageMetaBySrc[saved.url] = saved;
        return { src: saved.url };
      }),
    }
  );

  const textResult = await mammoth.extractRawText({ path: filePath });
  const structured = parseStructuredImport(htmlResult.value, imageMetaBySrc);
  const fallback = parsePairsFromText(textResult.value);
  const parsed = structured.pairCount > 0 ? structured : fallback;

  // Map leftover images onto pairs without images (by order)
  const unpairedImages = images.filter((img) => !parsed.pairs.some((p) => p.imageUrl === img.url));
  let imgIdx = 0;
  for (const pair of parsed.pairs) {
    if (!pair.imageUrl && imgIdx < unpairedImages.length) {
      pair.imageUrl = unpairedImages[imgIdx].url;
      imgIdx += 1;
    }
  }

  return {
    ...parsed,
    images,
    imageCount: images.length,
    taskCount: parsed.tasks?.length || 0,
    source: 'docx',
    rawTextPreview: textResult.value.slice(0, 500),
    warnings: htmlResult.messages?.map((m) => m.message) || [],
  };
};

const parseOcrImage = async (file) => {
  return {
    pairs: [],
    pairCount: 0,
    tasks: [],
    skippedLines: [],
    images: [
      {
        url: `/api/v1/uploads/images/${path.basename(file.filename)}`,
        filename: file.filename,
      },
    ],
    ocrEnabled: false,
    imageUrl: `/api/v1/uploads/images/${path.basename(file.filename)}`,
    filename: file.filename,
    message: 'OCR engine is not configured. Use DOCX import or paste pairs via bulk import.',
  };
};

const bulkImportWords = async (lessonId, pairs) => {
  const created = [];
  const skipped = [];
  const errors = [];

  for (const pair of pairs) {
    try {
      const word = await homeworkService.addWord({
        english: pair.english,
        uzbek: pair.uzbek,
        lessonId,
      });
      created.push(word);
    } catch (error) {
      if (error.code === 'DUPLICATE' || error.code === 'LIMIT_REACHED') {
        skipped.push({ ...pair, reason: error.message });
      } else {
        errors.push({ ...pair, reason: error.message });
      }
    }
  }

  return { created: created.length, skipped: skipped.length, errors, items: created, skippedItems: skipped };
};

const bulkImportSentences = async (lessonId, pairs) => {
  const created = [];
  const skipped = [];
  const errors = [];

  for (const pair of pairs) {
    try {
      const sentence = await sentenceService.createSentence({
        english: pair.english,
        uzbek: pair.uzbek,
        lessonId,
        task: pair.task,
        imageUrl: pair.imageUrl,
      });
      created.push(sentence);
    } catch (error) {
      if (error.code === 'DUPLICATE') {
        skipped.push({ ...pair, reason: error.message });
      } else {
        errors.push({ ...pair, reason: error.message });
      }
    }
  }

  return { created: created.length, skipped: skipped.length, errors, items: created, skippedItems: skipped };
};

module.exports = {
  parsePairsFromText,
  parseDocxFile,
  parseOcrImage,
  bulkImportWords,
  bulkImportSentences,
};
