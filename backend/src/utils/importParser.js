const { normalizeText } = require('./textNormalizer');

const SEPARATOR_PATTERN = /^(.+?)\s*(?:[-–—|:|→>•·]|\t)\s*(.+)$/;
const TASK_KEYWORD_PATTERN = /^(?:task|exercise|assignment|masala|vazifa|topshiriq)\b/i;
const NUMBERED_LINE_PATTERN = /^\d+[\).:\-]\s+/;

const isTaskLine = (line) => {
  if (TASK_KEYWORD_PATTERN.test(line)) return true;
  // Numbered instruction without an EN-UZ separator
  return NUMBERED_LINE_PATTERN.test(line) && !SEPARATOR_PATTERN.test(line);
};

const stripHtml = (html) =>
  String(html || '')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/\s+/g, ' ')
    .trim();

const parsePairsFromText = (rawText) => {
  const lines = String(rawText || '')
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  const pairs = [];
  const tasks = [];
  const skippedLines = [];
  let currentTask = null;

  for (const line of lines) {
    if (isTaskLine(line)) {
      currentTask = normalizeText(line).trim();
      tasks.push(currentTask);
      continue;
    }

    const match = line.match(SEPARATOR_PATTERN);
    if (!match) {
      skippedLines.push(line);
      continue;
    }

    const english = normalizeText(match[1]).trim();
    const uzbek = normalizeText(match[2]).trim();
    if (!english || !uzbek) {
      skippedLines.push(line);
      continue;
    }

    pairs.push({
      english,
      uzbek,
      ...(currentTask ? { task: currentTask } : {}),
    });
  }

  return { pairs, tasks, skippedLines, pairCount: pairs.length };
};

/**
 * Walk DOCX HTML blocks in order so images/tasks can bind to following pairs.
 */
const parseStructuredImport = (html, imageMetaBySrc = {}) => {
  const tokens = [];
  const regex = /<img\b[^>]*\bsrc=["']([^"']+)["'][^>]*>|<(?:p|li|h[1-6]|td)\b[^>]*>([\s\S]*?)<\/(?:p|li|h[1-6]|td)>/gi;
  let match;
  while ((match = regex.exec(html))) {
    if (match[1]) {
      tokens.push({ type: 'image', src: match[1] });
    } else {
      const text = stripHtml(match[2]);
      if (text) tokens.push({ type: 'text', text });
    }
  }

  if (tokens.length === 0) {
    return parsePairsFromText(stripHtml(html));
  }

  const pairs = [];
  const tasks = [];
  const skippedLines = [];
  let currentTask = null;
  let pendingImageUrl = null;

  for (const token of tokens) {
    if (token.type === 'image') {
      pendingImageUrl = imageMetaBySrc[token.src]?.url || token.src;
      continue;
    }

    const line = token.text;
    if (isTaskLine(line)) {
      currentTask = normalizeText(line).trim();
      tasks.push(currentTask);
      continue;
    }

    const pairMatch = line.match(SEPARATOR_PATTERN);
    if (!pairMatch) {
      skippedLines.push(line);
      continue;
    }

    const english = normalizeText(pairMatch[1]).trim();
    const uzbek = normalizeText(pairMatch[2]).trim();
    if (!english || !uzbek) {
      skippedLines.push(line);
      continue;
    }

    const pair = { english, uzbek };
    if (currentTask) pair.task = currentTask;
    if (pendingImageUrl) {
      pair.imageUrl = pendingImageUrl;
      pendingImageUrl = null;
    }
    pairs.push(pair);
  }

  // Orphan trailing images: attach to last pair without an image
  if (pendingImageUrl && pairs.length > 0) {
    const last = pairs[pairs.length - 1];
    if (!last.imageUrl) last.imageUrl = pendingImageUrl;
  }

  return { pairs, tasks, skippedLines, pairCount: pairs.length };
};

module.exports = {
  parsePairsFromText,
  parseStructuredImport,
  SEPARATOR_PATTERN,
  isTaskLine,
  stripHtml,
};
