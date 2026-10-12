import { RoutineSnapshot, TraitPoints, HabitRecord } from './RoutineModel';
import { Commission, CommissionAward, CommissionStage } from './CommissionModel';
import { RoutineEngine } from './RoutineEngine';
import { CommissionLedger } from './CommissionLedger';
import { CommissionProgress } from './CommissionProgress';

export class CommissionEngine {
  static bootstrap(state: RoutineSnapshot): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    if (!next.m2) { next.m2 = CommissionLedger.initialize(next); }
    return next;
  }
  static reconcile(before: RoutineSnapshot, candidate: RoutineSnapshot, today: string): RoutineSnapshot {
    const next: RoutineSnapshot = CommissionEngine.bootstrap(candidate);
    if (!before.m2) { next.m2!.ledger = CommissionLedger.initialize(before).ledger; }
    next.habits.filter((item: HabitRecord) => item.done && item.commissionId !== undefined).forEach((item: HabitRecord) => {
      const old: HabitRecord | undefined = before.habits.find((record: HabitRecord) => record.id === item.id);
      if (old?.commissionId === item.commissionId && item.commissionPoints !== undefined) { return; }
      const goal: Commission | undefined = next.m2!.goals.find((goal: Commission) => goal.id === item.commissionId);
      if (!goal) { throw new Error('关联委托已不存在，请重新选择'); }
      item.commissionPoints = JSON.parse(JSON.stringify(goal.points)) as TraitPoints[];
      item.commissionStages = JSON.parse(JSON.stringify(goal.stages)) as CommissionStage[];
      const parent: Commission | undefined = next.m2!.goals.find((parent: Commission) => parent.id === goal.parentId);
      item.commissionParentPoints = JSON.parse(JSON.stringify(parent?.points ?? [])) as TraitPoints[];
      item.commissionParentStages = JSON.parse(JSON.stringify(parent?.stages ?? [])) as CommissionStage[];
    });
    CommissionLedger.recordChanges(before,next,today);
    // Children settle before their parent; parent progress is a mean of bounded ratios, never mixed units.
    const goals: Commission[] = [...next.m2!.goals].sort((a: Commission,b: Commission) => Number(!!b.parentId)-Number(!!a.parentId));
    goals.forEach((goal: Commission) => CommissionProgress.periods(next,goal).forEach((period: string) => {
      const ratio: number = CommissionProgress.ratio(next,goal,period);
      if (goal.rewardMode === 'target') { CommissionEngine.setAward(next,goal,0,1,period,ratio,goal.points,today); }
      goal.stages.forEach((stage: CommissionStage) => CommissionEngine.setAward(next,goal,stage.id,stage.percent/100,
        period,ratio,stage.points,today,stage.title));
      next.m2!.awards.filter((award: CommissionAward) => award.goalId === goal.id && award.period === period)
        .forEach((award: CommissionAward) => CommissionEngine.setAward(next,goal,award.stageId,award.threshold,
          period,ratio,award.points,today));
    }));
    CommissionLedger.applyTotals(next);
    return next;
  }
  private static setAward(state: RoutineSnapshot, goal: Commission, stageId: number, threshold: number, period: string,
    ratio: number, points: TraitPoints[], today: string, stageTitle: string = '达成'): void {
    const key: string = `${goal.id}:${stageId}:${period}`;
    let award: CommissionAward | undefined = state.m2!.awards.find((item: CommissionAward) => item.key === key);
    const achieved: boolean = ratio >= (award?.threshold ?? threshold);
    if (!award && achieved) {
      const children: number[] = state.m2!.goals.filter((child: Commission) => child.parentId === goal.id).map((child: Commission) => child.id);
      const entries: HabitRecord[] = goal.mode === 'project' ? state.habits.filter((item: HabitRecord) =>
        item.done && item.deletedAt === undefined && children.includes(item.commissionId ?? -1)) :
        CommissionProgress.entries(state,goal,period);
      const day: string = entries.map((item) => item.activityDay!).sort().pop() ?? today;
      const witness: HabitRecord | undefined = [...entries].sort((a: HabitRecord,b: HabitRecord) =>
        (b.createdAt ?? b.id)-(a.createdAt ?? a.id) || b.id-a.id)[0];
      const stages: CommissionStage[] | undefined = goal.mode === 'project' ?
        witness?.commissionParentStages : witness?.commissionStages;
      // A newly added stage does not grant rewards against sources recorded before that stage existed.
      if (stageId !== 0 && stages !== undefined && !stages.some((stage: CommissionStage) => stage.id === stageId)) { return; }
      const frozen: TraitPoints[] | undefined = stageId === 0 ? (goal.mode === 'project' ?
        witness?.commissionParentPoints : witness?.commissionPoints) : stages?.find((stage: CommissionStage) => stage.id === stageId)?.points;
      award = { key, goalId: goal.id, stageId, period, day, title: `${goal.title} · ${stageTitle}`, active: false,
        threshold, points: JSON.parse(JSON.stringify(frozen ?? points)) as TraitPoints[] };
      state.m2!.awards.push(award);
    }
    if (award && achieved !== award.active) {
      CommissionLedger.append(state,'commission',award.day,award.points.map((point: TraitPoints): TraitPoints =>
        ({ key: point.key, points: point.points*(achieved ? 1 : -1) })),[],key);
      award.active = achieved;
    }
  }
}
