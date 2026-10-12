import { RoutineSnapshot } from '../data/RoutineStore';
import { CommissionEngine } from '../data/CommissionEngine';
import { RoutineHost } from './RoutineHost';

import { PageActions } from './PageActions';

export class DataActions {
  private readonly host: RoutineHost;
  private readonly ui: PageActions;
  constructor(host: RoutineHost, ui: PageActions) { this.host = host; this.ui = ui; }
  async exportData(csv: boolean): Promise<void> {
    if (!this.host.store || this.host.state.mutationBusy || !this.host.state.dataReady) { return; }
    this.host.state.mutationBusy = true;
    try {
      if (await this.host.store.exportFile(this.host.snapshot(), csv)) { this.host.state.notice = csv ? '记录 CSV 已导出（不用于恢复）' : '完整备份已导出'; }
    } catch (error) { this.host.showError(error); }
    finally { this.host.state.mutationBusy = false; }
  }

  async importData(): Promise<void> {
    if (!this.host.store || this.host.state.mutationBusy) { return; }
    this.host.state.mutationBusy = true;
    try {
      const state: RoutineSnapshot | undefined = await this.host.store.selectBackup();
      if (state) {
        this.host.state.pendingBackup = state;
        const extra: string = state.m2 ? `、${state.m2.goals.length} 个委托、${state.m2.repeats.length} 个重复计划` : '';
        this.ui.feedback.confirm('import',
          `恢复 ${state.habits.length} 条事项、${state.pinnedTasks.length} 个固定模板、${state.actions.length} 条旧记录${extra}`+
          `、${state.notes?.length ?? 0} 条便签？将覆盖当前数据，并保留恢复前快照。`);
      }
    } catch (error) { this.host.showError(error); }
    finally { this.host.state.mutationBusy = false; }
  }

  async exportRawData(): Promise<void> {
    if (!this.host.store || this.host.state.mutationBusy) { return; }
    this.host.state.mutationBusy = true;
    try { if (await this.host.store.exportRaw()) { this.host.state.notice = '原始数据已导出（未经校验）'; } }
    catch (error) { this.host.showError(error); }
    finally { this.host.state.mutationBusy = false; }
  }

  requestRestoreUndo(): void {
    this.ui.feedback.confirm('undo-restore', '返回上一次恢复前的数据？恢复之后的新修改也会被替换，当前状态仍会保留为可撤回快照。');
  }

  async confirmOperation(): Promise<void> {
    if (this.host.state.mutationBusy || (!this.host.state.dataReady && this.host.state.pendingConfirm !== 'import')) { return; }
    const operation: string = this.host.state.pendingConfirm;
    if (operation.startsWith('note-')) { await this.ui.notes.confirm(operation); return; }
    if (operation === 'batch') { await this.ui.batch.confirm(); return; }
    if (operation === 'import' || operation === 'undo-restore') {
      if (!this.host.store) { return; }
      this.host.state.mutationBusy = true;
      try {
        if (operation === 'import' && this.host.state.pendingBackup) {
          const next: RoutineSnapshot = CommissionEngine.bootstrap(this.host.state.pendingBackup);
          await this.host.store.replaceSnapshot(next); this.host.adopt(next);
        } else if (operation === 'undo-restore') { this.host.adopt(await this.host.store.previousM2Restore()); }
        this.host.state.dataReady = true; this.host.state.dataError = '';
        this.host.state.pendingConfirm = ''; this.host.state.pendingBackup = undefined; this.host.state.editingHabitId = -1;
        this.host.state.editingPinnedId = -1; this.ui.dialogue.dismissFeedback(); this.host.state.notice = '数据已恢复';
        this.ui.batch.exit(); this.host.state.recordTargetDay = ''; this.host.state.recordTargetTrait = '';
        this.host.state.recordTargetCommission = -1; this.host.state.draftCommissionId = -1;
        this.host.state.goalEditing = false; this.host.state.repeatEditing = false; this.host.state.progressOpen = false;
        this.host.state.noteEditing = false; this.host.state.noteLinkPicking = false; this.host.state.noteContext = undefined;
      } catch (error) { this.host.showError(error); }
      finally { this.host.state.mutationBusy = false; }
    }
  }
}
