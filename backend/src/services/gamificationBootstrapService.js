const Achievement = require('../models/Achievement');

const ACHIEVEMENT_CATALOG = [
  {
    code: 'FIRST_STEP',
    title: 'First Step',
    description: 'Earn your first XP',
    icon: 'star',
    category: 'milestone',
    criteria: { type: 'totalXp', value: 1 },
    xpReward: 10,
  },
  {
    code: 'STREAK_3',
    title: 'On Fire',
    description: 'Maintain a 3-day practice streak',
    icon: 'local_fire_department',
    category: 'streak',
    criteria: { type: 'streak', value: 3 },
    xpReward: 30,
  },
  {
    code: 'STREAK_7',
    title: 'Week Warrior',
    description: 'Maintain a 7-day practice streak',
    icon: 'whatshot',
    category: 'streak',
    criteria: { type: 'streak', value: 7 },
    xpReward: 70,
  },
  {
    code: 'STREAK_14',
    title: 'Dedicated Learner',
    description: 'Maintain a 14-day practice streak',
    icon: 'emoji_events',
    category: 'streak',
    criteria: { type: 'streak', value: 14 },
    xpReward: 140,
  },
  {
    code: 'WORDS_100',
    title: 'Word Smith',
    description: 'Earn 100 XP in Words',
    icon: 'abc',
    category: 'words',
    criteria: { type: 'moduleXp', module: 'words', value: 100 },
    xpReward: 50,
  },
  {
    code: 'SENTENCES_50',
    title: 'Sentence Builder',
    description: 'Earn 50 XP in Sentences',
    icon: 'translate',
    category: 'sentences',
    criteria: { type: 'moduleXp', module: 'sentences', value: 50 },
    xpReward: 50,
  },
  {
    code: 'LISTENING_75',
    title: 'Good Ear',
    description: 'Earn 75 XP in Listening',
    icon: 'headphones',
    category: 'listening',
    criteria: { type: 'moduleXp', module: 'listening', value: 75 },
    xpReward: 50,
  },
  {
    code: 'VIDEO_50',
    title: 'Screen Star',
    description: 'Earn 50 XP in Video',
    icon: 'play_circle',
    category: 'video',
    criteria: { type: 'moduleXp', module: 'video', value: 50 },
    xpReward: 50,
  },
  {
    code: 'XP_500',
    title: 'Rising Star',
    description: 'Reach 500 total XP',
    icon: 'military_tech',
    category: 'milestone',
    criteria: { type: 'totalXp', value: 500 },
    xpReward: 100,
  },
  {
    code: 'XP_1000',
    title: 'Scholar',
    description: 'Reach 1000 total XP',
    icon: 'school',
    category: 'milestone',
    criteria: { type: 'totalXp', value: 1000 },
    xpReward: 200,
  },
];

const seedAchievements = async () => {
  for (const item of ACHIEVEMENT_CATALOG) {
    await Achievement.findOneAndUpdate({ code: item.code }, item, { upsert: true, new: true });
  }
};

const ensureGamificationDemoContent = async () => {
  const Student = require('../models/Student');
  const gamificationService = require('./gamificationService');

  await seedAchievements();

  const student = await Student.findOne({ email: 'student@techren.uz' });
  if (!student) return;

  const profile = await gamificationService.getOrCreateProfile(student._id);
  if (profile.totalXp > 0) return;

  await gamificationService.awardXp(student._id, {
    module: 'words',
    amount: 45,
    reason: 'demo_bootstrap',
  });
};

module.exports = { seedAchievements, ACHIEVEMENT_CATALOG, ensureGamificationDemoContent };
