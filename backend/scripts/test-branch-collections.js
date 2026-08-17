/**
 * Unit checks for founder branch collection totals (no DB).
 * Run: node scripts/test-branch-collections.js
 */
const assert = require('assert');
const { aggregateBranchCollections } = require('../src/utils/branchCollections');

{
  const { items, totals } = aggregateBranchCollections({
    branches: [
      { _id: 'b1', name: 'Main' },
      { _id: 'b2', name: 'Chilonzor' },
    ],
    students: [
      { _id: 's1', branchId: 'b1' },
      { _id: 's2', branchId: 'b1' },
      { _id: 's3', branchId: 'b2' },
    ],
    duesMap: new Map([
      ['s1', { courses: [{ amountDue: 600, amountPaid: 200 }], amountRemaining: 400 }],
      ['s2', { courses: [{ amountDue: 500, amountPaid: 500 }], amountRemaining: 0 }],
      ['s3', { courses: [{ amountDue: 300, amountPaid: 0 }], amountRemaining: 300 }],
    ]),
  });

  assert.strictEqual(items.length, 2);
  const main = items.find((row) => row.branchName === 'Main');
  const chilonzor = items.find((row) => row.branchName === 'Chilonzor');
  assert.strictEqual(main.expected, 1100);
  assert.strictEqual(main.collected, 700);
  assert.strictEqual(main.remaining, 400);
  assert.strictEqual(main.unpaidCount, 1);
  assert.strictEqual(chilonzor.expected, 300);
  assert.strictEqual(chilonzor.collected, 0);
  assert.strictEqual(totals.expected, 1400);
  assert.strictEqual(totals.collected, 700);
  assert.strictEqual(totals.remaining, 700);
}

{
  const { items } = aggregateBranchCollections({
    branches: [{ _id: 'b1', name: 'Main' }],
    students: [],
    duesMap: new Map(),
  });
  assert.strictEqual(items.length, 1);
  assert.strictEqual(items[0].expected, 0);
  assert.strictEqual(items[0].studentCount, 0);
}

console.log('test-branch-collections: ok');
