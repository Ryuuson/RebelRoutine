import { UI_BODY_WEIGHT } from '../common/Typography';
import { KeyboardAvoidMode as UIKeyboardAvoidMode } from '@kit.ArkUI';
import { RoutineState } from '../common/RoutineState';
import { OptionsSheet } from '../components/OptionsSheet';
import { ActionSheet } from '../components/ActionSheet';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { RoutineStore, RoutineSnapshot } from '../data/RoutineStore';

import { PageActions } from '../common/PageActions';
import { INK, PAPER, STEEL } from '../common/Theme';
import { dayKey } from '../common/DayUtil';
import { RecordView } from '../views/RecordView';
import { MenuView } from '../views/MenuView';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { TodayView } from '../views/TodayView';
import { MainNavigation } from '../views/MainNavigation';
import { TaskView } from '../views/TaskView';
import { GrowthView } from '../views/GrowthView';
import { MorganaDialog } from '../components/MorganaDialog';
import { CutButton, cutLabel } from '../components/CutWidgets';
import { BatchBar } from '../components/BatchBar';
import { BatchEditSheet } from '../components/BatchEditSheet';
import { CityBackdrop } from '../components/CityBackdrop';
import { CommissionEngine } from '../data/CommissionEngine';
import { CommissionSheet } from '../components/CommissionSheet';
import { WindowLayout } from '../common/WindowLayout';
import { NotesView } from '../views/NotesView';
import { NoteEditor } from '../components/NoteEditor';
import { Motion } from '../common/Motion';

@Entry
@Component
struct Index {
  @State state: RoutineState = new RoutineState();
  @StorageProp('routineForeground') @Watch('refreshToday') foregroundEpoch: number = 0;
  private dayTimerId: number = -1;
  store?: RoutineStore;
  private mainWindow?: window.Window;
  private pageActive: boolean = false;
  private readonly keyboardListener = (height: number): void => { this.state.keyboardVisible = height > 0; };
  private readonly windowSizeListener = (): void => { this.refreshInsets(); };
  private readonly avoidAreaListener = (options: window.AvoidAreaOptions): void => {
    if (options.type !== window.AvoidAreaType.TYPE_KEYBOARD) { this.refreshInsets(); }
  };
  private refreshInsets(): void {
    if (this.mainWindow) {
      this.state.screenInsets = WindowLayout.insets(this.mainWindow,this.state.screenInsets);
      this.state.windowSize = WindowLayout.size(this.mainWindow,this.state.windowSize);
    }
  }
  readonly todayScroller: Scroller = new Scroller();
  readonly taskScroller: Scroller = new Scroller();
  readonly recordScroller: Scroller = new Scroller();
  readonly growthScroller: Scroller = new Scroller();
  readonly actionsUI: PageActions = new PageActions(this);

