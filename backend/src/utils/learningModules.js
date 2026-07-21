/** Default module catalogs keyed by subject profile. Adding modules here expands new subjects without Flutter changes. */

const LANGUAGE_MODULES = [
  { key: 'words', label: 'Words', category: 'learning', icon: 'spellcheck', audience: 'all' },
  { key: 'sentences', label: 'Sentences', category: 'learning', icon: 'format_quote', audience: 'all' },
  { key: 'listening', label: 'Listening', category: 'learning', icon: 'headphones', audience: 'all' },
  { key: 'video', label: 'Video Lessons', category: 'learning', icon: 'play_circle', audience: 'all' },
  { key: 'grammar', label: 'Grammar', category: 'learning', icon: 'menu_book', audience: 'all' },
  { key: 'flashcards', label: 'Flashcards', category: 'learning', icon: 'style', audience: 'all' },
  { key: 'quiz', label: 'Quiz', category: 'assessment', icon: 'quiz', audience: 'all' },
  { key: 'exam', label: 'Exam', category: 'assessment', icon: 'emoji_events', audience: 'all' },
  { key: 'cms', label: 'Learning CMS', category: 'management', icon: 'edit_note', audience: 'staff' },
  { key: 'import', label: 'Content Import', category: 'management', icon: 'upload_file', audience: 'staff' },
  { key: 'progress', label: 'Student Progress', category: 'statistics', icon: 'insights', audience: 'staff' },
];

const PROGRAMMING_MODULES = [
  { key: 'lessons', label: 'Lessons', category: 'learning', icon: 'school', audience: 'all' },
  { key: 'projects', label: 'Projects', category: 'learning', icon: 'folder_special', audience: 'all' },
  { key: 'exercises', label: 'Exercises', category: 'learning', icon: 'code', audience: 'all' },
  { key: 'challenges', label: 'Challenges', category: 'learning', icon: 'bolt', audience: 'all' },
  { key: 'video', label: 'Videos', category: 'learning', icon: 'play_circle', audience: 'all' },
  { key: 'quiz', label: 'Quiz', category: 'assessment', icon: 'quiz', audience: 'all' },
  { key: 'exam', label: 'Exam', category: 'assessment', icon: 'emoji_events', audience: 'all' },
  { key: 'cms', label: 'Learning CMS', category: 'management', icon: 'edit_note', audience: 'staff' },
  { key: 'progress', label: 'Student Progress', category: 'statistics', icon: 'insights', audience: 'staff' },
];

const STEM_MODULES = [
  { key: 'lessons', label: 'Lessons', category: 'learning', icon: 'school', audience: 'all' },
  { key: 'practice', label: 'Practice', category: 'learning', icon: 'calculate', audience: 'all' },
  { key: 'examples', label: 'Worked Examples', category: 'learning', icon: 'lightbulb', audience: 'all' },
  { key: 'video', label: 'Videos', category: 'learning', icon: 'play_circle', audience: 'all' },
  { key: 'quiz', label: 'Quiz', category: 'assessment', icon: 'quiz', audience: 'all' },
  { key: 'exam', label: 'Exam', category: 'assessment', icon: 'emoji_events', audience: 'staff' },
  { key: 'cms', label: 'Learning CMS', category: 'management', icon: 'edit_note', audience: 'staff' },
  { key: 'progress', label: 'Student Progress', category: 'statistics', icon: 'insights', audience: 'staff' },
];

const SUBJECT_COLORS = [
  '#2563EB', '#0D9488', '#7C3AED', '#DB2777', '#EA580C',
  '#0891B2', '#4F46E5', '#059669', '#CA8A04', '#DC2626',
];

const SUBJECT_ICONS = {
  english: 'translate',
  russian: 'translate',
  german: 'translate',
  french: 'translate',
  programming: 'code',
  it: 'computer',
  computer: 'computer',
  mathematics: 'functions',
  math: 'functions',
  physics: 'science',
  chemistry: 'science',
  biology: 'eco',
  ielts: 'school',
  toefl: 'school',
  sat: 'school',
};

const hashString = (value) => {
  let hash = 0;
  const text = String(value || '');
  for (let i = 0; i < text.length; i += 1) {
    hash = (hash << 5) - hash + text.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
};

const inferProfile = (name = '') => {
  const lower = name.toLowerCase();
  if (/(program|coding|python|java|it\b|computer)/.test(lower)) return 'programming';
  if (/(math|physics|chemistry|biology|stem)/.test(lower)) return 'stem';
  return 'language';
};

const defaultModulesForSubject = (name) => {
  const profile = inferProfile(name);
  if (profile === 'programming') return PROGRAMMING_MODULES.map((m) => ({ ...m, enabled: true }));
  if (profile === 'stem') return STEM_MODULES.map((m) => ({ ...m, enabled: true }));
  return LANGUAGE_MODULES.map((m) => ({ ...m, enabled: true }));
};

const defaultColorForSubject = (name) => SUBJECT_COLORS[hashString(name) % SUBJECT_COLORS.length];

const defaultIconForSubject = (name = '') => {
  const lower = name.toLowerCase();
  for (const [key, icon] of Object.entries(SUBJECT_ICONS)) {
    if (lower.includes(key)) return icon;
  }
  return inferProfile(name) === 'programming' ? 'code' : 'menu_book';
};

const ensureSubjectLearningFields = (subject) => {
  const name = subject.name || 'Subject';
  const modules = Array.isArray(subject.modules) && subject.modules.length
    ? subject.modules
    : defaultModulesForSubject(name);
  return {
    icon: subject.icon || defaultIconForSubject(name),
    color: subject.color || defaultColorForSubject(name),
    description: subject.description || '',
    modules,
  };
};

module.exports = {
  LANGUAGE_MODULES,
  PROGRAMMING_MODULES,
  STEM_MODULES,
  defaultModulesForSubject,
  defaultColorForSubject,
  defaultIconForSubject,
  ensureSubjectLearningFields,
  catalogModulesForProfile: (profile) => {
    if (profile === 'programming') return PROGRAMMING_MODULES.map((m) => ({ ...m, enabled: true }));
    if (profile === 'stem') return STEM_MODULES.map((m) => ({ ...m, enabled: true }));
    return LANGUAGE_MODULES.map((m) => ({ ...m, enabled: true }));
  },
};
