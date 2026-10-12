import { RoutineSnapshot, TraitPoints } from './RoutineModel';
import { Commission, CommissionData, RepeatPlan, LedgerEntry, CommissionAward, CommissionStage } from './CommissionModel';
import { CommissionLedger } from './CommissionLedger';

export class CommissionValidation {
  static day(value: string): boolean {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) { return false; }
    const date: Date = new Date(`${value}T12:00:00`);
    return Number.isFinite(date.getTime()) && date.getFullYear() >= 1970 &&
      `${date.getFullYear()}-${(date.getMonth()+1).toString().padStart(2,'0')}-${date.getDate().toString().padStart(2,'0')}` === value;
  }
  static amount(value: number): boolean { return Number.isFinite(value) && value > 0 && value <= 1000000000; }
  static id(value: number): boolean { return Number.isSafeInteger(value) && value >= 0; }
  static points(points: TraitPoints[], signed: boolean = false): void {
    if (!Array.isArray(points) || new Set(points.map((item: TraitPoints) => item.key)).size !== points.length ||
      points.some((item: TraitPoints) => !item || typeof item.key !== 'string' || !Number.isSafeInteger(item.points) ||
        (!signed && item.points <= 0))) { throw new Error('成长账目无效'); }
  }
  static reward(keys: string[], points: TraitPoints[]): void {
    CommissionValidation.points(points);
    if (!Array.isArray(keys) || new Set(keys).size !== keys.length || keys.some((key: string) =>
      !['knowledge','proficiency','charm','kindness','health'].includes(key)) || points.length !== keys.length ||
      points.some((item: TraitPoints) => !keys.includes(item.key))) { throw new Error('委托成长设置无效'); }
  }
  static goal(goal: Commission, data: CommissionData): void {
    if (!goal || !CommissionValidation.id(goal.id) || typeof goal.title !== 'string' || !goal.title.trim() ||
      typeof goal.unit !== 'string' || !goal.unit.trim() || !CommissionValidation.amount(goal.target) ||
      !['once','count','quantity','project'].includes(goal.mode) || !['target','entry'].includes(goal.rewardMode) ||
      typeof goal.weekly !== 'boolean' ||
      !CommissionValidation.id(goal.createdAt) || !CommissionValidation.id(goal.updatedAt) ||
      (goal.deadline !== undefined && !CommissionValidation.day(goal.deadline)) ||
      (goal.mode === 'once' && goal.target !== 1) || (goal.mode === 'count' && !Number.isSafeInteger(goal.target)) ||
      (goal.mode === 'project' && (goal.target !== 100 || goal.weekly))) { throw new Error('委托配置无效'); }
    if (goal.parentId !== undefined) {
      const parent: Commission | undefined = data.goals.find((item: Commission) => item.id === goal.parentId);
      if (!parent || parent.id === goal.id || parent.parentId !== undefined || parent.mode !== 'project' || goal.weekly ||
        goal.mode === 'project') { throw new Error('子任务只支持一层，周期目标请独立建立'); }
    }
    CommissionValidation.reward(goal.keys,goal.points);
    if (!Array.isArray(goal.stages) || new Set(goal.stages.map((stage: CommissionStage) => stage.id)).size !== goal.stages.length) {
      throw new Error('阶段配置无效');
    }
    goal.stages.forEach((stage: CommissionStage) => {
      if (!stage || !CommissionValidation.id(stage.id) || stage.id === 0 || typeof stage.title !== 'string' ||
        !stage.title.trim() || !Number.isFinite(stage.percent) || stage.percent <= 0 || stage.percent > 100) { throw new Error('阶段节点无效'); }
      CommissionValidation.reward(stage.keys,stage.points);
    });
  }
  static validate(state: RoutineSnapshot): void {
    const data: CommissionData | undefined = state.m2;
    if (!data) { return; }
    if (data.schema !== 1 || !Array.isArray(data.goals) || !Array.isArray(data.awards) ||
      !Array.isArray(data.ledger) || !Array.isArray(data.repeats)) { throw new Error('委托数据格式不支持'); }
    if (new Set(data.goals.map((goal: Commission) => goal.id)).size !== data.goals.length) { throw new Error('委托编号重复'); }
    data.goals.forEach((goal: Commission) => CommissionValidation.goal(goal,data));
    state.habits.forEach((item) => {
      if ((item.commissionId !== undefined && (!data.goals.some((goal: Commission) => goal.id === item.commissionId) ||
        !CommissionValidation.amount(item.progressValue ?? 1))) ||
        (item.progressEntry !== undefined && typeof item.progressEntry !== 'boolean') ||
        (item.repeatId !== undefined && (!data.repeats.some((plan: RepeatPlan) => plan.id === item.repeatId) ||
        !CommissionValidation.day(item.repeatDay ?? '')))) { throw new Error('事项进度来源无效'); }
      const goal: Commission | undefined = data.goals.find((goal: Commission) => goal.id === item.commissionId);
      if (goal?.mode === 'count' && !Number.isSafeInteger(item.progressValue ?? 1)) { throw new Error('次数需为正整数'); }
      if (goal?.mode === 'once' && (item.progressValue ?? 1) !== 1) { throw new Error('一次完成每条记录计入一次'); }
      if (goal?.mode === 'project') { throw new Error('总委托通过子任务汇总，不能直接登记数量'); }
      [item.commissionPoints,item.commissionParentPoints].forEach((points: TraitPoints[] | undefined) => {
        if (points !== undefined) { CommissionValidation.points(points); }
      });
      [item.commissionStages,item.commissionParentStages].forEach((stages: CommissionStage[] | undefined) => {
        if (stages !== undefined) {
          if (!Array.isArray(stages)) { throw new Error('阶段来源快照无效'); }
          stages.forEach((stage: CommissionStage) => CommissionValidation.reward(stage.keys,stage.points));
        }
      });
    });
    if (new Set(data.ledger.map((entry: LedgerEntry) => entry.id)).size !== data.ledger.length) { throw new Error('账目编号重复'); }
    data.ledger.forEach((entry: LedgerEntry) => {
      if (!entry || !CommissionValidation.id(entry.id) || !CommissionValidation.id(entry.createdAt) ||
        !CommissionValidation.day(entry.day) || !['opening','record','commission'].includes(entry.kind) ||
        !Array.isArray(entry.refs) || entry.refs.some((ref) => !CommissionValidation.id(ref.id) || typeof ref.action !== 'boolean')) {
        throw new Error('成长账目来源无效');
      }
      CommissionValidation.points(entry.points,true);
    });
    if (new Set(data.awards.map((award: CommissionAward) => award.key)).size !== data.awards.length) { throw new Error('达成来源重复'); }
    data.awards.forEach((award: CommissionAward) => {
      if (!award || !data.goals.some((goal: Commission) => goal.id === award.goalId) || !CommissionValidation.id(award.stageId) ||
        !CommissionValidation.day(award.day) || typeof award.active !== 'boolean' || typeof award.title !== 'string' ||
        !Number.isFinite(award.threshold) || award.threshold <= 0 || award.threshold > 1 ||
        (award.period !== 'all' && !CommissionValidation.day(award.period)) ||
        award.key !== `${award.goalId}:${award.stageId}:${award.period}`) { throw new Error('达成来源无效'); }
      CommissionValidation.points(award.points);
      const entries: LedgerEntry[] = data.ledger.filter((entry: LedgerEntry) => entry.awardKey === award.key);
      const keys: string[] = Array.from(new Set([...award.points,...entries.flatMap((entry: LedgerEntry) => entry.points)]
        .map((point: TraitPoints) => point.key)));
      if (keys.some((key: string) => entries.reduce((sum: number, entry: LedgerEntry) =>
        sum+(entry.points.find((point: TraitPoints) => point.key === key)?.points ?? 0),0) !==
        (award.active ? award.points.find((point: TraitPoints) => point.key === key)?.points ?? 0 : 0))) {
        throw new Error('达成来源与成长账目不一致');
      }
    });
    if (data.ledger.some((entry: LedgerEntry) => entry.kind === 'commission' ?
      !data.awards.some((award: CommissionAward) => award.key === entry.awardKey) : entry.awardKey !== undefined)) {
      throw new Error('成长账目缺少达成来源');
    }
    if (new Set(data.repeats.map((plan: RepeatPlan) => plan.id)).size !== data.repeats.length) { throw new Error('重复计划编号重复'); }
    data.repeats.forEach((plan: RepeatPlan) => CommissionValidation.repeat(plan,data));
    const balances: TraitPoints[] = CommissionLedger.balances(data);
    if (balances.some((point: TraitPoints) => !Number.isSafeInteger(point.points)) || state.traitTotals.some((total) =>
      total.score !== Math.max(0,balances.find((point: TraitPoints) => point.key === total.key)?.points ?? 0)) ||
      balances.some((point: TraitPoints) => !state.traitTotals.some((total) => total.key === point.key))) { throw new Error('成长账目与累计值不一致'); }
  }
  static repeat(plan: RepeatPlan, data: CommissionData): void {
    if (!plan || !CommissionValidation.id(plan.id) || typeof plan.title !== 'string' || !plan.title.trim() ||
      typeof plan.subtitle !== 'string' || !['daily','weekly'].includes(plan.rule) || !CommissionValidation.day(plan.startDay) ||
      !CommissionValidation.day(plan.through) || typeof plan.paused !== 'boolean' || !CommissionValidation.amount(plan.value) ||
      !Array.isArray(plan.usedDays) || new Set(plan.usedDays).size !== plan.usedDays.length ||
      plan.usedDays.some((day: string) => !CommissionValidation.day(day)) || !Array.isArray(plan.weekdays) ||
      !plan.weekdays.length || new Set(plan.weekdays).size !== plan.weekdays.length ||
      plan.weekdays.some((day: number) => !Number.isInteger(day) || day < 0 || day > 6) ||
      (plan.traits !== undefined && (!Array.isArray(plan.traits) || plan.traits.some((key: string) =>
        !['knowledge','proficiency','charm','kindness','health'].includes(key)))) ||
      (plan.goalId !== undefined && !data.goals.some((goal: Commission) => goal.id === plan.goalId && goal.mode !== 'project'))) {
      throw new Error('重复计划无效');
    }
    CommissionValidation.points(plan.points);
    if (plan.traits !== undefined) { CommissionValidation.reward(plan.traits,plan.points); }
    else if (plan.points.length) { throw new Error('自动判断的重复计划不能预设成长幅度'); }
    const goal: Commission | undefined = data.goals.find((goal: Commission) => goal.id === plan.goalId);
    if ((goal?.mode === 'count' && !Number.isSafeInteger(plan.value)) || (goal?.mode === 'once' && plan.value !== 1)) {
      throw new Error('重复计划的次数进度无效');
    }
  }
}