  onPageShow(): void { this.refreshToday(); this.startDayTimer(); }
  onPageHide(): void { this.clearDayTimer(); }
  startDayTimer(): void {
    this.clearDayTimer(); this.dayTimerId = setInterval(() => this.refreshToday(), 60000);
  }
  clearDayTimer(): void {
    if (this.dayTimerId !== -1) { clearInterval(this.dayTimerId); this.dayTimerId = -1; }
  }
  refreshToday(): void {
    this.state.today = dayKey(); this.actionsUI.updateCompletedCount();
    if (this.state.m2) { this.actionsUI.commissions.refreshRepeats(); }
  }
  aboutToAppear(): void {
    this.refreshToday(); this.startDayTimer();
    this.pageActive = true;
    const context = getContext(this) as common.UIAbilityContext;
    this.store = new RoutineStore(context);
    this.restoreState();
    this.getUIContext().setKeyboardAvoidMode(UIKeyboardAvoidMode.RESIZE);
    window.getLastWindow(context).then((win: window.Window) => {
      if (!this.pageActive) { return; }
      this.mainWindow = win;
      this.refreshInsets();
      win.on('keyboardHeightChange', this.keyboardListener);
      win.on('avoidAreaChange', this.avoidAreaListener);
      win.on('windowSizeChange', this.windowSizeListener);
    }).catch(() => {});
  }
  aboutToDisappear(): void {
    this.clearDayTimer();
    this.pageActive = false;
    this.actionsUI.focus.stopTimer();
    this.actionsUI.dialogue.dismissFeedback();
    if (this.mainWindow) {
      this.mainWindow.off('keyboardHeightChange', this.keyboardListener);
      this.mainWindow.off('avoidAreaChange', this.avoidAreaListener);
      this.mainWindow.off('windowSizeChange', this.windowSizeListener);
    }
  }
  snapshot(): RoutineSnapshot {
    return { version: 2, revision: this.state.revision, habits: this.state.habits,
      pinnedTasks: this.state.pinnedTasks, actions: this.state.actions, traitTotals: this.state.traitTotals,
      activeDay: this.state.activeDay || dayKey(), m2: this.state.m2, notes: this.state.notes };
  }
  adopt(state: RoutineSnapshot): void {
    this.state.renderEpoch += 1;
    this.state.habits = state.habits; this.state.pinnedTasks = state.pinnedTasks;
    this.state.actions = state.actions; this.state.traitTotals = state.traitTotals;
    this.state.notes = state.notes ?? [];
    this.state.m2 = state.m2;
    this.state.activeDay = dayKey(); this.state.today = dayKey(); this.state.revision = state.revision;
    this.actionsUI.updateCompletedCount(); this.actionsUI.queries.cacheHistory();
  }
  showError(error: Error): void {
    this.state.notice = `操作未保存：${error.message || String(error)}`;
    this.actionsUI.feedback.toast(this.state.notice);
  }
  async restoreState(): Promise<void> {
    this.state.dataReady = false;
    try {
      if (!this.store) { return; }
      this.adopt(await this.store.loadM2Snapshot(dayKey()));
      this.state.dataReady = true; this.state.dataError = "";
      await this.actionsUI.commissions.refreshRepeats();
    } catch (error) { this.state.dataError = `数据异常：${error.message || String(error)}`; this.showError(error); }
  }
  async mutate(operation: () => Promise<RoutineSnapshot>, settle: boolean = true): Promise<boolean> {
    if (this.state.mutationBusy || !this.state.dataReady) { return false; }
    this.state.mutationBusy = true;
    try {
      const before: RoutineSnapshot = this.snapshot();
      const candidate: RoutineSnapshot = await operation();
      const next: RoutineSnapshot = settle && candidate.m2 ? CommissionEngine.reconcile(before,candidate,dayKey()) : candidate;
      next.revision = this.state.revision + 1; next.activeDay = dayKey();
      if (this.store) { await this.store.saveSnapshot(next); }
      this.adopt(next); this.state.notice = '';
      return true;
    } catch (error) { this.showError(error); return false; }
    finally { this.state.mutationBusy = false; }
  }
  switchPage(page: string): void {
    if (this.state.mutationBusy) { return; }
    this.actionsUI.batch.exit();
    this.state.mainPage = page; this.state.recordTargetDay = ''; this.state.recordTargetTrait = '';
    this.state.recordSection = '行动';
    this.state.recordTargetCommission = -1;
    this.state.editingHabitId = -1; this.state.editingPinnedId = -1; this.state.actionMenuId = -1;
    this.actionsUI.dialogue.dismissFeedback();
  }
  openWorkspace(name: string): void {
    if (this.state.mutationBusy) { return; }
    this.actionsUI.batch.exit();
    this.state.workspaceStack.push(this.state.workspace);
    this.state.workspace = name;
  }
  closeWorkspace(): void {
    if (this.state.mutationBusy) { return; }
    this.actionsUI.batch.exit();
    this.state.workspace = this.state.workspaceStack.pop() ?? '';
    this.state.editingHabitId = -1; this.state.editingPinnedId = -1; this.state.actionMenuId = -1;
  }
  onBackPress(): boolean {
    if (this.state.mutationBusy) { return true; }
    if (this.state.pendingConfirm) {
      this.state.pendingConfirm = ''; this.state.pendingBackup = undefined; this.state.pendingBatch = undefined; return true;
    }
    if (this.state.noteEditing) {
      if (this.state.noteLinkPicking) { this.state.noteLinkPicking = false; }
      else { this.actionsUI.notes.requestClose(); }
      return true;
    }
    if (this.state.goalEditing || this.state.progressOpen || this.state.repeatEditing) {
      this.state.goalEditing = false; this.state.progressOpen = false; this.state.repeatEditing = false; return true;
    }
    if (this.state.workspace === 'commission' && this.state.commissionTrail.length) {
      this.state.commissionId = this.state.commissionTrail.pop()!; return true;
    }
    if (this.state.batchEditing) { this.state.batchEditing = false; return true; }
    if (this.state.selectionPage) { this.actionsUI.batch.exit(); return true; }
    if (this.state.optionsOpen) { this.state.optionsOpen = false; return true; }
    if (this.state.actionMenuId !== -1) { this.state.actionMenuId = -1; this.state.editingHabitId = -1; return true; }
    if (this.state.editingHabitId !== -1 || this.state.editingPinnedId !== -1) { this.state.editingHabitId = -1; this.state.editingPinnedId = -1; return true; }
    if (this.state.workspace) { this.closeWorkspace(); return true; }
    if (this.state.composerOpen && (this.state.draftDateOpen || this.state.draftTraitOpen)) { this.state.draftDateOpen = false;
      this.state.draftTraitOpen = false; return true; }
    if (this.state.composerOpen) { this.actionsUI.draft.collapseComposer(); return true; }
    if (this.state.mainPage !== '今日') { this.switchPage('今日'); return true; }
    return false;
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      CityBackdrop({ state: this.state });
      Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Stack() {
          if (this.state.mainPage === '今日') { TodayView({ state: this.state, ui: this.actionsUI }).transition(Motion.page()); }
          else if (this.state.mainPage === '任务') { TaskView({ state: this.state, ui: this.actionsUI }).transition(Motion.page()); }
          else if (this.state.mainPage === '记录') {
            if (this.state.recordSection === '便签') { NotesView({ state: this.state, ui: this.actionsUI }).transition(Motion.page()); }
            else { RecordView({ state: this.state, ui: this.actionsUI }).transition(Motion.page()); }
          }
          else { GrowthView({ state: this.state, ui: this.actionsUI }).transition(Motion.page()); }
        }.width('100%').layoutWeight(1);
        if (!this.state.keyboardVisible) {
          if (this.state.selectionPage) { BatchBar({ state: this.state, ui: this.actionsUI }); }
          else { MainNavigation({ state: this.state, ui: this.actionsUI }); }
        }
      }.width('100%').height('100%').visibility(this.state.workspace ? Visibility.Hidden : Visibility.Visible);
      if (this.state.workspace) { MenuView({ state: this.state, 
          ui: this.actionsUI
         }).transition(Motion.workspace()); }

