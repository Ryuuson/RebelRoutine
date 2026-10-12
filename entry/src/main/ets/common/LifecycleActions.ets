import { HabitRecord, TraitPoints, RoutineSnapshot } from '../data/RoutineStore';
import { TRAIT_DEFINITIONS, TraitDefinition, TraitHit } from '../data/TraitAnalyzer';
import { RoutineEngine } from '../data/RoutineEngine';
import { MorganaEvent } from '../data/MorganaFeedback';
import { dayKey } from './DayUtil';
import { RoutineHost } from './RoutineHost';
import { RoutineCommands } from '../data/RoutineCommands';
import { RoutineBatch } from '../data/RoutineBatch';

import { PageActions } from './PageActions';

export class LifecycleActions {
  private readonly host: RoutineHost;
  private readonly ui: PageActions;
  constructor(host: RoutineHost, ui: PageActions) { this.host = host; this.ui = ui; }
  async toggleHabit(id: number): Promise<boolean> {
    const target: HabitRecord | undefined = this.host.state.habits.find((item: HabitRecord) => item.id === id);
    if (!target || this.host.state.editingHabitId === id || !RoutineEngine.visible(target)) { return false; }
    let keys: string[] = []; let amounts: TraitPoints[] = [];
    const sign: number = target.done ? -1 : 1;
    const previousRanks: number[] = TRAIT_DEFINITIONS.map((trait: TraitDefinition) => this.ui.queries.traitRank(trait.key));
    const saved: boolean = await this.host.mutate(async (): Promise<RoutineSnapshot> => {
      keys = target.done ? target.awardedTraits ?? [] : target.assignedTraits === undefined ?
        (await this.ui.analyzer.analyze(`${target.title} ${target.subtitle}`)).hits.map((hit: TraitHit) => hit.key) :
          this.ui.queries.validTraitKeys(target.assignedTraits);
      amounts = target.done ? target.awardedPoints ?? [] : target.assignedPoints ?? [];
      return RoutineCommands.complete(this.host.snapshot(), id, dayKey(), keys, amounts);
    });
    if (saved) {
      const raised: boolean = sign > 0 && TRAIT_DEFINITIONS.some((trait: TraitDefinition, index: number) => this.ui.queries.traitRank(trait.key)
        > previousRanks[index]);
      const left: number = this.ui.queries.todayHabits().filter((item: HabitRecord) => !item.done).length;
      this.ui.dialogue.queueFeedback(sign < 0 ? MorganaEvent.Undo : raised ? MorganaEvent.RankUp :
        left === 0 ? MorganaEvent.Clear : MorganaEvent.Complete, keys, sign, amounts);
    }
    return saved;
  }



  startEditing(habit: HabitRecord): void {
    this.host.state.notice = '';
    this.host.state.actionMenuId = -1;
    this.host.state.editingHabitId = habit.id;
    this.host.state.editDay = habit.day ?? '';
    this.host.state.editActivityDay = habit.activityDay ?? habit.day ?? dayKey();
    this.host.state.editTitle = habit.title;
    this.host.state.editSubtitle = habit.subtitle;
    this.host.state.editCommissionId = habit.commissionId ?? -1; this.host.state.editProgressValue = `${habit.progressValue ?? 1}`;
    this.host.state.editTraits = habit.done ? [...habit.awardedTraits ?? []] : habit.assignedTraits === undefined ? ['auto'] : [...habit.assignedTraits];
    this.host.state.editPoints = [...(habit.done ? habit.awardedPoints : habit.assignedPoints) ?? []];
  }

