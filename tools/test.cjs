const path = require('path');
const { spawnSync } = require('child_process');

const suites = [
  'verify_14_m2.cjs',
  'verify_18_notes.cjs',
  'verify_navigation.cjs',
  'verify_trait_selection.cjs',
  'verify_20_today_delete.cjs',
  'verify_23_calendar.cjs',
  'verify_24_native_picker.cjs'
];

let failed = 0;
for (const suite of suites) {
  console.log(`TEST: ${suite}`);
  const result = spawnSync(process.execPath, [path.join(__dirname, 'visual-check', suite)], {
    stdio: 'inherit', env: process.env
  });
  if (result.error || result.status !== 0) {
    if (result.error) console.error(result.error.message);
    failed += 1;
  }
}
console.log(`${suites.length - failed}/${suites.length} suites passed.`);
process.exitCode = failed ? 1 : 0;
