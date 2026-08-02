/**
 * Maps Cursor / external IELTS Academic Reading generator JSON into TechRen exam shape.
 *
 * Expected input (generator format):
 * {
 *   title, module: "Academic"|"General", duration: 60, totalQuestions: 40,
 *   passages: [{ title, difficulty, content|passage, topic?, questions: [{ number, type, question, options?, answer, explanation }] }]
 * }
 */

const badRequest = (msg) =>
  Object.assign(new Error(msg), { statusCode: 400, code: 'BAD_REQUEST' });

const TYPE_MAP = {
  MULTIPLE_CHOICE: 'mcq',
  MCQ: 'mcq',
  TRUE_FALSE_NOT_GIVEN: 'tfng',
  TRUE_FALSE_NOTGIVEN: 'tfng',
  TFNG: 'tfng',
  YES_NO_NOT_GIVEN: 'ynng',
  YES_NO_NOTGIVEN: 'ynng',
  YNNG: 'ynng',
  MATCHING_HEADINGS: 'matching_headings',
  MATCHING_INFORMATION: 'matching',
  MATCHING_FEATURES: 'matching',
  MATCHING_SENTENCE_ENDINGS: 'matching',
  MATCHING: 'matching',
  SENTENCE_COMPLETION: 'sentence_completion',
  SUMMARY_COMPLETION: 'summary_completion',
  NOTES_COMPLETION: 'form_completion',
  TABLE_COMPLETION: 'table_completion',
  FLOW_CHART_COMPLETION: 'summary_completion',
  FLOWCHART_COMPLETION: 'summary_completion',
  DIAGRAM_LABEL_COMPLETION: 'diagram_labeling',
  DIAGRAM_LABELING: 'diagram_labeling',
  MAP_LABELING: 'map_labeling',
  SHORT_ANSWER: 'short_answer',
  SHORT_ANSWER_QUESTIONS: 'short_answer',
};

const LAYOUT_FOR_GENERATOR_TYPE = {
  NOTES_COMPLETION: 'notes',
  FLOW_CHART_COMPLETION: 'flow_chart',
  FLOWCHART_COMPLETION: 'flow_chart',
  SUMMARY_COMPLETION: 'summary',
  TABLE_COMPLETION: 'table',
};

const DIFFICULTY_HINT = {
  easy: 'easy',
  medium: 'medium',
  hard: 'hard',
  Easy: 'easy',
  Medium: 'medium',
  Hard: 'hard',
};

const normalizeTypeKey = (raw) =>
  String(raw || '')
    .trim()
    .toUpperCase()
    .replace(/[\s-]+/g, '_');

const mapQuestionType = (raw) => {
  const key = normalizeTypeKey(raw);
  const mapped = TYPE_MAP[key];
  if (!mapped) throw badRequest(`Unsupported question type: ${raw}`);
  return { key, type: mapped, layout: LAYOUT_FOR_GENERATOR_TYPE[key] || 'default' };
};

const normalizeAnswerList = (answer) => {
  if (answer == null) return [];
  if (Array.isArray(answer)) return answer.map((a) => String(a).trim()).filter(Boolean);
  if (typeof answer === 'object') {
    // { blank1: "x", blank2: "y" } or { primary: "x" }
    if (answer.primary != null) return [String(answer.primary).trim()].filter(Boolean);
    return Object.values(answer)
      .map((v) => String(v).trim())
      .filter(Boolean);
  }
  return [String(answer).trim()].filter(Boolean);
};

const normalizeOptions = (options, typeKey) => {
  if (Array.isArray(options) && options.length) {
    return options.map((o) => {
      if (o == null) return '';
      if (typeof o === 'string') return o;
      if (typeof o === 'object') return String(o.text || o.label || o.value || o);
      return String(o);
    });
  }
  if (typeKey === 'TRUE_FALSE_NOT_GIVEN' || typeKey === 'TFNG') {
    return ['True', 'False', 'Not Given'];
  }
  if (typeKey === 'YES_NO_NOT_GIVEN' || typeKey === 'YNNG') {
    return ['Yes', 'No', 'Not Given'];
  }
  return [];
};

