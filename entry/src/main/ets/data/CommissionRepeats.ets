import { RoutineSnapshot, HabitRecord } from './RoutineModel';
import { RepeatPlan } from './CommissionModel';
import { CommissionEngine } from './CommissionEngine';
import { CommissionValidation } from './CommissionValidation';
import { RoutineCommands } from './RoutineCommands';

export class CommissionRepeats {
  static offset(day: string, amount: number): string {
    const date: Date = new Date(`${day}T12:00:00`); date.setDate(date.getDate()+amount);
    return `${date.getFullYear()}-${(date.getMonth()+1).toString().padStart(2,'0')}-${date.getDate().toString().padStart(2,'0')}`;
  }
  static save(state: RoutineSnapshot, plan: RepeatPlan, today: string): RoutineSnapshot {
    const next: RoutineSnapshot = CommissionEngine.bootstrap(state);
    CommissionValidation.repeat(plan,next.m2!);
    if (plan.startDay < today && !next.m2!.repeats.some((item: RepeatPlan) => item.id === plan.id)) {
      throw new Error('新重复计划从今天或未来开始');
    }
    const index: number = next.m2!.repeats.findIndex((item: RepeatPlan) => item.id === plan.id);
    if (index < 0) { next.m2!.repeats.push(plan); } else { next.m2!.repeats[index] = plan; }
    return CommissionRepeats.generate(next,today);
  }
  static toggle(state: RoutineSnapshot, id: number, today: string): RoutineSnapshot {
    const next: RoutineSnapshot = CommissionEngine.bootstrap(state);
    const plan: RepeatPlan | undefined = next.m2!.repeats.find((item: RepeatPlan) => item.id === id);
    if (!plan) { throw new Error('重复计划不存在'); }
    plan.paused = !plan.paused; plan.through = CommissionRepeats.offset(today,plan.paused ? 0 : -1);
    return CommissionRepeats.generate(next,today);
  }
  static generate(state: RoutineSnapshot, today: string): RoutineSnapshot {
    const next: RoutineSnapshot = CommissionEngine.bootstrap(state);
    next.m2!.repeats.forEach((plan: RepeatPlan) => {
      if (plan.through >= today) { return; }
      if (plan.paused) { plan.through = today; return; }
      let day: string = plan.through < plan.startDay ? plan.startDay : CommissionRepeats.offset(plan.through,1);
      let id: number = RoutineCommands.nextId(next,Date.now());
      while (day <= today) {
        const weekday: number = new Date(`${day}T12:00:00`).getDay();
        if ((plan.rule === 'daily' || plan.weekdays.includes(weekday)) && !plan.usedDays.includes(day)) {
          const item: HabitRecord = { id: id++, title: plan.title, subtitle: plan.subtitle, day, done: false, awardedTraits: [],
            assignedTraits: plan.traits, assignedPoints: [...plan.points], createdAt: Date.now(), updatedAt: Date.now(),
            repeatId: plan.id, repeatDay: day, commissionId: plan.goalId, progressValue: plan.goalId === undefined ? undefined : plan.value };
          next.habits.push(item); plan.usedDays.push(day);
        }
        day = CommissionRepeats.offset(day,1);
      }
      plan.through = today;
    });
    return next;
  }
}
