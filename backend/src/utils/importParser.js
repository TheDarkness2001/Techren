const { normalizeText } = require('./textNormalizer');
const { parseCsv, looksLikeCsv } = require('./csvParser');
const { canonicalizeVocabPair } = require('./vocabList');

const SEPARATOR_PATTERN = /^(.+?)\s*(?:[-–—|:|→>•·]|\t)\s*(.+)$/;
const TASK_KEYWORD_PATTERN = /^(?:task|exercise|assignment|masala|vazifa|topshiriq)\b/i;
const NUMBERED_LINE_PATTERN = /^\d+[\).:\-]\s+/;
const CSV_HEADER_PATTERN = /^(english|en|word)$/i;

const isTaskLine = (line) => {
  if (TASK_KEYWORD_PATTERN.test(line)) return true;
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

const toPairRecord = (englishRaw, uzbekRaw, extras = {}) => {
  const canonical = canonicalizeVocabPair(englishRaw, uzbekRaw);
  if (!canonical.english || !canonical.uzbek) return null;
  return {
    english: canonical.english,
    uzbek: canonical.uzbek,
    englishForms: canonical.englishForms,
    uzbekMeanings: canonical.uzbekMeanings,
    ...extras,
  };
};

const emptyParseResult = () => ({
  pairs: [],
  tasks: [],
  skippedLines: [],
  warnings: [],
  duplicates: [],
  pairCount: 0,
  validCount: 0,
  warningCount: 0,
  duplicateCount: 0,
});

const finalizeParseResult = (result) => {
  const seen = new Map();
  const pairs = [];
  const duplicates = [...(result.duplicates || [])];

  for (const pair of result.pairs || []) {
    const key = (pair.englishForms || []).map((f) => f.toLowerCase()).sort().join('|');
    if (seen.has(key)) {
      duplicates.push({
        english: pair.english,
        uzbek: pair.uzbek,
        reason: `Duplicate detected: ${pair.english} → ${pair.uzbek}`,
      });
      continue;
    }
    seen.set(key, true);
    pairs.push(pair);
  }

  const warnings = result.warnings || [];
  return {
    pairs,
    tasks: result.tasks || [],
    skippedLines: result.skippedLines || [],
    warnings,
    duplicates,
    pairCount: pairs.length,
    validCount: pairs.length,
    warningCount: warnings.length,
    duplicateCount: duplicates.length,
  };
};

const parseCsvPairs = (rawText) => {
  const result = emptyParseResult();
  let rows;
  try {
    rows = parseCsv(rawText);
  } catch (error) {
    result.warnings.push({ row: 0, message: error.message || 'Malformed CSV' });
    return finalizeParseResult(result);
  }

  let start = 0;
  if (rows.length > 0) {
    const header = rows[0].map((cell) => String(cell || '').trim());
    if (header.length >= 2 && CSV_HEADER_PATTERN.test(header[0]) && /^(uzbek|uz|translation|meaning)$/i.test(header[1])) {
      start = 1;
    } else if (header.length >= 2 && !header[0] && !header[1]) {
      start = 1;
    }
  }

  for (let i = start; i < rows.length; i += 1) {
    const rowNumber = i + 1;
    const cells = rows[i].map((cell) => String(cell || '').trim());
    const isEmpty = cells.every((cell) => !cell);
    if (isEmpty) continue;

    if (cells.length > 2 && cells.slice(2).some(Boolean)) {
      result.warnings.push({
        row: rowNumber,
        message: `Row ${rowNumber} has ${cells.length} columns. Wrap English and Uzbek in quotes so commas stay inside one vocabulary item.`,
      });
    }

    const english = cells[0] || '';
    const uzbek = cells[1] || '';
    if (!english && !uzbek) continue;
    if (!english) {
      result.warnings.push({ row: rowNumber, message: `Row ${rowNumber} has no English word` });
      result.skippedLines.push(cells.join(','));
      continue;
    }
    if (!uzbek) {
      result.warnings.push({ row: rowNumber, message: `Row ${rowNumber} has no Uzbek meaning` });
      result.skippedLines.push(cells.join(','));
      continue;
    }

    const pair = toPairRecord(english, uzbek);
    if (!pair) {
      result.skippedLines.push(cells.join(','));
      continue;
    }
    pairsPush(result, pair, rowNumber);
  }

  return finalizeParseResult(result);
};

const pairsPush = (result, pair, rowNumber) => {
  const duplicate = result.pairs.find((existing) =>
    (existing.englishForms || []).map((f) => f.toLowerCase()).sort().join('|')
    === (pair.englishForms || []).map((f) => f.toLowerCase()).sort().join('|')
  );
  if (duplicate) {
    result.duplicates.push({
      english: pair.english,
      uzbek: pair.uzbek,
      reason: `Row ${rowNumber} appears to duplicate "${duplicate.english}"`,
    });
    result.warnings.push({
      row: rowNumber,
      message: `Row ${rowNumber} appears to duplicate "${duplicate.english}"`,
    });
    return;
  }
  result.pairs.push(pair);
};

const parseSeparatedLines = (rawText) => {
  const result = emptyParseResult();
  const lines = String(rawText || '')
    .split(/\r?\n/)
    .map((line) => line.trim());

  let currentTask = null;
  let rowNumber = 0;

  for (const line of lines) {
    rowNumber += 1;
    if (!line) continue;

    if (isTaskLine(line)) {
      currentTask = normalizeText(line).trim();
      result.tasks.push(currentTask);
      continue;
    }

    const match = line.match(SEPARATOR_PATTERN);
    if (!match) {
      result.skippedLines.push(line);
      result.warnings.push({
        row: rowNumber,
        message: `Row ${rowNumber} is not a vocabulary pair. Use: english | uzbek  or  english - uzbek`,
      });
      continue;
    }

    const pair = toPairRecord(match[1], match[2], currentTask ? { task: currentTask } : {});
    if (!pair) {
      if (!normalizeText(match[1])) {
        result.warnings.push({ row: rowNumber, message: `Row ${rowNumber} has no English word` });
      } else {
        result.warnings.push({ row: rowNumber, message: `Row ${rowNumber} has no Uzbek meaning` });
      }
      result.skippedLines.push(line);
      continue;
    }
    pairsPush(result, pair, rowNumber);
  }

  return finalizeParseResult(result);
};

const parsePairsFromText = (rawText) => {
  if (looksLikeCsv(rawText)) return parseCsvPairs(rawText);
  return parseSeparatedLines(rawText);
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

  const result = emptyParseResult();
  let currentTask = null;
  let pendingImageUrl = null;
  let rowNumber = 0;

  for (const token of tokens) {
    if (token.type === 'image') {
      pendingImageUrl = imageMetaBySrc[token.src]?.url || token.src;
      continue;
    }

    const line = token.text;
    rowNumber += 1;
    if (isTaskLine(line)) {
      currentTask = normalizeText(line).trim();
      result.tasks.push(currentTask);
      continue;
    }

    const pairMatch = line.match(SEPARATOR_PATTERN);
    if (!pairMatch) {
      result.skippedLines.push(line);
      continue;
    }

    const extras = {};
    if (currentTask) extras.task = currentTask;
    if (pendingImageUrl) {
      extras.imageUrl = pendingImageUrl;
      pendingImageUrl = null;
    }
    const pair = toPairRecord(pairMatch[1], pairMatch[2], extras);
    if (!pair) {
      result.skippedLines.push(line);
      continue;
    }
    pairsPush(result, pair, rowNumber);
  }

  if (pendingImageUrl && result.pairs.length > 0) {
    const last = result.pairs[result.pairs.length - 1];
    if (!last.imageUrl) last.imageUrl = pendingImageUrl;
  }

  return finalizeParseResult(result);
};

module.exports = {
  parsePairsFromText,
  parseCsvPairs,
  parseStructuredImport,
  SEPARATOR_PATTERN,
  isTaskLine,
  stripHtml,
};
