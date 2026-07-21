const { normalizeText, normalizeForComparison } = require('./textNormalizer');

const checkVocabAnswer = (word, { answer, answers, direction }) => {
  if (!word || !direction) {
    throw Object.assign(new Error('Word and direction are required'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  let isCorrect = false;
  let correctAnswer = '';
  let userAnswer = '';

  if (direction === 'en-to-uz') {
    const meanings = word.uzbek
      .split(',')
      .map((m) => normalizeForComparison(m))
      .filter(Boolean);
    correctAnswer = normalizeText(word.uzbek);

    if (Array.isArray(answers) && answers.length > 0) {
      const studentAnswers = answers.map((a) => normalizeForComparison(a)).filter(Boolean);
      userAnswer = studentAnswers.join(', ');
      const sortedMeanings = [...meanings].sort();
      const sortedStudent = [...studentAnswers].sort();
      isCorrect = sortedMeanings.length === sortedStudent.length
        && sortedMeanings.every((m, i) => m === sortedStudent[i]);
    } else if (answer) {
      const normalizedAnswer = normalizeForComparison(answer);
      userAnswer = normalizedAnswer;
      isCorrect = meanings.some((m) => m === normalizedAnswer);
    }
  } else if (direction === 'uz-to-en') {
    const englishForms = word.english
      .split(',')
      .map((f) => normalizeForComparison(f))
      .filter(Boolean);
    correctAnswer = normalizeText(word.english);

    if (Array.isArray(answers) && answers.length > 0) {
      const studentAnswers = answers.map((a) => normalizeForComparison(a)).filter(Boolean);
      userAnswer = studentAnswers.join(', ');
      const sortedForms = [...englishForms].sort();
      const sortedStudent = [...studentAnswers].sort();
      isCorrect = sortedForms.length === sortedStudent.length
        && sortedForms.every((f, i) => f === sortedStudent[i]);
    } else if (answer) {
      const normalizedAnswer = normalizeForComparison(answer);
      userAnswer = normalizedAnswer;
      isCorrect = englishForms.some((form) => form === normalizedAnswer);
    }
  } else {
    throw Object.assign(new Error('Invalid direction. Use "en-to-uz" or "uz-to-en"'), { statusCode: 400, code: 'BAD_REQUEST' });
  }

  return { isCorrect, correctAnswer, userAnswer, direction };
};

module.exports = { checkVocabAnswer };
