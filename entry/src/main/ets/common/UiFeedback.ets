import { RoutineHost } from './RoutineHost';

import { PageActions } from './PageActions';

export class UiFeedback {
  private readonly host: RoutineHost;
  private readonly ui: PageActions;
  constructor(host: RoutineHost, ui: PageActions) { this.host = host; this.ui = ui; }
  toast(message: string): void { this.host.getUIContext().getPromptAction().showToast({ message }); }
  confirm(operation: string, text: string): void {
    this.host.state.pendingConfirm = operation; this.host.state.confirmText = text;
  }
  workspaceTitleRed(workspace: string = this.host.state.workspace): string {
    return workspace === 'pinned' ? '固定' : workspace === 'focus' ? '专注' : workspace === 'data' ? '数据' :
      workspace === 'notes' ? '相关' : workspace === 'commission' ? '委托' : workspace === 'repeats' ? '重复' :
      workspace === 'manage' ? '回收' : '怪盗';
  }

  workspaceTitleWhite(workspace: string = this.host.state.workspace): string {
    return workspace === 'pinned' ? '事项' : workspace === 'focus' ? '时间' : workspace === 'data' ? '管理' :
      workspace === 'notes' ? '便签' : workspace === 'commission' ? '详情' : workspace === 'repeats' ? '计划' :
      workspace === 'manage' ? '站' : '菜单';
  }

  focusDraft(): void {
    try { this.host.getUIContext().getFocusController().requestFocus(this.host.state.optionsOpen ? 'routine-options-title' : 'routine-title'); }
    catch (error) { this.host.state.draftError = '请点输入框填写事项'; }
  }

  jumpToRecord(day: string): void { this.host.switchPage('记录'); this.host.state.recordTargetDay = day; }

  jumpToTrait(key: string): void { this.host.switchPage('记录'); this.host.state.recordTargetTrait = key; }

  clearRecordFilter(): void {
    this.ui.batch.exit(); this.host.state.recordTargetDay = ''; this.host.state.recordTargetTrait = '';
    this.host.state.recordTargetCommission = -1;
  }

  openAction(id: number, legacy: boolean = false): void {
    this.host.getUIContext().getFocusController().clearFocus(); this.ui.dialogue.dismissFeedback();
    this.host.state.actionMenuId = id; this.host.state.actionMenuLegacy = legacy; this.host.state.sheetMode = 'actions';
  }
}
