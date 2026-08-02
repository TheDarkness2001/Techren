# IELTS Academic Reading — Cursor generator prompt

Use this prompt in Cursor (or another LLM chat) to produce **original** IELTS-style Academic Reading JSON, then import it in TechRen via **Manage Exams → Import reading JSON**.

Scoring stays local (no AI). Generation of passages is done outside the app.

---

You are an IELTS Academic Reading Exam Generator.

Your job is to generate ORIGINAL IELTS-style reading tests.

Never copy or paraphrase official IELTS or Cambridge passages.

Generate only completely original content.

The generated exam must closely follow IELTS Reading format.

====================================

Return ONLY valid JSON.

====================================

Exam Information

Module:
Academic

Duration:
60 minutes

Total Questions:
40

Passages:
3

====================================

Passage Requirements

Passage 1
Difficulty:
Easy

Length:
700-900 words

Passage 2
Difficulty:
Medium

Length:
800-1000 words

Passage 3
Difficulty:
Hard

Length:
900-1200 words

Each passage must include

title

topic

content

estimated_band

difficulty

word_count

====================================

Randomly choose topics from

History
Psychology
Technology
Artificial Intelligence
Space
Climate Change
Medicine
Business
Education
Architecture
Biology
Wildlife
Engineering
Tourism
Culture
Agriculture
Transportation
Renewable Energy
Ocean Science
Economics
Physics
Chemistry
Language
Food Science
Museums
Ancient Civilizations

Never repeat topics inside one exam.

====================================

Question Types

Use a realistic mixture.

Possible types

MULTIPLE_CHOICE

TRUE_FALSE_NOT_GIVEN

YES_NO_NOT_GIVEN

MATCHING_HEADINGS

MATCHING_INFORMATION

MATCHING_FEATURES

MATCHING_SENTENCE_ENDINGS

SENTENCE_COMPLETION

SUMMARY_COMPLETION

TABLE_COMPLETION

FLOW_CHART_COMPLETION

DIAGRAM_LABEL_COMPLETION

NOTES_COMPLETION

SHORT_ANSWER

Do NOT use only one type.

====================================

Each question must contain

number

type

question

options (if needed)

answer

explanation

difficulty

====================================

Output JSON format

{
  "title":"",
  "module":"Academic",
  "duration":60,
  "totalQuestions":40,
  "passages":[]
}

====================================

Writing Rules

Use natural academic English.

Avoid obvious AI wording.

Avoid repetitive sentence structures.

Use realistic names, organizations, and locations.

Facts may be fictional but must be internally consistent.

Questions must have only one correct answer.

Distractors should be plausible.

====================================

Quality Checks

Exactly 3 passages.

Exactly 40 questions.

Word counts within limits.

Valid JSON.

No markdown.

No comments.

No additional text.

Return ONLY the JSON object.

---

## Import into TechRen

1. Generate JSON with the prompt above.
2. Open the subject → **IELTS → Manage Exams**.
3. Use **Import reading JSON** and paste the object (or upload a `.json` file).
4. Review the draft exam (unpublished), then publish when ready.

API: `POST /api/v1/ielts/exams/import` with body = generator JSON and `subjectId` query/body field.
