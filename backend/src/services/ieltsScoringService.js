/**
 * Approximate IELTS Academic Listening/Reading raw→band conversion (40 questions).
 * Values are midpoint estimates used for mock practice only.
 */
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

const normalizeAnswer = (value) =>
  String(value ?? '')
    .trim()
    .toLowerCase()
    .replace(/[.,;:!?'"()\-_/\\]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

const answersMatch = (studentAnswer, acceptedList) => {
  const student = normalizeAnswer(studentAnswer);
  if (!student) return false;
  const list = Array.isArray(acceptedList) ? acceptedList : [acceptedList];
  return list.some((accepted) => {
    const a = normalizeAnswer(accepted);
    if (!a) return false;
    if (a.includes('/') || a.includes('|')) {
      return a.split(/[/|]/).map((p) => p.trim()).filter(Boolean).some((p) => p === student);
    }
    return a === student;
  });
};

const rawToBand = (raw, max = 40) => {
  if (raw == null || max <= 0) return null;
  // Scale to 40-question equivalent when exam has fewer auto-scored items.
  const scaled = max === 40 ? raw : Math.round((raw / max) * 40);
  for (const row of ACADEMIC_BAND_TABLE) {
    if (scaled >= row.min) return row.band;
  }
  return 0;
};

const scoreObjectiveQuestions = (questions, answersMap) => {
  let raw = 0;
  let max = 0;
  const review = [];

  for (const q of questions) {
    if (q.type === 'task1' || q.type === 'task2') continue;
    const pts = Number(q.points) || 1;
    max += pts;
    const studentAnswer = answersMap?.[String(q._id)] ?? answersMap?.get?.(String(q._id));
    const correct = answersMatch(studentAnswer, q.answers || []);
    if (correct) raw += pts;
    review.push({
      questionId: q._id,
      correct,
      studentAnswer: studentAnswer ?? null,
      correctAnswers: q.answers || [],
    });
  }

  return { raw, max, band: rawToBand(raw, max || 40), review };
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
};
