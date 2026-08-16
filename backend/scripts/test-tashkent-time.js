const assert = require('assert');
const {
  getTashkentParts,
  tashkentBillingPeriod,
  billingPeriodFromQuery,
  addCalendarDays,
} = require('../src/utils/classWindow');

const parts = getTashkentParts(new Date('2026-01-01T00:30:00Z'));
assert.strictEqual(parts.dateString, '2026-01-01');
assert.strictEqual(parts.year, 2026);
assert.strictEqual(parts.month, 1);
assert.strictEqual(parts.dayOfMonth, 1);

const nyeUtc = getTashkentParts(new Date('2025-12-31T20:00:00Z'));
assert.strictEqual(nyeUtc.dateString, '2026-01-01');
assert.strictEqual(nyeUtc.month, 1);
assert.strictEqual(nyeUtc.year, 2026);

const period = tashkentBillingPeriod(new Date('2025-12-31T20:00:00Z'));
assert.deepStrictEqual(period, { month: 1, year: 2026 });

assert.deepStrictEqual(billingPeriodFromQuery({}), tashkentBillingPeriod());
assert.deepStrictEqual(billingPeriodFromQuery({ month: '8', year: '2026' }), { month: 8, year: 2026 });

assert.strictEqual(addCalendarDays('2026-03-01', -2), '2026-02-27');
assert.strictEqual(addCalendarDays('2026-01-01', 0), '2026-01-01');

console.log('test-tashkent-time: ok');
