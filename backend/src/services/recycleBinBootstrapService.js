const Word = require('../models/Word');
const RecycleBin = require('../models/RecycleBin');
const recycleBinService = require('./recycleBinService');

const ensureRecycleBinDemoContent = async () => {
  const exists = await RecycleBin.exists({ cascadeGroupId: 'bootstrap-demo' });
  if (exists) return;

  const word = await Word.findOne({ english: 'good' });
  if (!word) return;

  await recycleBinService.softDelete('words', word._id, {
    deletedBy: 'system',
    moduleType: 'words',
    cascadeGroupId: 'bootstrap-demo',
  });
};

module.exports = { ensureRecycleBinDemoContent };
