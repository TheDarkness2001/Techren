const { normalizeText, normalizeForComparison } = require('./textNormalizer');

/**
 * Split a vocabulary field into unique display forms.
 * Commas separate forms/meanings of ONE item — they do not create new items.
 */
const splitVocabList = (value) => {
  const seen = new Set();
  const items = [];
  const source = Array.isArray(value) ? value : String(value || '').split(',');

  for (const part of source) {
    const display = normalizeText(part);
    if (!display) continue;
    const key = normalizeForComparison(display);
    if (seen.has(key)) continue;
    seen.add(key);
    items.push(display);
  }
  return items;
};

const joinVocabList = (value) => splitVocabList(value).join(', ');

const vocabKey = (english) =>
  splitVocabList(english)
    .map((item) => normalizeForComparison(item))
    .sort()
    .join('|');

const primaryFormKey = (english) => {
  const forms = splitVocabList(english);
  return forms.length ? normalizeForComparison(forms[0]) : '';
};

const canonicalizeVocabPair = (english, uzbek) => {
  const englishForms = splitVocabList(english);
  const uzbekMeanings = splitVocabList(uzbek);
  return {
    englishForms,
    uzbekMeanings,
    english: joinVocabList(englishForms),
    uzbek: joinVocabList(uzbekMeanings),
    key: vocabKey(englishForms),
    primaryKey: primaryFormKey(englishForms),
  };
};

const mergeVocabPair = (existing, incoming) => {
  const englishForms = splitVocabList([
    ...(existing.englishForms || splitVocabList(existing.english)),
    ...(incoming.englishForms || splitVocabList(incoming.english)),
  ]);
  const uzbekMeanings = splitVocabList([
    ...(existing.uzbekMeanings || splitVocabList(existing.uzbek)),
    ...(incoming.uzbekMeanings || splitVocabList(incoming.uzbek)),
  ]);
  return canonicalizeVocabPair(englishForms, uzbekMeanings);
};

const isSameVocabItem = (left, right) => {
  const a = canonicalizeVocabPair(left.english || left.englishForms, left.uzbek || left.uzbekMeanings);
  const b = canonicalizeVocabPair(right.english || right.englishForms, right.uzbek || right.uzbekMeanings);
  if (!a.key || !b.key) return false;
  return a.key === b.key || (a.primaryKey && a.primaryKey === b.primaryKey);
};

module.exports = {
  splitVocabList,
  joinVocabList,
  vocabKey,
  primaryFormKey,
  canonicalizeVocabPair,
  mergeVocabPair,
  isSameVocabItem,
};
