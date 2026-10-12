// Execute the native picker bridge/controllers; SDK UI rendering is substituted, not claimed as device evidence.
const assert = require('assert/strict');
const { subject, load } = require('./load_07_handlers.cjs');
const { NativeDatePicker: Picker } = load('common/NativeDatePicker');
const { dateKey } = load('common/DayUtil');
const plain = value => JSON.parse(JSON.stringify(value));
const app = subject();
let options, cleared = 0, writes = 0;
app.getUIContext = () => ({
  getFocusController: () => ({ clearFocus: () => cleared++ }),
  showDatePickerDialog: value => { options = value; }
});
app.store.saveSnapshot = async () => writes++;
const before = plain(app.snapshot());
Picker.open(app.actionsUI, 'draft', false, '2026-10-05');
assert.equal(cleared, 1); assert.equal(dateKey(options.selected), '2026-10-05');
assert.equal(dateKey(options.start), '1970-01-01'); assert.equal(dateKey(options.end), '2100-12-31');
assert.equal(options.showTime, false); assert.equal(options.lunar, false);
assert.equal(options.onDateChange, undefined); // Scrolling/cancelling never commits a draft value.
assert.deepEqual(plain(app.snapshot()), before);
options.onDateAccept(new Date('2026-10-09T12:00:00'));
assert.equal(app.draftDay, '2026-10-09');
Picker.open(app.actionsUI, 'draft', false, ''); assert.equal(dateKey(options.selected), app.today);
Picker.open(app.actionsUI, 'draft', false, '2026-02-30'); assert.equal(dateKey(options.selected), app.today);
Picker.open(app.actionsUI, 'edit', true, '2027-01-01');
assert.equal(dateKey(options.selected), app.today); assert.equal(dateKey(options.end), app.today);
options.onDateAccept(new Date('2026-09-29T12:00:00')); assert.equal(app.editActivityDay, '2026-09-29');
options.onDateAccept(new Date('2026-10-01T12:00:00')); assert.equal(app.editActivityDay, '2026-09-29');
for (const [target, done, field] of [['edit',false,'editDay'],['batch',false,'batchDay'],
  ['deadline',false,'goalDeadline'],['progress',true,'progressDay'],['repeat',false,'repeatStart']]) {
  Picker.open(app.actionsUI,target,done,'2026-09-01');
  options.onDateAccept(new Date('2024-02-29T12:00:00')); assert.equal(app[field], '2024-02-29');
}
Picker.open(app.actionsUI,'deadline',false,'');
options.onDateAccept(new Date('invalid')); assert.equal(app.goalDeadline, '2024-02-29');
app.mutationBusy = true; options.onDateAccept(new Date('2026-09-01T12:00:00'));
assert.equal(app.goalDeadline, '2024-02-29'); app.mutationBusy = false;
app.actionsUI.draft.setDate('deadline',false,''); assert.equal(app.goalDeadline, '');
app.actionsUI.draft.setDate('draft',false,''); assert.equal(app.draftDay, '-');
assert.equal(writes,0); assert.deepEqual(plain(app.snapshot()),before);
console.log('PASS: native showDatePickerDialog, current/fallback date, cancel/no-write, confirmation, future bounds, leap day and all field targets.');
