/**
 * Lock BBC news listening for all groups.
 * Clears practiceUnlockedFor on every listening level so staff must re-grant access per group.
 */
require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  await mongoose.connect(process.env.MONGO_URI);
  const db = mongoose.connection.db;

  const result = await db.collection('levels').updateMany(
    { moduleType: 'listening', isDeleted: { $ne: true } },
    { $set: { practiceUnlockedFor: [] } }
  );

  console.log(`Locked BBC listening levels: matched=${result.matchedCount}, modified=${result.modifiedCount}`);
  await mongoose.disconnect();
  process.exit(0);
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