      if (this.state.optionsOpen) { OptionsSheet({ state: this.state, ui: this.actionsUI }).transition(Motion.sheet()); }
      if (this.state.actionMenuId !== -1) { ActionSheet({ state: this.state, ui: this.actionsUI }).transition(Motion.sheet()); }
      if (this.state.batchEditing) { BatchEditSheet({ state: this.state, ui: this.actionsUI }).transition(Motion.sheet()); }
      if (this.state.goalEditing || this.state.progressOpen || this.state.repeatEditing) {
        CommissionSheet({ state: this.state, ui: this.actionsUI }).transition(Motion.sheet());
      }
      if (this.state.noteEditing) { NoteEditor({ state: this.state, ui: this.actionsUI }).transition(Motion.editor()); }
      if (this.state.dataError) {
        Stack() {
          Column({ space: 14 }) {
            cutLabel('数据', '异常', 23);
            Text(this.state.dataError).fontWeight(UI_BODY_WEIGHT).fontSize(14).fontColor(PAPER);
            Text('其他写入已暂停。请先导出原始数据，再从兼容的完整备份恢复。').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL);
            CutButton({ label: '从备份恢复', selected: true, action: () => this.actionsUI.data.importData() });
            CutButton({ label: '导出原始数据', selected: false, action: () => this.actionsUI.data.exportRawData() });
          }.width('88%').padding(24).backgroundColor(INK).border({ width: 3, color: PAPER });
        }.width('100%').height('100%').backgroundColor('#E5000000');
      }
      if (this.state.pendingConfirm) { ConfirmDialog({ state: this.state, 
          ui: this.actionsUI
         }).transition(Motion.dialog()); }
      if (this.state.dialogVisible && !this.state.noteEditing && !this.state.workspace && !this.state.pendingConfirm &&
        !this.state.optionsOpen && this.state.actionMenuId === -1) {
        MorganaDialog({ state: this.state, ui: this.actionsUI });
      }
      }.width('100%').height('100%').padding({ top: this.state.screenInsets.top, left: this.state.screenInsets.left,
        right: this.state.screenInsets.right, bottom: this.state.keyboardVisible ? 0 : this.state.screenInsets.bottom });
    }.width(LayoutPolicy.matchParent).height(LayoutPolicy.matchParent).backgroundColor(INK)
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM],[LayoutSafeAreaEdge.ALL]);
  
  }
}