const wordCount = (text) =>
  String(text || '')
    .trim()
    .split(/\s+/)
    .filter(Boolean).length;

const isReadingGeneratorPayload = (payload) => {
  const data = payload?.exam || payload;
  if (!data) return false;
  if (Array.isArray(data.passages) && data.passages.length > 0) return true;
  // Single-passage Cursor format: { title, passage, questions: [...] }
  if ((data.passage || data.content) && Array.isArray(data.questions) && data.questions.length > 0) {
    return true;
  }
  return false;
};

/** Normalize single-passage JSON into the multi-passage generator shape. */
const normalizeGeneratorPayload = (payload) => {
  const data = { ...(payload.exam || payload) };
  if (Array.isArray(data.passages) && data.passages.length > 0) return data;

  if ((data.passage || data.content) && Array.isArray(data.questions)) {
    const content = data.passage || data.content || '';
    return {
      title: data.title || 'IELTS Reading Passage',
      module: data.module || 'Academic',
      duration: data.duration || data.readingTimeMinutes || 20,
      totalQuestions: data.totalQuestions != null ? data.totalQuestions : data.questions.length,
      passages: [
        {
          title: data.title || 'Passage 1',
          topic: data.topic || null,
          difficulty: data.difficulty || 'Medium',
          content,
          estimated_band: data.estimatedBand ?? data.estimated_band ?? null,
          word_count: data.wordCount ?? data.word_count ?? undefined,
          readingTimeMinutes: data.readingTimeMinutes,
          questions: data.questions,
        },
      ],
      _singlePassage: true,
    };
  }
  return data;
};

/**
 * Convert generator JSON → { title, mode, trainingType, timers, sections: [...] }
 * ready for importExamJson's native section shape.
 */
