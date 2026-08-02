/**
 * Seed Typing Speed Challenge word lists + code snippets.
 * Usage: node scripts/seed-typing-content.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const mongoose = require('mongoose');
const TypingContent = require('../src/models/TypingContent');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/techren_edu';

const PROGRAMMING_WORDS = [
  'function', 'const', 'let', 'return', 'boolean', 'string', 'React', 'MongoDB', 'Express', 'Python',
  'Arduino', 'compile', 'algorithm', 'database', 'frontend', 'backend', 'server', 'API', 'variable',
  'object', 'class', 'inheritance', 'git', 'github', 'terminal', 'linux', 'docker', 'css', 'html',
  'javascript', 'typescript', 'promise', 'callback', 'async', 'await', 'node', 'array', 'loop',
  'debug', 'deploy', 'package', 'module', 'import', 'export', 'interface', 'schema', 'query',
  'router', 'middleware', 'controller', 'service', 'model', 'component', 'state', 'props', 'hook',
];

const ENGLISH = {
  easy: [
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have', 'I', 'it', 'for', 'not', 'on', 'with',
    'he', 'as', 'you', 'do', 'at', 'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her', 'she',
    'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there', 'their', 'what', 'so', 'up', 'out', 'if',
    'about', 'who', 'get', 'which', 'go', 'me', 'when', 'make', 'can', 'like', 'time', 'no', 'just', 'him',
  ],
  medium: [
    'people', 'into', 'year', 'your', 'good', 'some', 'could', 'them', 'see', 'other', 'than', 'then',
    'now', 'look', 'only', 'come', 'its', 'over', 'think', 'also', 'back', 'after', 'use', 'two', 'how',
    'our', 'work', 'first', 'well', 'way', 'even', 'new', 'want', 'because', 'any', 'these', 'give',
    'day', 'most', 'us', 'system', 'program', 'computer', 'student', 'teacher', 'practice', 'result',
  ],
  hard: [
    'although', 'however', 'therefore', 'necessary', 'available', 'important', 'development', 'experience',
    'information', 'environment', 'government', 'education', 'technology', 'performance', 'knowledge',
    'understanding', 'particular', 'significant', 'opportunity', 'community', 'application', 'management',
    'organization', 'professional', 'communication', 'responsibility', 'achievement', 'challenge',
  ],
  expert: [
    'sophisticated', 'implementation', 'architecture', 'infrastructure', 'authentication', 'authorization',
    'asynchronous', 'concurrency', 'encapsulation', 'polymorphism', 'serialization', 'orchestration',
    'observability', 'idempotent', 'deterministic', 'heuristic', 'abstraction', 'dependency',
    'compatibility', 'scalability', 'throughput', 'latency', 'resilience', 'instrumentation',
  ],
};

const CODE_SNIPPETS = [
  {
    title: 'JS calculateAge',
    language: 'javascript',
    difficulty: 'easy',
    code: 'function calculateAge(age){\n    return age + 10;\n}',
  },
  {
    title: 'JS user object',
    language: 'javascript',
    difficulty: 'medium',
    code: 'const user={\n name:"John",\n age:22\n}',
  },
  {
    title: 'Python range print',
    language: 'python',
    difficulty: 'easy',
    code: 'for i in range(10):\n    print(i)',
  },
  {
    title: 'Arduino setup',
    language: 'arduino',
    difficulty: 'medium',
    code: 'void setup(){\n Serial.begin(9600);\n}',
  },
  {
    title: 'JS async fetch',
    language: 'javascript',
    difficulty: 'hard',
    code: 'async function load(){\n  const res = await fetch("/api");\n  return res.json();\n}',
  },
  {
    title: 'Python list comp',
    language: 'python',
    difficulty: 'medium',
    code: 'squares = [n * n for n in range(10)]\nprint(squares)',
  },
  {
    title: 'TS interface',
    language: 'typescript',
    difficulty: 'hard',
    code: 'interface User {\n  id: string;\n  name: string;\n}\nconst u: User = { id: "1", name: "Ada" };',
  },
  {
    title: 'Express route',
    language: 'javascript',
    difficulty: 'medium',
    code: 'app.get("/health", (req, res) => {\n  res.json({ ok: true });\n});',
  },
];

async function upsertWordList(kind, difficulty, title, words) {
  await TypingContent.findOneAndUpdate(
    { kind, difficulty, title },
    {
      kind,
      difficulty,
      title,
      words,
      code: '',
      language: null,
      published: true,
      isDeleted: false,
    },
    { upsert: true, new: true }
  );
}

async function upsertCode(snippet) {
  await TypingContent.findOneAndUpdate(
    { kind: 'code', title: snippet.title },
    {
      kind: 'code',
      title: snippet.title,
      difficulty: snippet.difficulty,
      language: snippet.language,
      words: [],
      code: snippet.code,
      published: true,
      isDeleted: false,
    },
    { upsert: true, new: true }
  );
}

async function main() {
  await mongoose.connect(MONGO_URI);
  console.log('Connected');

  for (const [difficulty, words] of Object.entries(ENGLISH)) {
    await upsertWordList('english', difficulty, `English ${difficulty}`, words);
    console.log(`English ${difficulty}: ${words.length} words`);
  }

  await upsertWordList('programming', 'easy', 'Programming basics', PROGRAMMING_WORDS.slice(0, 20));
  await upsertWordList('programming', 'medium', 'Programming core', PROGRAMMING_WORDS);
  await upsertWordList('programming', 'hard', 'Programming advanced', PROGRAMMING_WORDS);
  await upsertWordList('programming', 'expert', 'Programming expert', PROGRAMMING_WORDS);
  console.log(`Programming lists seeded (${PROGRAMMING_WORDS.length} words)`);

  for (const snippet of CODE_SNIPPETS) {
    await upsertCode(snippet);
  }
  console.log(`Code snippets: ${CODE_SNIPPETS.length}`);

  const count = await TypingContent.countDocuments({ isDeleted: { $ne: true } });
  console.log(`Total TypingContent docs: ${count}`);
  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
