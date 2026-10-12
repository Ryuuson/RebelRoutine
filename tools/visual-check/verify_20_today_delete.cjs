// Exercise deletion from the real edit-mode controller, including unsaved drafts and failed writes.
const assert = require('assert/strict');
const { subject } = require('./load_07_handlers.cjs');
const plain = value => JSON.parse(JSON.stringify(value));

(async () => {
  const app = subject();
  await app.addTask('今日事项', '原备注', ['knowledge'], [{ key: 'knowledge', points: 2 }]);
  const id = app.habits[0].id;
  app.openAction(id); await app.sheetOperation('edit');
  assert.equal(app.sheetMode, 'edit'); assert.equal(app.mainPage, '今日');
  app.editTitle = '尚未保存的标题'; app.editSubtitle = '尚未保存的备注';
  const before = plain(app.snapshot());
  await app.sheetOperation('delete');
  assert.equal(app.pendingConfirm, 'batch'); assert.equal(app.actionMenuId, id);
  assert.deepEqual(plain(app.snapshot()), before);
  assert.equal(app.onBackPress(), true); // Cancel confirmation; retain editor and draft.
  assert.equal(app.pendingConfirm, ''); assert.equal(app.sheetMode, 'edit');
  assert.equal(app.editTitle, '尚未保存的标题'); assert.equal(app.editingHabitId, id);
  assert.deepEqual(plain(app.snapshot()), before);
  await app.sheetOperation('delete');
  app.store.saveSnapshot = async () => { throw Error('write failed'); };
  await app.confirmOperation();
  assert.deepEqual(plain(app.snapshot()), before);
  assert.equal(app.pendingConfirm, 'batch'); assert.equal(app.editingHabitId, id);
  assert.equal(app.editTitle, '尚未保存的标题');
  app.store.saveSnapshot = async () => {};
  await app.confirmOperation();
  assert.equal(app.mainPage, '今日'); assert.equal(app.actionMenuId, -1); assert.equal(app.editingHabitId, -1);
  assert.ok(app.habits[0].deletedAt); assert.equal(app.habits[0].title, '今日事项');
  assert.equal(app.todayHabits().length, 0);
  await app.lifecycle(id, 'restore'); assert.equal(app.todayHabits().length, 1);

  // Completed items on today's list use the same edit entry and actual award refund.
  await app.toggleHabit(id); assert.equal(app.traitScore('knowledge'), 2);
  app.openAction(id); await app.sheetOperation('edit'); await app.sheetOperation('delete');
  assert.ok(app.confirmText.includes('相关成长会一并撤回'));
  assert.equal(app.traitScore('knowledge'), 2);
  await app.confirmOperation(); assert.equal(app.traitScore('knowledge'), 0);
  await app.lifecycle(id, 'restore'); assert.equal(app.traitScore('knowledge'), 2);
  assert.equal(app.habits[0].done, true); assert.equal(app.mainPage, '今日');
  console.log('PASS: today edit-mode delete, cancel preserves draft, failed write/retry, recycle restore and completed award refund.');
})().catch(error => { console.error(error); process.exitCode = 1; });
