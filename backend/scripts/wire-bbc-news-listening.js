/**
 * Wire Learning "Listening" → BBC news using the existing Gold listening level.
 * - Renames English subject module label
 * - Renames Gold level to "BBC news"
 * - Unlocks that level for all exam groups tied to the English subject
 */
require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;

  const english = await db.collection('subjects').findOne({ name: /^english$/i, isDeleted: { $ne: true } });
  if (!english) throw new Error('English subject not found');

  const modules = Array.isArray(english.modules) ? english.modules : [];
  let moduleChanged = false;
  for (const m of modules) {
    if (m.key === 'listening' && m.label !== 'BBC news') {
      m.label = 'BBC news';
      m.icon = m.icon || 'headphones';
      moduleChanged = true;
    }
  }
  if (moduleChanged) {
    await db.collection('subjects').updateOne({ _id: english._id }, { $set: { modules } });
    console.log('Updated English subject module label: Listening → BBC news');
  } else {
    console.log('English subject module already labeled BBC news (or missing listening key)');
  }

  const goldLevel = await db.collection('levels').findOne({
    name: /^gold$/i,
    moduleType: 'listening',
    isDeleted: { $ne: true },
  });
  if (!goldLevel) throw new Error('Active Gold listening level not found');

  // Groups that use English subject (via subjectId on exam group if present, else all non-deleted)
  const groupFilter = {
    isDeleted: { $ne: true },
    $or: [{ subjectId: english._id }, { subject: english._id }],
  };
  let groups = await db.collection('examgroups').find(groupFilter).project({ _id: 1, name: 1 }).toArray();
  if (!groups.length) {
    // Fallback: unlock for every active exam group (common when subjectId not set on groups)
    groups = await db
      .collection('examgroups')
      .find({ isDeleted: { $ne: true } })
      .project({ _id: 1, name: 1 })
      .toArray();
    console.log('No subject-linked groups; unlocking for all active exam groups:', groups.length);
  } else {
    console.log('Unlocking for English-linked groups:', groups.map((g) => g.name).join(', '));
  }

  const groupIds = groups.map((g) => g._id);
  await db.collection('levels').updateOne(
    { _id: goldLevel._id },
    {
      $set: {
        name: 'BBC news',
        practiceUnlockedFor: groupIds,
        moduleType: 'listening',
      },
    }
  );
  console.log('Renamed level Gold → BBC news and set practiceUnlockedFor count=', groupIds.length);

  // Count exercises under this level's lessons
  const lessons = await db
    .collection('lessons')
    .find({ levelId: goldLevel._id, isDeleted: { $ne: true } })
    .project({ _id: 1 })
    .toArray();
  const lessonIds = lessons.map((l) => l._id);
  const exCount = await db.collection('listeningexercises').countDocuments({
    lessonId: { $in: lessonIds },
    isDeleted: { $ne: true },
  });
  console.log('BBC news exercises available:', exCount, 'across', lessons.length, 'lesson(s)');

  await mongoose.disconnect();
  console.log('Done.');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
