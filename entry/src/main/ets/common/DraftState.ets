import { HabitRecord, PinnedTask, TraitPoints, RoutineSnapshot } from '../data/RoutineStore';
import { TraitHit } from '../data/TraitAnalyzer';
import { RoutineEngine } from '../data/RoutineEngine';
import { dayKey, yesterdayKey, shiftDay } from './DayUtil';
import { makeHabitRecord } from './RecordUtil';
import { RoutineHost } from './RoutineHost';
import { RoutineCommands } from '../data/RoutineCommands';

import { PageActions } from './PageActions';

export class DraftState {
  private readonly host: RoutineHost;
  private readonly ui: PageActions;
  constructor(host: RoutineHost, ui: PageActions) { this.host = host; this.ui = ui; }
  openComposer(done: boolean): void {
    this.host.state.composerOpen = true;
    if (!this.host.state.newTaskDraft) {
      this.host.state.draftDone = done; this.host.state.draftDay = done || this.host.state.mainPage === '今日' ? '' : '-';
      this.host.state.draftError = ''; this.host.state.draftDateOpen = false;
    }
  }

  collapseComposer(): void {
    this.host.state.composerOpen = false; this.host.state.optionsOpen = false;
    this.host.getUIContext().getFocusController().clearFocus();
  }





  chooseTrait(target: string, key: string, current: string[]): void {
    let next: string[] = [];
    if (key === 'auto') {
      next = ['auto'];
    } else if (key !== 'none') {
      next = current.includes(key) ? current.filter((item: string) => item !== key) :
        [...current.filter((item: string) => item !== 'auto'), key];
    }
    if (target === 'goal') { this.host.state.goalTraits = next; }
    else if (target === 'repeat') { this.host.state.repeatTraits = next; }
    else if (target === 'draft') { this.host.state.draftTraits = next; }
    else if (target === 'pinned') { this.host.state.pinnedEditTraits = next; }
    else { this.host.state.editTraits = next; }
  }

  selectionFor(target: string): string[] {
    return target === 'goal' ? this.host.state.goalTraits : target === 'repeat' ? this.host.state.repeatTraits :
      target === 'draft' ? this.host.state.draftTraits : target === 'pinned' ? this.host.state.pinnedEditTraits : this.host.state.editTraits;
  }

  pointsFor(target: string): TraitPoints[] {
    return target === 'goal' ? this.host.state.goalPoints : target === 'repeat' ? this.host.state.repeatPoints :
      target === 'draft' ? this.host.state.draftPoints : target === 'pinned' ? this.host.state.pinnedEditPoints : this.host.state.editPoints;
  }

  setPoints(target: string, key: string, text: string): void {
    const points: number = Math.max(1, Math.floor(Number(text)) || 1);
    const next: TraitPoints[] = [...this.pointsFor(target).filter((item: TraitPoints) => item.key !== key), { key, points }];
    if (target === 'goal') { this.host.state.goalPoints = next; }
    else if (target === 'repeat') { this.host.state.repeatPoints = next; }
    else if (target === 'draft') { this.host.state.draftPoints = next; }
    else if (target === 'pinned') { this.host.state.pinnedEditPoints = next; }
    else { this.host.state.editPoints = next; }
  }

  nextTaskId(): number {
    return RoutineCommands.nextId(this.host.snapshot(), Date.now());
  }

  async addTask(title: string, subtitle: string = '', assignedTraits?: string[], assignedPoints: TraitPoints[] = [],
    day: string = dayKey(), done: boolean = false, commissionId: number = -1, progressValue: number = 1): Promise<boolean> {
    return this.host.mutate(async (): Promise<RoutineSnapshot> => {
      if (!title.trim()) { throw new Error('请输入事项标题'); }
      RoutineCommands.validateDate(day, done, dayKey());
      const selected: string[] | undefined = assignedTraits === undefined ? undefined : this.ui.queries.validTraitKeys(assignedTraits);
      const task: HabitRecord = makeHabitRecord(this.nextTaskId(), day, title.trim(), subtitle, false, [], selected,
        this.ui.queries.normalizedPoints(selected ?? [], assignedPoints));
      task.day = done ? undefined : day || undefined; task.createdAt = Date.now(); task.updatedAt = task.createdAt;
      if (commissionId >= 0) {
        task.commissionId = commissionId; task.progressValue = progressValue;
      }
      const keys: string[] = done && selected === undefined ?
        (await this.ui.analyzer.analyze(`${title} ${subtitle}`)).hits.map((hit: TraitHit) => hit.key) : selected ?? [];
      return RoutineCommands.addTask(this.host.snapshot(), task, day, done, keys);
    });
  }

  async addDraftTask(): Promise<void> {
    const actualDay: string = this.host.state.draftDay === '-' ? '' : this.host.state.draftDay || dayKey();
    const wasDone: boolean = this.host.state.draftDone;
    if (await this.addTask(this.host.state.newTaskDraft, this.host.state.draftSubtitle,
      this.ui.queries.assignedSelection(this.host.state.draftTraits), this.host.state.draftPoints,
      actualDay, wasDone, this.host.state.draftCommissionId, Number(this.host.state.draftProgressValue))) {
      this.host.state.newTaskDraft = ''; this.host.state.draftSubtitle = ''; this.host.state.draftTraits = ['auto']; this.host.state.draftPoints
        = []; this.host.state.draftDay = ''; this.host.state.draftDone = false;
      this.host.state.draftError = ''; this.host.state.draftDateOpen = false; this.host.state.draftTraitOpen = false;
      this.host.state.optionsOpen = false;
      if (this.host.state.mainPage !== '今日') { this.host.state.composerOpen = false; }
      this.host.getUIContext().getFocusController().clearFocus();
      this.host.state.draftCommissionId = -1; this.host.state.draftProgressValue = '1';
      this.ui.feedback.toast(wasDone ? `已记录到 ${actualDay}` : actualDay ? `已安排到 ${actualDay}` : '已保存为未安排事项');
    } else { this.host.state.draftError = this.host.state.notice; }
  }

