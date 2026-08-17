const { normalizeText, normalizeForComparison } = require('./textNormalizer');
const { splitVocabList } = require('./vocabList');

const splitStudentAnswers = (answer, answers) => {
  if (Array.isArray(answers) && answers.length > 0) {
    return splitVocabList(answers);
  }
  return splitVocabList(answer);
};

const checkAgainstAccepted = (accepted, studentParts) => {
  const acceptedKeys = new Set(accepted.map((item) => normalizeForComparison(item)).filter(Boolean));
  const studentKeys = studentParts.map((item) => normalizeForComparison(item)).filter(Boolean);

  if (acceptedKeys.size === 0 || studentKeys.length === 0) return false;

  // Any single accepted meaning/form is enough. Extra tokens must also be accepted
  // so "bormoq, ketmoq" is correct and "bormoq, kitob" is not.
  return studentKeys.every((key) => acceptedKeys.has(key));
};

const checkVocabAnswer = (word, { answer, answers, direction, expectedForm } = {}) => {
  if (!word || !direction) {
    throw Object.assign(new Error('Word and direction are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  const uzbekMeanings = splitVocabList(word.uzbek);
  const englishForms = splitVocabList(word.english);
  const studentParts = splitStudentAnswers(answer, answers);
  const userAnswer = studentParts.join(', ');

  let isCorrect = false;
  let correctAnswer = '';

  if (direction === 'en-to-uz') {
    correctAnswer = normalizeText(uzbekMeanings.join(', '));
    isCorrect = checkAgainstAccepted(uzbekMeanings, studentParts);
  } else if (direction === 'uz-to-en') {
    const accepted = expectedForm ? [expectedForm, ...englishForms] : englishForms;
    correctAnswer = normalizeText(expectedForm || englishForms.join(', '));
    isCorrect = checkAgainstAccepted(accepted, studentParts);
  } else if (direction === 'form') {
    const accepted = expectedForm ? [expectedForm] : englishForms;
    correctAnswer = normalizeText(expectedForm || englishForms[0] || word.english);
    isCorrect = checkAgainstAccepted(accepted, studentParts);
  } else {
    throw Object.assign(new Error('Invalid direction. Use "en-to-uz" or "uz-to-en"'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  return { isCorrect, correctAnswer, userAnswer, direction };
};

module.exports = { checkVocabAnswer, checkAgainstAccepted, splitStudentAnswers };
