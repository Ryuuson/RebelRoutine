import { RoutineHost } from './RoutineHost';
import { PageActions } from './PageActions';
import { RoutineSnapshot } from '../data/RoutineModel';
import { Commission, RepeatPlan, CommissionStage } from '../data/CommissionModel';
import { CommissionCommands } from '../data/CommissionCommands';
import { CommissionRepeats } from '../data/CommissionRepeats';
import { dayKey, offsetDay } from './DayUtil';

export class CommissionActions {
  private readonly host: RoutineHost;
  private readonly ui: PageActions;
  constructor(host: RoutineHost, ui: PageActions) { this.host = host; this.ui = ui; }
  open(id: number): void {
    if (this.host.state.mutationBusy) { return; }
    if (this.host.state.workspace === 'commission') { this.host.state.commissionTrail.push(this.host.state.commissionId); }
    else { this.host.state.commissionTrail = []; this.host.openWorkspace('commission'); }
    this.host.state.commissionId = id;
  }
  edit(goal?: Commission, parentId: number = -1): void {
    const s = this.host.state;
    s.goalEditId = goal?.id ?? -1; s.goalParentId = goal?.parentId ?? parentId; s.goalTitle = goal?.title ?? '';
    s.goalMode = goal?.mode ?? (parentId >= 0 ? 'once' : 'quantity');
    s.goalTarget = `${goal?.target ?? (parentId >= 0 ? 1 : 120)}`; s.goalUnit = goal?.unit ?? (parentId >= 0 ? '次' : '分钟');
    s.goalDeadline = goal?.deadline ?? ''; s.goalWeekly = goal?.weekly ?? false; s.goalRewardMode = goal?.rewardMode ?? 'target';
    s.goalTraits = [...goal?.keys ?? []]; s.goalPoints = [...goal?.points ?? []];
    s.goalStages = JSON.parse(JSON.stringify(goal?.stages ?? [])) as CommissionStage[]; s.notice = ''; s.goalEditing = true;
  }
  async save(): Promise<void> {
    const s = this.host.state;
    const old: Commission | undefined = s.m2?.goals.find((item: Commission) => item.id === s.goalEditId);
    const keys: string[] = this.ui.queries.validTraitKeys(s.goalTraits);
    const id: number = old?.id ?? (s.m2?.goals ?? []).reduce((value: number, item: Commission) => Math.max(value,item.id+1),Date.now());
    const goal: Commission = { id, parentId: s.goalParentId < 0 ? undefined : s.goalParentId,
      title: s.goalTitle.trim(), mode: s.goalMode, target: s.goalMode === 'once' ? 1 : s.goalMode === 'project' ? 100 : Number(s.goalTarget),
      unit: s.goalMode === 'project' ? '%' : s.goalMode === 'once' || s.goalMode === 'count' ? '次' : s.goalUnit.trim(),
      weekly: s.goalWeekly, deadline: s.goalDeadline.trim() || undefined, rewardMode: s.goalRewardMode,
      keys, points: this.ui.queries.normalizedPoints(keys,s.goalPoints), stages: s.goalStages,
      createdAt: old?.createdAt ?? Date.now(), updatedAt: Date.now() };
    if (await this.host.mutate(async (): Promise<RoutineSnapshot> => CommissionCommands.save(this.host.snapshot(),goal))) {
      s.goalEditing = false; if (s.workspace !== 'commission') { this.open(goal.id); }
    }
  }
  startProgress(goal: Commission): void {
    this.host.state.commissionId = goal.id; this.host.state.progressValue = goal.mode === 'once' ? '1' : '';
    this.host.state.progressDay = dayKey(); this.host.state.progressNote = ''; this.host.state.notice = ''; this.host.state.progressOpen = true;
  }
  async saveProgress(): Promise<void> {
    const s = this.host.state;
    if (await this.host.mutate(async (): Promise<RoutineSnapshot> => CommissionCommands.record(this.host.snapshot(),s.commissionId,
      Number(s.progressValue),s.progressDay.trim(),s.progressNote,dayKey()))) { s.progressOpen = false; this.ui.feedback.toast('进度已记录'); }
  }
  back(): void {
    if (this.host.state.commissionTrail.length) { this.host.state.commissionId = this.host.state.commissionTrail.pop()!; }
    else { this.host.closeWorkspace(); }
  }
  records(goalId: number): void {
    this.host.state.workspace = ''; this.host.state.workspaceStack = []; this.host.state.commissionTrail = [];
    this.host.switchPage('记录'); this.host.state.recordTargetCommission = goalId;
  }
  editRepeat(plan?: RepeatPlan): void {
    const s = this.host.state;
    s.repeatEditId = plan?.id ?? -1; s.repeatTitle = plan?.title ?? ''; s.repeatSubtitle = plan?.subtitle ?? '';
    s.repeatRule = plan?.rule ?? 'daily'; s.repeatDays = [...plan?.weekdays ?? [1,2,3,4,5]];
    s.repeatStart = plan?.startDay ?? dayKey(); s.repeatGoalId = plan?.goalId ?? -1; s.repeatValue = `${plan?.value ?? 1}`;
    s.repeatTraits = plan?.traits === undefined ? ['auto'] : [...plan.traits]; s.repeatPoints = [...plan?.points ?? []];
    s.notice = ''; s.repeatEditing = true;
  }
  async saveRepeat(): Promise<void> {
    const s = this.host.state;
    const old: RepeatPlan | undefined = s.m2?.repeats.find((item: RepeatPlan) => item.id === s.repeatEditId);
    const keys: string[] | undefined = this.ui.queries.assignedSelection(s.repeatTraits);
    const id: number = old?.id ?? (s.m2?.repeats ?? []).reduce((value: number, item: RepeatPlan) => Math.max(value,item.id+1),Date.now());
    const plan: RepeatPlan = { id, title: s.repeatTitle.trim(), subtitle: s.repeatSubtitle.trim(),
      rule: s.repeatRule, weekdays: s.repeatDays, startDay: s.repeatStart.trim(), through: offsetDay(dayKey(),-1),
      paused: old?.paused ?? false, usedDays: [...old?.usedDays ?? []], goalId: s.repeatGoalId < 0 ? undefined : s.repeatGoalId,
      value: Number(s.repeatValue), traits: keys, points: this.ui.queries.normalizedPoints(keys ?? [],s.repeatPoints) };
    if (await this.host.mutate(async (): Promise<RoutineSnapshot> => CommissionRepeats.save(this.host.snapshot(),plan,dayKey()))) {
      s.repeatEditing = false;
    }
  }
  async toggleRepeat(id: number): Promise<void> {
    await this.host.mutate(async (): Promise<RoutineSnapshot> => CommissionRepeats.toggle(this.host.snapshot(),id,dayKey()));
  }
  async refreshRepeats(): Promise<void> {
    const s = this.host.state;
    if (!s.m2 || !s.dataReady || s.mutationBusy || !s.m2.repeats.some((plan: RepeatPlan) => plan.through < dayKey())) { return; }
    await this.host.mutate(async (): Promise<RoutineSnapshot> => CommissionRepeats.generate(this.host.snapshot(),dayKey()));
  }
}
