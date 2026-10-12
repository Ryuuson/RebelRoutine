import { BatchRequest, RecordRef, CompletionReward, RoutineSnapshot, HabitRecord, TraitPoints } from '../data/RoutineModel';
import { RoutineBatch } from '../data/RoutineBatch';
import { TraitHit, TRAIT_DEFINITIONS, TraitDefinition } from '../data/TraitAnalyzer';
import { MorganaEvent } from '../data/MorganaFeedback';
import { RoutineHost } from './RoutineHost';
import { PageActions } from './PageActions';
import { dayKey } from './DayUtil';

export class BatchActions {
  private readonly host: RoutineHost;
  private readonly ui: PageActions;
  constructor(host: RoutineHost, ui: PageActions) { this.host = host; this.ui = ui; }

  enter(page: string): void {
    if (this.host.state.mutationBusy) { return; }
    this.ui.draft.collapseComposer(); this.ui.dialogue.dismissFeedback();
    this.host.state.actionMenuId = -1; this.host.state.selectionPage = page;
    this.host.state.selectedRefs = []; this.host.state.notice = '';
  }

  exit(): void {
    this.host.state.selectionPage = ''; this.host.state.selectedRefs = []; this.host.state.batchEditing = false;
    this.host.state.pendingBatch = undefined;
  }

  selected(ref: RecordRef, refs: RecordRef[] = this.host.state.selectedRefs): boolean {
    return refs.some((item: RecordRef) => RoutineBatch.key(item) === RoutineBatch.key(ref));
  }

  toggle(ref: RecordRef): void {
    if (this.host.state.mutationBusy) { return; }
    const selected: RecordRef[] = this.host.state.selectedRefs;
    this.host.state.selectedRefs = this.selected(ref) ? selected.filter((item: RecordRef) =>
      RoutineBatch.key(item) !== RoutineBatch.key(ref)) : [...selected, ref];
  }

  visible(): RecordRef[] {
    if (this.host.state.selectionPage === '任务') {
      return this.ui.queries.libraryHabits().map((item: HabitRecord): RecordRef => ({ id: item.id, action: false }));
    }
    if (this.host.state.selectionPage === '记录') {
      const days: string[] = this.ui.queries.recordDays();
      return this.ui.queries.historyEntries().filter((entry) => days.includes(entry.day)).map((entry): RecordRef =>
        ({ id: entry.id, action: entry.action }));
    }
    return [...this.ui.queries.collectionHabits(this.host.state.habits, this.host.state.today, '回收站')
      .map((item: HabitRecord): RecordRef => ({ id: item.id, action: false })),
      ...this.host.state.actions.filter((item) => item.deletedAt !== undefined).map((item): RecordRef => ({ id: item.id, action: true }))];
  }

  selectAll(): void { this.host.state.selectedRefs = this.visible(); }
  clear(): void { this.host.state.selectedRefs = []; }
  canEdit(refs: RecordRef[] = this.host.state.selectedRefs): boolean {
    return refs.length > 0 && !refs.some((ref: RecordRef) => ref.action);
  }

  openEdit(): void {
    if (!this.canEdit()) { this.ui.feedback.toast('批量编辑适用于完整事项记录；旧版记录可删除'); return; }
    this.host.state.batchDay = dayKey(); this.host.state.batchEditing = true; this.host.state.notice = '';
  }

  async request(operation: string, refs: RecordRef[] = this.host.state.selectedRefs): Promise<void> {
    if (this.host.state.mutationBusy || !this.host.state.dataReady) { return; }
    const request: BatchRequest = { refs: refs.map((ref: RecordRef): RecordRef => ({ id: ref.id, action: ref.action })), operation };
    if (operation === 'date') { request.day = this.host.state.batchDay; }
    if (operation === 'delete' || operation === 'purge') {
      try {
        const state: RoutineSnapshot = this.host.snapshot();
        const next: RoutineSnapshot = RoutineBatch.apply(state, request, dayKey());
        const removed: number = RoutineBatch.removed(state, next);
        this.host.state.pendingBatch = request; this.host.state.pendingBatchRevision = state.revision;
        this.ui.feedback.confirm('batch', operation === 'purge' ? `永久删除 ${refs.length} 条？此操作无法恢复。` :
          `将 ${refs.length} 条移入回收站。${removed > 0 ? '相关成长会一并撤回，恢复时还原。' : '可在回收站恢复。'}`);
      } catch (error) { this.host.showError(error); }
      return;
    }
    await this.execute(request);
  }

  async confirm(): Promise<void> {
    const request: BatchRequest | undefined = this.host.state.pendingBatch;
    if (!request) { return; }
    if (this.host.state.revision !== this.host.state.pendingBatchRevision) {
      this.host.showError(new Error('数据已变化，请取消后重新确认操作')); return;
    }
    await this.execute(request);
  }

  private async execute(request: BatchRequest): Promise<void> {
    let amounts: TraitPoints[] = [];
    const previousRanks: number[] = TRAIT_DEFINITIONS.map((trait: TraitDefinition) => this.ui.queries.traitRank(trait.key));
    const saved: boolean = await this.host.mutate(async (): Promise<RoutineSnapshot> => {
      const state: RoutineSnapshot = this.host.snapshot();
      const rewards: CompletionReward[] = [];
      if (request.operation === 'complete') {
        for (const ref of request.refs) {
          const item: HabitRecord | undefined = state.habits.find((record: HabitRecord) => record.id === ref.id);
          if (!item || ref.action) { throw new Error('待办不存在'); }
          const keys: string[] = item.assignedTraits === undefined ?
            (await this.ui.analyzer.analyze(`${item.title} ${item.subtitle}`)).hits.map((hit: TraitHit) => hit.key) :
            this.ui.queries.validTraitKeys(item.assignedTraits);
          rewards.push({ id: item.id, keys, points: item.assignedPoints ?? [] });
        }
      }
      const next: RoutineSnapshot = RoutineBatch.apply(state, request, dayKey(), rewards);
      amounts = next.traitTotals.map((total): TraitPoints => ({ key: total.key, points: total.score -
        (state.traitTotals.find((item) => item.key === total.key)?.score ?? 0) })).filter((point: TraitPoints) => point.points > 0);
      return next;
    });
    if (!saved) { return; }
    this.host.state.pendingConfirm = ''; this.host.state.pendingBatch = undefined;
    this.host.state.actionMenuId = -1; this.host.state.editingHabitId = -1; this.exit();
    if (this.host.state.libraryFilter === '旧隐藏事项' && !this.ui.queries.hasHidden(this.host.state.habits)) {
      this.host.state.libraryFilter = '回收站';
    }
    if (request.operation === 'complete') {
      const raised: boolean = TRAIT_DEFINITIONS.some((trait: TraitDefinition, index: number) =>
        this.ui.queries.traitRank(trait.key) > previousRanks[index]);
      this.ui.dialogue.queueFeedback(raised ? MorganaEvent.RankUp : this.ui.queries.todayHabits().every((item) => item.done) ?
        MorganaEvent.Clear : MorganaEvent.Complete, amounts.map((point: TraitPoints) => point.key), 1, amounts);
    } else { this.ui.feedback.toast(`${request.operation === 'date' ? '已修改' : request.operation === 'delete' ? '已移入回收站' :
      request.operation === 'purge' ? '已永久删除' : '已恢复'} ${request.refs.length} 条`); }
  }
}
