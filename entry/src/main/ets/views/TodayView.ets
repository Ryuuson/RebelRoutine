import { EmptyState } from '../components/EmptyState';
import { RoutineState } from '../common/RoutineState';
import { HabitRecord, PinnedTask } from '../data/RoutineStore';
import { INK, PAPER, STEEL } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton, cutLabel } from '../components/CutWidgets';
import { TodayIdentity } from '../components/ScreenIdentity';
import { CutSurface } from '../components/CutSurface';
import { Composer } from '../components/Composer';
import { MorganaSnsPrompt } from '../components/MorganaDialog';
import { TaskRow } from '../components/TaskRow';
@Component
export struct TodayView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  @State overdueOpen: boolean = false;
  @Builder
  private pinnedShortcut(item: PinnedTask, added: boolean) {
                Stack() {
                  Image($r('app.media.pinned_choice')).width('100%').height('100%').objectFit(ImageFit.Fill);
                  Text(`${added ? '✓ ' : ''}${item.title}`)
                    .fontSize(12).fontWeight(FontWeight.Bold).fontColor(added ? STEEL : PAPER)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    .padding({ left: 17, right: 21 });
                }.width(Math.min(220, Math.max(108, item.title.length * 12 + 62))).height(42).opacity(added ? 0.55 : 1)
                  .onClick(() => this.ui.draft.quickPinned(item)).enabled(this.state.dataReady && !this.state.mutationBusy);
  }
  build() {
    Scroll(this.ui.host.todayScroller) {
      Column({ space: 12 }) {
        TodayIdentity({ state: this.state, ui: this.ui });
        Column({ space: 10 }) {
          MorganaSnsPrompt({ ui: this.ui });
          Scroll() {
            Row({ space: 6 }) {
              ForEach(this.state.pinnedTasks, (item: PinnedTask) => {
                this.pinnedShortcut(item, this.ui.queries.pinnedAdded(item, this.state.habits, this.state.today));
              }, (item: PinnedTask) => `${item.id}-${this.state.renderEpoch}`);
              if (this.ui.queries.hasYesterday(this.state.habits, this.state.today)) { CutButton({ label: '照昨天', selected: false, action: () =>
                this.ui.draft.reuseYesterday() }); }
              CutButton({ label: '编辑', selected: false, action: () => this.ui.host.openWorkspace('pinned') });
            }
          }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off);
          Composer({ state: this.state, ui: this.ui })
          if (this.ui.queries.overdueCount(this.state.habits, this.state.today) > 0) {
            CutButton({ label: `有 ${this.ui.queries.overdueCount(this.state.habits, this.state.today)} 件之前没做完`, selected: this.overdueOpen,
              action: () => this.overdueOpen = !this.overdueOpen });
            if (this.overdueOpen) {
              ForEach(this.ui.queries.tasksIn('待处理', this.state.habits, this.state.today), (item: HabitRecord) => {
                Column({ space: 5 }) {
                  Text(item.title).fontSize(15).fontWeight(FontWeight.Bold).fontColor(PAPER);
                  Row() {
                    CutButton({ label: '今天做', selected: true, action: () => this.ui.lifecycle.rescheduleToday(item.id) });
                    CutButton({ label: '编辑', selected: false, action: () => {
                      this.ui.feedback.openAction(item.id); this.ui.lifecycle.sheetOperation('edit');
                    } });
                  }
                }.width('100%').alignItems(HorizontalAlign.Start).padding(12).backgroundColor(INK);
              }, (item: HabitRecord) => `${item.id}-${this.state.renderEpoch}`);
            }
          }
          Row() {
            cutLabel('今日', '待办', 19);
            Blank().layoutWeight(1);
            CutButton({ label: this.state.isFocusing ? `专注 ${this.ui.focus.formattedTime(this.state.remainingSeconds)}` : '开始专注', selected: false,
              action: () => this.ui.host.openWorkspace('focus') });
          }.width('100%').margin({ top: 8 });
          CutSurface() {
            Column({ space: 2 }) {
              if (this.ui.queries.todayHabits(this.state.habits, this.state.today).length === 0) {
                Column({ space: 4 }) {
                  EmptyState({ message: '今天还没有安排', inset: 0 });
                }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 20, right: 20, top: 10, bottom: 10 });
              }
              ForEach(this.ui.queries.todaySorted(this.state.habits, this.state.today), (item: HabitRecord) => {
                TaskRow({ state: this.state, item: item, todayStyle: true, ui: this.ui });
              }, (item: HabitRecord) => `${item.id}-${this.state.renderEpoch}`);
            }.width('100%').alignItems(HorizontalAlign.Start).padding({ top: 8, bottom: 12 });
          }
        }.width('100%').padding({ left: 18, right: 18 }).alignItems(HorizontalAlign.Start);
      }.width('100%').padding({ bottom: 24 });
    }.width('100%').height('100%').align(Alignment.TopStart).scrollBar(BarState.Off);
  }

}
