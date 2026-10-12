import { RoutineSnapshot, HabitRecord } from './RoutineModel';
import { Commission } from './CommissionModel';

export class CommissionProgress {
  static week(day: string): string {
    const date: Date = new Date(`${day}T12:00:00`);
    date.setDate(date.getDate() - (date.getDay() + 6) % 7);
    return `${date.getFullYear()}-${(date.getMonth()+1).toString().padStart(2,'0')}-${date.getDate().toString().padStart(2,'0')}`;
  }
  static period(goal: Commission, day: string): string { return goal.weekly ? CommissionProgress.week(day) : 'all'; }
  static entries(state: RoutineSnapshot, goal: Commission, period: string): HabitRecord[] {
    return state.habits.filter((item: HabitRecord) => item.commissionId === goal.id && item.done && item.deletedAt === undefined &&
      CommissionProgress.period(goal, item.activityDay ?? '') === period);
  }
  static value(state: RoutineSnapshot, goal: Commission, period: string): number {
    const children: Commission[] = state.m2?.goals.filter((item: Commission) => item.parentId === goal.id) ?? [];
    if (children.length) {
      return children.reduce((sum: number, item: Commission) => sum + CommissionProgress.ratio(state,item,'all'),0) / children.length * 100;
    }
    return Number(CommissionProgress.entries(state,goal,period).reduce((sum: number, item: HabitRecord) =>
      sum + (item.progressValue ?? 1),0).toPrecision(12));
  }
  static ratio(state: RoutineSnapshot, goal: Commission, period: string): number {
    return Math.min(1, CommissionProgress.value(state,goal,period) / goal.target);
  }
  static periods(state: RoutineSnapshot, goal: Commission): string[] {
    return goal.weekly ? Array.from(new Set([...state.habits.filter((item: HabitRecord) => item.commissionId === goal.id && item.activityDay)
      .map((item: HabitRecord) => CommissionProgress.period(goal,item.activityDay!)),
      ...(state.m2?.awards.filter((award) => award.goalId === goal.id).map((award) => award.period) ?? [])])) : ['all'];
  }
}