const mapReadingGeneratorToExam = (payload, { subjectId, strict = true } = {}) => {
  const data = normalizeGeneratorPayload(payload);
  if (!data.title) throw badRequest('Reading import requires a title');

  const single = data._singlePassage === true || (Array.isArray(data.passages) && data.passages.length === 1);
  const expectedPassages = single ? 1 : 3;
  if (!Array.isArray(data.passages) || data.passages.length !== expectedPassages) {
    throw badRequest(
      single
        ? 'Single-passage import requires exactly 1 passage'
        : 'Full reading import requires exactly 3 passages'
    );
  }

  const moduleRaw = String(data.module || data.trainingType || 'Academic').toLowerCase();
  const trainingType = moduleRaw.includes('general') ? 'general' : 'academic';
  const duration = Number(data.duration || 60);

  let totalQ = 0;
  const typeSet = new Set();
  const topics = new Set();

  const sections = data.passages.map((p, pi) => {
    const content = p.content || p.passage || '';
    const qs = Array.isArray(p.questions) ? p.questions : [];
    if (!qs.length) throw badRequest(`Passage ${pi + 1} has no questions`);

    if (p.topic) topics.add(String(p.topic).toLowerCase());

    const questions = qs.map((q, qi) => {
      const { key, type, layout } = mapQuestionType(q.type);
      typeSet.add(key);
      totalQ += 1;
      const answers = normalizeAnswerList(q.answer ?? q.answers);
      const options = normalizeOptions(q.options, key);
      const explanation = q.explanation || '';
      const prompt = q.question || q.prompt || '';
      const number = q.number != null ? Number(q.number) : totalQ;

      const matchingKind =
        key === 'MATCHING_INFORMATION'
          ? 'information'
          : key === 'MATCHING_FEATURES'
            ? 'features'
            : key === 'MATCHING_SENTENCE_ENDINGS'
              ? 'sentence_endings'
              : key === 'MATCHING_HEADINGS'
                ? 'headings'
                : undefined;

      return {
        order: qi,
        number,
        type,
        prompt,
        instruction: q.instruction || '',
        options,
        answers,
        acceptedAnswers: answers.length
          ? {
              primary: answers[0],
              alternatives: answers.slice(1),
              synonyms: [],
              rejected: [],
              explanation,
            }
          : undefined,
        layout,
        points: q.points != null ? Number(q.points) : 1,
        metadata: {
          generatorType: key,
          generatorDifficulty: q.difficulty || p.difficulty || null,
          explanation,
          topic: p.topic || null,
          ...(matchingKind ? { matchingKind } : {}),
          ...(q.headings ? { headings: q.headings } : {}),
          ...(q.choices ? { choices: q.choices } : {}),
          ...(q.paragraphs ? { paragraphs: q.paragraphs } : {}),
          ...(q.imageUrl ? { imageUrl: q.imageUrl } : {}),
          ...(q.hotspots ? { hotspots: q.hotspots } : {}),
          raw: q.metadata || undefined,
        },
      };
    });

    const wc = p.word_count != null ? Number(p.word_count) : wordCount(content);
    const difficulty = DIFFICULTY_HINT[p.difficulty] || String(p.difficulty || '').toLowerCase() || 'medium';

    return {
      skill: 'reading',
      order: pi,
      title: p.title || `Passage ${pi + 1}`,
      instructions:
        p.instructions ||
        `Read Passage ${pi + 1} and answer the questions. Difficulty: ${p.difficulty || difficulty}.`,
      passage: content,
      passageFormat: p.passageFormat === 'html' ? 'html' : 'plain',
      part: pi + 1,
      questions,
      metadataNote: {
        topic: p.topic || null,
        difficulty,
        wordCount: wc,
        estimatedBand: p.estimated_band || p.estimatedBand || null,
      },
    };
  });

  if (strict) {
    const expected = data.totalQuestions != null
      ? Number(data.totalQuestions)
      : single
        ? totalQ
        : 40;
    if (!single && totalQ !== expected) {
      throw badRequest(`Expected ${expected} questions across 3 passages, got ${totalQ}`);
    }
    if (single && (totalQ < 10 || totalQ > 14)) {
      throw badRequest(`Single-passage import expects 10–14 questions, got ${totalQ}`);
    }
    if (typeSet.size < 2) {
      throw badRequest('Reading import must use more than one question type');
    }
    const topicNames = sections
      .map((s) => s.metadataNote.topic)
      .filter(Boolean)
      .map((t) => String(t).toLowerCase());
    if (topicNames.length >= 2 && new Set(topicNames).size !== topicNames.length) {
      throw badRequest('Passages must use different topics within one exam');
    }
  }

  const topicList = sections.map((s) => s.metadataNote.topic).filter(Boolean);
  const descriptionParts = [
    `Imported IELTS ${trainingType === 'academic' ? 'Academic' : 'General Training'} Reading`,
    `${sections.length} passages · ${totalQ} questions`,
    topicList.length ? `Topics: ${topicList.join(', ')}` : null,
  ].filter(Boolean);

  return {
    subjectId: subjectId || data.subjectId,
    title: data.title,
    description: data.description || descriptionParts.join(' · '),
    mode: 'reading',
    trainingType,
    difficulty: 'official',
    timers: {
      listeningMinutes: 40,
      readingMinutes: duration,
      writingMinutes: 60,
    },
    published: false,
    sections: sections.map(({ metadataNote, ...s }) => ({
      ...s,
      // stash generator meta on instructions footer is enough; keep section clean
      answerHighlights: metadataNote.topic
        ? `topic:${metadataNote.topic};difficulty:${metadataNote.difficulty};words:${metadataNote.wordCount}`
        : '',
    })),
    _generatorMeta: {
      totalQuestions: totalQ,
      questionTypes: [...typeSet],
      topics: topicList,
    },
  };
};

module.exports = {
  isReadingGeneratorPayload,
  normalizeGeneratorPayload,
  mapReadingGeneratorToExam,
  mapQuestionType,
  TYPE_MAP,
};
