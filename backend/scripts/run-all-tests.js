const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const scriptsDir = __dirname;
const scripts = fs
  .readdirSync(scriptsDir)
  .filter((name) => name.startsWith('test-') && name.endsWith('.js'))
  .sort();

if (scripts.length === 0) {
  console.error('No test scripts found.');
  process.exit(1);
}

let failed = 0;

for (const script of scripts) {
  console.log(`\n=== ${script} ===`);
  const result = spawnSync(process.execPath, [path.join(scriptsDir, script)], {
    stdio: 'inherit',
    env: process.env,
  });
  if (result.status !== 0) failed += 1;
}

console.log(`\n${scripts.length - failed}/${scripts.length} test suites passed.`);
process.exit(failed > 0 ? 1 : 0);
