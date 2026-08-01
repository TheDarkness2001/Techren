/**
 * IELTS Academic / General Training raw→band conversion for mock practice.
 * Uses local tables only — no external AI.
 */
const { evaluateAnswer, normalizeAnswer } = require('./ieltsAnswerEngine');

const ACADEMIC_BAND_TABLE = [
  { min: 39, band: 9.0 },
  { min: 37, band: 8.5 },
  { min: 35, band: 8.0 },
  { min: 33, band: 7.5 },
  { min: 30, band: 7.0 },
  { min: 27, band: 6.5 },
  { min: 23, band: 6.0 },
  { min: 19, band: 5.5 },
  { min: 15, band: 5.0 },
  { min: 13, band: 4.5 },
  { min: 10, band: 4.0 },
  { min: 8, band: 3.5 },
  { min: 6, band: 3.0 },
  { min: 4, band: 2.5 },
  { min: 2, band: 2.0 },
  { min: 1, band: 1.0 },
  { min: 0, band: 0 },
];

/** Approximate General Training Listening/Reading conversion (practice only). */
const GENERAL_BAND_TABLE = [
  { min: 39, band: 9.0 },
  { min: 37, band: 8.5 },
  { min: 35, band: 8.0 },
  { min: 32, band: 7.5 },
  { min: 30, band: 7.0 },
  { min: 26, band: 6.5 },
  { min: 23, band: 6.0 },
  { min: 18, band: 5.5 },
  { min: 16, band: 5.0 },
  { min: 13, band: 4.5 },
  { min: 11, band: 4.0 },
  { min: 8, band: 3.5 },
  { min: 6, band: 3.0 },
  { min: 4, band: 2.5 },
  { min: 2, band: 2.0 },
  { min: 1, band: 1.0 },
  { min: 0, band: 0 },
];

/** @deprecated use evaluateAnswer — kept for callers/tests */
const answersMatch = (studentAnswer, acceptedList) => {
  const result = evaluateAnswer(
    { answers: Array.isArray(acceptedList) ? acceptedList : [acceptedList], metadata: {} },
    studentAnswer
  );
  return result.correct;
};

const rawToBand = (raw, max = 40, trainingType = 'academic') => {
  if (raw == null || max <= 0) return null;
  const scaled = max === 40 ? raw : Math.round((raw / max) * 40);
  const table = trainingType === 'general' ? GENERAL_BAND_TABLE : ACADEMIC_BAND_TABLE;
  for (const row of table) {
    if (scaled >= row.min) return row.band;
  }
  return 0;
};

/**
 * @param {object[]} questions
 * @param {object} answersMap
 * @param {{ trainingType?: string }} [opts]
 */
const scoreObjectiveQuestions = (questions, answersMap, opts = {}) => {
  const trainingType = opts.trainingType || 'academic';
  let raw = 0;
  let max = 0;
  const review = [];

  for (const q of questions) {
    if (q.type === 'task1' || q.type === 'task2') continue;
    const pts = Number(q.points) || 1;
    max += pts;
    const studentAnswer = answersMap?.[String(q._id)] ?? answersMap?.get?.(String(q._id));
    const evaluated = evaluateAnswer(q, studentAnswer);
    if (evaluated.correct) raw += pts;
    review.push({
      questionId: q._id,
      correct: evaluated.correct,
      studentAnswer: evaluated.studentAnswer ?? studentAnswer ?? null,
      correctAnswers: evaluated.correctAnswers || q.answers || [],
      explanation: evaluated.explanation || '',
      reason: evaluated.reason || null,
      type: q.type,
      prompt: q.prompt || '',
      number: q.number,
      points: pts,
    });
  }

  return { raw, max, band: rawToBand(raw, max || 40, trainingType), review };
};

const meanBand = (...bands) => {
  const vals = bands.filter((b) => b != null && !Number.isNaN(Number(b))).map(Number);
  if (!vals.length) return null;
  const mean = vals.reduce((a, b) => a + b, 0) / vals.length;
  return Math.round(mean * 2) / 2;
};

module.exports = {
  normalizeAnswer,
  answersMatch,
  rawToBand,
  scoreObjectiveQuestions,
  meanBand,
  ACADEMIC_BAND_TABLE,
  GENERAL_BAND_TABLE,
};
