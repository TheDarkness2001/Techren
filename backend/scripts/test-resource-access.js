const assert = require('assert');
const {
  assertParentChild,
  parentStudentScope,
  linkedChildIds,
} = require('../src/utils/resourceAccess');

const parent = { children: ['aaa', { _id: 'bbb' }] };

assert.deepStrictEqual(linkedChildIds(parent), ['aaa', 'bbb']);
assertParentChild(parent, 'aaa');
assertParentChild(parent, 'bbb');

let threw = false;
try {
  assertParentChild(parent, 'ccc');
} catch (e) {
  threw = true;
  assert.strictEqual(e.statusCode, 403);
  assert.strictEqual(e.code, 'FORBIDDEN');
}
assert.ok(threw, 'unlinked child must 403');

assert.strictEqual(parentStudentScope(parent, 'aaa'), 'aaa');
assert.deepStrictEqual(parentStudentScope(parent, null), { $in: ['aaa', 'bbb'] });

console.log('resourceAccess OK');
