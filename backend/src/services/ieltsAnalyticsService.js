const IeltsAttempt = require('../models/IeltsAttempt');
const IeltsExam = require('../models/IeltsExam');
const IeltsQuestion = require('../models/IeltsQuestion');

/**
 * Aggregate attempt review data — no external AI.
 */
const staffOverview = async ({ subjectId, examId, days = 90 } = {}) => {
  const since = new Date(Date.now() - Number(days) * 24 * 60 * 60 * 1000);
  const filter = {
    status: { $in: ['submitted', 'scored'] },
    submittedAt: { $gte: since },
  };
  if (examId) filter.examId = examId;
  if (subjectId) {
    const exams = await IeltsExam.find({ subjectId }).select('_id');
    filter.examId = { $in: exams.map((e) => e._id) };
  }

  const attempts = await IeltsAttempt.find(filter).limit(2000);
  const bandBuckets = {};
  const typeStats = {};
  let totalAttempts = attempts.length;
  let listeningSum = 0;
  let readingSum = 0;
  let listeningN = 0;
  let readingN = 0;

  for (const a of attempts) {
    const overall = a.scores?.overallBand;
    if (overall != null) {
      const key = String(overall);
      bandBuckets[key] = (bandBuckets[key] || 0) + 1;
    }
    if (a.scores?.listeningBand != null) {
      listeningSum += a.scores.listeningBand;
      listeningN += 1;
    }
    if (a.scores?.readingBand != null) {
      readingSum += a.scores.readingBand;
      readingN += 1;
    }
    const review = a.questionReview || [];
    for (const r of review) {
      const t = r.type || 'unknown';
      if (!typeStats[t]) typeStats[t] = { correct: 0, total: 0 };
      typeStats[t].total += 1;
      if (r.correct) typeStats[t].correct += 1;
    }
  }

  const byType = Object.entries(typeStats).map(([type, s]) => ({
    type,
    total: s.total,
    correct: s.correct,
    accuracy: s.total ? Math.round((s.correct / s.total) * 1000) / 10 : 0,
  }));

  return {
    totalAttempts,
    averageListeningBand: listeningN ? Math.round((listeningSum / listeningN) * 10) / 10 : null,
    averageReadingBand: readingN ? Math.round((readingSum / readingN) * 10) / 10 : null,
    bandDistribution: bandBuckets,
    questionTypeAccuracy: byType.sort((a, b) => a.accuracy - b.accuracy),
    days: Number(days),
  };
};

const studentAnalytics = async (studentId, { days = 180 } = {}) => {
  const since = new Date(Date.now() - Number(days) * 24 * 60 * 60 * 1000);
  const attempts = await IeltsAttempt.find({
    studentId,
    status: { $in: ['submitted', 'scored'] },
    submittedAt: { $gte: since },
  })
    .sort({ submittedAt: 1 })
    .limit(200);

  const trend = attempts.map((a) => ({
    attemptId: a._id,
    examId: a.examId,
    submittedAt: a.submittedAt,
    listeningBand: a.scores?.listeningBand ?? null,
    readingBand: a.scores?.readingBand ?? null,
    writingBand: a.scores?.writingBand ?? null,
    overallBand: a.scores?.overallBand ?? null,
  }));

  const typeStats = {};
  for (const a of attempts) {
    for (const r of a.questionReview || []) {
      const t = r.type || 'unknown';
      if (!typeStats[t]) typeStats[t] = { correct: 0, total: 0 };
      typeStats[t].total += 1;
      if (r.correct) typeStats[t].correct += 1;
    }
  }

  const strengths = [];
  const weaknesses = [];
  for (const [type, s] of Object.entries(typeStats)) {
    if (s.total < 3) continue;
    const accuracy = s.correct / s.total;
    const row = {
      type,
      accuracy: Math.round(accuracy * 1000) / 10,
      total: s.total,
    };
    if (accuracy >= 0.7) strengths.push(row);
    else if (accuracy < 0.5) weaknesses.push(row);
  }
  strengths.sort((a, b) => b.accuracy - a.accuracy);
  weaknesses.sort((a, b) => a.accuracy - b.accuracy);

  const latest = trend.length ? trend[trend.length - 1] : null;

  return {
    attemptsCompleted: attempts.length,
    latestBands: latest,
    bandTrend: trend,
    strengths,
    weaknesses,
    days: Number(days),
  };
};

const examQuestionDifficulty = async (examId) => {
  const attempts = await IeltsAttempt.find({
    examId,
    status: { $in: ['submitted', 'scored'] },
  }).limit(1000);
  const questions = await IeltsQuestion.find({ examId }).sort({ number: 1 });
  const byQ = {};
  for (const q of questions) {
    byQ[String(q._id)] = {
      questionId: q._id,
      number: q.number,
      type: q.type,
      prompt: (q.prompt || '').slice(0, 120),
      correct: 0,
      total: 0,
      avgSeconds: 0,
      secondsSum: 0,
      secondsN: 0,
    };
  }
  for (const a of attempts) {
    for (const r of a.questionReview || []) {
      const id = String(r.questionId);
      if (!byQ[id]) continue;
      byQ[id].total += 1;
      if (r.correct) byQ[id].correct += 1;
    }
    if (a.timePerQuestion) {
      for (const [qid, secs] of a.timePerQuestion.entries()) {
        if (!byQ[qid]) continue;
        byQ[qid].secondsSum += Number(secs) || 0;
        byQ[qid].secondsN += 1;
      }
    }
  }
  return Object.values(byQ).map((row) => ({
    ...row,
    accuracy: row.total ? Math.round((row.correct / row.total) * 1000) / 10 : null,
    avgSeconds: row.secondsN ? Math.round(row.secondsSum / row.secondsN) : null,
    difficultyHint:
      row.total >= 5
        ? row.correct / row.total < 0.4
          ? 'hard'
          : row.correct / row.total > 0.8
            ? 'easy'
            : 'medium'
        : 'insufficient_data',
  }));
};

module.exports = {
  staffOverview,
  studentAnalytics,
  examQuestionDifficulty,
};
