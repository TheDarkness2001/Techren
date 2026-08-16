const assert = require('assert');
const { parsePagination, MAX_LIMIT } = require('../src/utils/pagination');

assert.strictEqual(MAX_LIMIT, 500);

const capped = parsePagination({ page: '1', limit: '200' });
assert.strictEqual(capped.limit, 200);
assert.strictEqual(capped.skip, 0);

const maxed = parsePagination({ limit: '999' });
assert.strictEqual(maxed.limit, 500);

const def = parsePagination({});
assert.strictEqual(def.limit, 20);
assert.strictEqual(def.page, 1);

console.log('pagination OK');