  async reuseYesterday(): Promise<void> {
    let added: number = 0;
    if (await this.host.mutate(async (): Promise<RoutineSnapshot> => {
      const state: RoutineSnapshot = this.host.snapshot();
      const next: RoutineSnapshot = RoutineCommands.reuseYesterday(state, dayKey(), yesterdayKey(), Date.now());
      added = next.habits.length - state.habits.length; return next;
    })) { this.ui.feedback.toast(`已加入 ${added} 条昨天的事项`); }
  }

  startPinnedEditing(item: PinnedTask): void {
    if (this.host.state.editingPinnedId === item.id) {
      return;
    }
    this.host.state.pinnedEditTitle = item.title;
    this.host.state.pinnedEditSubtitle = item.subtitle;
    this.host.state.pinnedEditTraits = item.assignedTraits === undefined ? ['auto'] : [...item.assignedTraits];
    this.host.state.pinnedEditPoints = [...item.assignedPoints ?? []];
    this.host.state.editingPinnedId = item.id;
    this.host.state.pressedPinnedId = -1;
  }

  async savePinnedEditing(): Promise<void> {
    if (await this.host.mutate(async (): Promise<RoutineSnapshot> => {
      if (!this.host.state.pinnedEditTitle.trim()) { throw new Error('请输入事项标题'); }
      const task: PinnedTask = {
        id: this.host.state.editingPinnedId === -2 ? this.nextTaskId() : this.host.state.editingPinnedId, title:
          this.host.state.pinnedEditTitle.trim(), subtitle: this.host.state.pinnedEditSubtitle.trim(),
        assignedTraits: this.ui.queries.assignedSelection(this.host.state.pinnedEditTraits),
        assignedPoints: this.ui.queries.normalizedPoints(this.ui.queries.assignedSelection(this.host.state.pinnedEditTraits) ?? [],
          this.host.state.pinnedEditPoints)
      };
      if (this.host.state.editingPinnedId === -2) { const next: RoutineSnapshot = RoutineEngine.clone(this.host.snapshot());
        next.pinnedTasks.push(task); return next; }
      return RoutineCommands.editPinned(this.host.snapshot(), task);
    })) { this.host.state.editingPinnedId = -1; }
  }

  async removePinned(id: number): Promise<void> {
    await this.host.mutate(async (): Promise<RoutineSnapshot> => RoutineCommands.removePinned(this.host.snapshot(), id));
  }

  async quickPinned(item: PinnedTask): Promise<void> {
    if (this.ui.queries.pinnedAdded(item, this.host.state.habits, dayKey())) {
      try { this.ui.feedback.toast('已在今天'); }
      catch (error) { this.host.state.draftError = '已在今天'; }
      return;
    }
    await this.addTask(item.title, item.subtitle, item.assignedTraits, item.assignedPoints ?? []);
  }

  openOptions(): void {
    this.host.getUIContext().getFocusController().clearFocus(); this.host.state.optionsOpen = true;
  }

  setQuickDone(done: boolean): void {
    this.host.state.draftDone = done; this.host.state.draftDay = ''; this.host.state.draftError = '';
  }

  async submitQuick(): Promise<void> {
    if (!this.host.state.newTaskDraft.trim()) { this.ui.feedback.focusDraft(); return; }
    await this.addDraftTask();
  }

  startNewPinned(): void {
    this.host.state.editingPinnedId = -2; this.host.state.pinnedEditTitle = ''; this.host.state.pinnedEditSubtitle = '';
    this.host.state.pinnedEditTraits = ['auto']; this.host.state.pinnedEditPoints = [];
  }

  async movePinned(id: number, offset: number): Promise<void> {
    await this.host.mutate(async (): Promise<RoutineSnapshot> => {
      const next: RoutineSnapshot = RoutineEngine.clone(this.host.snapshot());
      const index: number = next.pinnedTasks.findIndex((item: PinnedTask) => item.id === id); const target: number = index + offset;
      if (index >= 0 && target >= 0 && target < next.pinnedTasks.length) {
        const item: PinnedTask = next.pinnedTasks[index]; next.pinnedTasks.splice(index, 1); next.pinnedTasks.splice(target, 0, item);
      } return next;
    });
  }
  setDate(target: string, done: boolean, value: string): void {
    if (target === 'draft') { this.host.state.draftDay = value || '-'; this.host.state.draftError = ''; }
    else if (target === 'batch') { this.host.state.batchDay = value; }
    else if (target === 'deadline') { this.host.state.goalDeadline = value; }
    else if (target === 'progress') { this.host.state.progressDay = value; }
    else if (target === 'repeat') { this.host.state.repeatStart = value; }
    else if (done) { this.host.state.editActivityDay = value; }
    else { this.host.state.editDay = value; }
  }
  chooseDate(target: string, done: boolean, offset: number): void { this.setDate(target, done, shiftDay(offset)); }
}
