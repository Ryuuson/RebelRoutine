import { BatchRequest, CompletionReward, RecordRef, RoutineSnapshot, HabitRecord, ActionRecord } from './RoutineModel';
import { RoutineEngine } from './RoutineEngine';
import { RoutineCommands } from './RoutineCommands';

/** Validate the whole selection before producing one candidate snapshot. Never persist here. */
export class RoutineBatch {
  static key(ref: RecordRef): string { return `${ref.action ? 'a' : 't'}:${ref.id}`; }

  static apply(state: RoutineSnapshot, request: BatchRequest, today: string,
    rewards: CompletionReward[] = [], now: number = Date.now()): RoutineSnapshot {
    const refs: RecordRef[] = request.refs;
    const operation: string = request.operation;
    if (!refs.length) { throw new Error('请先选择事项'); }
    if (new Set(refs.map((ref: RecordRef) => RoutineBatch.key(ref))).size !== refs.length) { throw new Error('选择中存在重复事项'); }
    if (!['complete', 'date', 'delete', 'restore', 'purge', 'reopen'].includes(operation)) { throw new Error('不支持的操作'); }
    if (operation === 'date' && request.day === undefined) { throw new Error('请选择日期'); }
    refs.forEach((ref: RecordRef) => {
      if (ref.action) {
        const item: ActionRecord | undefined = state.actions.find((record: ActionRecord) => record.id === ref.id);
        if (!item) { throw new Error('选中的旧记录已不存在'); }
        if (!['delete', 'restore', 'purge'].includes(operation)) { throw new Error('旧版记录仅支持删除、恢复和永久删除'); }
        RoutineBatch.checkDeleted(item.deletedAt, operation);
      } else {
        const item: HabitRecord | undefined = state.habits.find((record: HabitRecord) => record.id === ref.id);
        if (!item) { throw new Error('选中的事项已不存在'); }
        RoutineBatch.checkDeleted(item.deletedAt, operation);
        if (operation === 'complete' && (item.done || !RoutineEngine.visible(item))) { throw new Error('只能完成仍可操作的待办'); }
        if (operation === 'reopen' && (item.done || (!item.cancelled && !item.archived))) { throw new Error('只能恢复旧隐藏的待办'); }
        if (operation === 'date') {
          if (!item.done && !RoutineEngine.visible(item)) { throw new Error('请先恢复旧隐藏事项'); }
          RoutineCommands.validateDate(request.day ?? '', item.done, today);
        }
      }
    });
    let next: RoutineSnapshot = RoutineEngine.clone(state);
    refs.forEach((ref: RecordRef) => {
      if (ref.action) {
        next = operation === 'purge' ? RoutineCommands.purgeAction(next, ref.id) :
          RoutineCommands.actionLifecycle(next, ref.id, operation, now);
      } else if (operation === 'complete') {
        const item: HabitRecord = next.habits.find((record: HabitRecord) => record.id === ref.id)!;
        const reward: CompletionReward | undefined = rewards.find((entry: CompletionReward) => entry.id === ref.id);
        const keys: string[] = reward?.keys ?? item.assignedTraits ?? [];
        if (item.assignedTraits === undefined && !reward) { throw new Error('自动维度尚未分析完成'); }
        next = RoutineCommands.complete(next, ref.id, today, keys, reward?.points ?? item.assignedPoints ?? []);
      } else if (operation === 'date') {
        const item: HabitRecord = next.habits.find((record: HabitRecord) => record.id === ref.id)!;
        if (item.done) { item.activityDay = request.day; item.inferredDay = false; }
        else { item.day = request.day || undefined; }
        item.updatedAt = now;
        next = RoutineCommands.edit(next, item, today);
      } else { next = RoutineCommands.lifecycle(next, ref.id, operation); }
    });
    return next;
  }

  private static checkDeleted(deletedAt: number | undefined, operation: string): void {
    const needsDeleted: boolean = operation === 'restore' || operation === 'purge';
    if ((deletedAt !== undefined) !== needsDeleted) { throw new Error('事项状态已变化，请重新选择'); }
  }

  static removed(before: RoutineSnapshot, after: RoutineSnapshot): number {
    return before.traitTotals.reduce((sum, total) => sum + Math.max(0, total.score -
      (after.traitTotals.find((item) => item.key === total.key)?.score ?? 0)), 0);
  }
}
