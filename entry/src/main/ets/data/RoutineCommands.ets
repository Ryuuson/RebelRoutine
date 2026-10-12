import { ActionRecord, HabitRecord, PinnedTask, RoutineSnapshot, TraitPoints } from './RoutineModel';
import { RoutineEngine } from './RoutineEngine';

/** No SDK/UI access: every command clones its input and returns the candidate snapshot. */
export class RoutineCommands {
  static validateDate(day: string, done: boolean, today: string): void {
    if (day && !RoutineEngine.validDay(day)) { throw new Error('请输入有效日期（YYYY-MM-DD）'); }
    if (done && (!day || day > today)) { throw new Error('实际行动日期需要今天或过去的有效日期'); }
  }
  static complete(state: RoutineSnapshot, id: number, day: string, keys: string[], amounts: TraitPoints[]): RoutineSnapshot {
    return RoutineEngine.complete(state, id, day, keys, amounts);
  }

  static edit(state: RoutineSnapshot, item: HabitRecord, today: string = RoutineEngine.localDay(new Date())): RoutineSnapshot {
    RoutineCommands.validateDate(item.done ? item.activityDay ?? item.day ?? '' : item.day ?? '', item.done, today);
    if (!item.title.trim()) { throw new Error('请输入事项标题'); }
    return RoutineEngine.edit(state, item);
  }

  static lifecycle(state: RoutineSnapshot, id: number, operation: string): RoutineSnapshot {
    return RoutineEngine.lifecycle(state, id, operation);
  }
  static nextId(state: RoutineSnapshot, now: number): number {
    return Math.max(now, ...state.habits.map((item: HabitRecord) => item.id + 1),
      ...state.pinnedTasks.map((item: PinnedTask) => item.id + 1));
  }

  static addTask(state: RoutineSnapshot, task: HabitRecord, day: string, done: boolean, keys: string[]): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    next.habits.push(task);
    return done ? RoutineEngine.complete(next, task.id, day, keys, task.assignedPoints ?? []) : next;
  }

  static reuseYesterday(state: RoutineSnapshot, today: string, yesterday: string, now: number): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    const seen: string[] = state.habits.filter((item: HabitRecord) => item.day === today && RoutineEngine.visible(item))
      .map((item: HabitRecord) => item.title.trim().toLowerCase());
    let added: number = 0;
    state.habits.filter((item: HabitRecord) => item.day === yesterday && RoutineEngine.visible(item)).forEach((item: HabitRecord) => {
      if (!seen.includes(item.title.trim().toLowerCase())) {
        next.habits.push({ id: RoutineCommands.nextId(state, now) + added, day: today, title: item.title,
          subtitle: item.subtitle, done: false, awardedTraits: [], assignedTraits: item.assignedTraits,
          assignedPoints: item.assignedPoints, createdAt: now, updatedAt: now });
        added++; seen.push(item.title.trim().toLowerCase());
      }
    });
    return next;
  }

  static togglePinned(state: RoutineSnapshot, task: PinnedTask): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    const exists: boolean = next.pinnedTasks.some((item: PinnedTask) => item.title === task.title && item.subtitle === task.subtitle);
    if (exists) { next.pinnedTasks = next.pinnedTasks.filter((item: PinnedTask) => item.title !== task.title || item.subtitle !== task.subtitle); }
    else { next.pinnedTasks.push(task); }
    return next;
  }

  static editPinned(state: RoutineSnapshot, task: PinnedTask): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    next.pinnedTasks = next.pinnedTasks.map((item: PinnedTask) => item.id === task.id ? task : item); return next;
  }

  static removePinned(state: RoutineSnapshot, id: number): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    next.pinnedTasks = next.pinnedTasks.filter((item: PinnedTask) => item.id !== id); return next;
  }

  static actionLifecycle(state: RoutineSnapshot, id: number, operation: string, now: number): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    const record: ActionRecord | undefined = next.actions.find((item: ActionRecord) => item.id === id);
    if (!record) { throw new Error('记录不存在'); }
    if (operation === 'delete' && record.deletedAt === undefined) {
      record.deletedPoints = RoutineEngine.removal(next, record.traits, []);
      RoutineEngine.award(next, record.traits, [], -1); record.deletedAt = now;
    } else if (operation === 'restore' && record.deletedAt !== undefined) {
      const receipt: TraitPoints[] = record.deletedPoints ?? record.traits.map((key: string): TraitPoints => ({ key, points: 1 }));
      RoutineEngine.award(next, receipt.map((point: TraitPoints) => point.key), receipt, 1);
      record.deletedAt = undefined; record.deletedPoints = undefined;
    }
    return next;
  }

  static purgeAction(state: RoutineSnapshot, id: number): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    next.actions = next.actions.filter((item: ActionRecord) => item.id !== id || item.deletedAt === undefined); return next;
  }
}