  async saveEditing(): Promise<void> {
    const saved: boolean = await this.host.mutate(async (): Promise<RoutineSnapshot> => {
      const target: HabitRecord | undefined = this.host.state.habits.find((item: HabitRecord) => item.id === this.host.state.editingHabitId);
      if (!target || !this.host.state.editTitle.trim()) { throw new Error('请输入事项标题'); }
      RoutineCommands.validateDate(target.done ? this.host.state.editActivityDay : this.host.state.editDay, target.done, dayKey());
      const next: HabitRecord = JSON.parse(JSON.stringify(target)) as HabitRecord;
      next.title = this.host.state.editTitle.trim(); next.subtitle = this.host.state.editSubtitle.trim();
      next.commissionId = this.host.state.editCommissionId < 0 ? undefined : this.host.state.editCommissionId;
      next.progressValue = next.commissionId === undefined ? undefined : Number(this.host.state.editProgressValue);
      next.updatedAt = Date.now();
      const selected: string[] | undefined = this.ui.queries.assignedSelection(this.host.state.editTraits);
      const points: TraitPoints[] = this.ui.queries.normalizedPoints(selected ?? [], this.host.state.editPoints);
      if (!next.done) {
        next.day = this.host.state.editDay || undefined; next.assignedTraits = selected; next.assignedPoints = points;
      }
      if (next.done) {
        next.activityDay = this.host.state.editActivityDay;
        if (this.host.state.editActivityDay !== target.activityDay) { next.inferredDay = false; }
        const changed: boolean = JSON.stringify(target.awardedTraits ?? []) !== JSON.stringify(this.host.state.editTraits) ||
          JSON.stringify(this.ui.queries.normalizedPoints(target.awardedTraits ?? [], target.awardedPoints ?? [])) !==
            JSON.stringify(this.ui.queries.normalizedPoints(this.host.state.editTraits, this.host.state.editPoints));
        if (changed) {
          next.assignedTraits = selected; next.assignedPoints = points;
          next.awardedTraits = selected === undefined ?
            (await this.ui.analyzer.analyze(`${next.title} ${next.subtitle}`)).hits.map((hit: TraitHit) => hit.key) : selected;
          next.awardedPoints = this.ui.queries.normalizedPoints(next.awardedTraits, points);
        }
      }
      return RoutineCommands.edit(this.host.snapshot(), next, dayKey());
    });
    if (saved) { this.host.state.editingHabitId = -1; this.host.state.actionMenuId = -1; }
  }

  async lifecycle(id: number, operation: string): Promise<void> {
    if (!['delete', 'restore', 'purge', 'reopen'].includes(operation)) { return; }
    await this.ui.batch.request(operation, [{ id, action: false }]);
  }



  async actionLifecycle(id: number, operation: string): Promise<void> {
    await this.ui.batch.request(operation, [{ id, action: true }]);
  }

  async reschedule(id: number, day: string): Promise<void> {
    await this.host.mutate(async (): Promise<RoutineSnapshot> =>
      RoutineBatch.apply(this.host.snapshot(), { refs: [{ id, action: false }], operation: 'date', day }, dayKey()));
  }

  async sheetOperation(operation: string): Promise<void> {
    const id: number = this.host.state.actionMenuId;
    if (this.host.state.actionMenuLegacy) {
      if (['delete', 'restore', 'purge'].includes(operation)) { await this.actionLifecycle(id, operation); if (!this.host.state.notice) {
        this.host.state.actionMenuId = -1; } }
      return;
    }
    const item: HabitRecord | undefined = this.ui.queries.selectedHabit();
    if (!item || !this.ui.queries.canOperate(item, operation)) { return; }
    if (operation === 'edit') {
      this.startEditing(item); this.host.state.actionMenuId = id; this.host.state.sheetMode = operation; return;
    }
    if (operation === 'complete' || operation === 'undo') { if (await this.toggleHabit(id)) { this.host.state.actionMenuId = -1; } }
    else if (operation === 'focus') { this.host.state.actionMenuId = -1; this.host.openWorkspace('focus'); if (!this.host.state.isFocusing) {
      this.ui.focus.toggleFocus(); } }
    else { await this.lifecycle(id, operation); }
  }

  async rescheduleToday(id: number): Promise<void> { await this.reschedule(id, dayKey()); }
}
