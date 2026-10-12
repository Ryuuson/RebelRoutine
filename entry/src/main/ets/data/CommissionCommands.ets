import { RoutineSnapshot, HabitRecord, TraitPoints } from './RoutineModel';
import { Commission } from './CommissionModel';
import { CommissionEngine } from './CommissionEngine';
import { CommissionValidation } from './CommissionValidation';
import { RoutineCommands } from './RoutineCommands';

export class CommissionCommands {
  static save(state: RoutineSnapshot, goal: Commission): RoutineSnapshot {
    const next: RoutineSnapshot = CommissionEngine.bootstrap(state);
    const index: number = next.m2!.goals.findIndex((item: Commission) => item.id === goal.id);
    const before: Commission | undefined = next.m2!.goals[index];
    if (before && next.habits.some((item: HabitRecord) => item.commissionId === goal.id) &&
      (before.mode !== goal.mode || before.weekly !== goal.weekly || before.unit !== goal.unit || before.parentId !== goal.parentId ||
        before.rewardMode !== goal.rewardMode)) {
      throw new Error('已有行动时请保留进度类型、周期、单位、父级和成长方式；新规则请建立新委托');
    }
    if (index < 0) { next.m2!.goals.push(goal); } else { next.m2!.goals[index] = goal; }
    next.m2!.goals.forEach((item: Commission) => CommissionValidation.goal(item,next.m2!));
    return next;
  }
  static record(state: RoutineSnapshot, goalId: number, value: number, day: string, note: string, today: string): RoutineSnapshot {
    const next: RoutineSnapshot = CommissionEngine.bootstrap(state);
    const goal: Commission | undefined = next.m2!.goals.find((item: Commission) => item.id === goalId);
    if (!goal || goal.mode === 'project') { throw new Error('请选择可登记进度的子任务或独立目标'); }
    RoutineCommands.validateDate(day,true,today);
    if (!CommissionValidation.amount(value) || (goal.mode === 'count' && !Number.isSafeInteger(value))) { throw new Error('请输入有效进度'); }
    const keys: string[] = goal.rewardMode === 'entry' ? [...goal.keys] : [];
    const points: TraitPoints[] = goal.rewardMode === 'entry' ? [...goal.points] : [];
    const id: number = RoutineCommands.nextId(next,Date.now());
    const item: HabitRecord = { id, title: goal.title, subtitle: note.trim(), done: false, awardedTraits: [],
      assignedTraits: keys, assignedPoints: points, commissionId: goalId, progressValue: goal.mode === 'once' ? 1 : value,
      progressEntry: true, createdAt: Date.now(), updatedAt: Date.now() };
    return RoutineCommands.addTask(next,item,day,true,keys);
  }
}
