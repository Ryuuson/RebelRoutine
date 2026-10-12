import { EmptyState } from '../components/EmptyState';
import { humanDate } from '../common/DayUtil';
import { RoutineState } from '../common/RoutineState';
import { HabitRecord } from '../data/RoutineStore';
import { INK, PAPER, RED, SHEAR, UNSHEAR } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton } from '../components/CutWidgets';
import { ScreenIdentity } from '../components/ScreenIdentity';
import { CutSurface } from '../components/CutSurface';
import { Composer } from '../components/Composer';
import { TaskRow } from '../components/TaskRow';
import { SelectionControls } from '../components/SelectionControls';
import { CommissionList } from './CommissionList';
import { CommissionChoice } from '../components/CommissionChoices';

@Component
export struct TaskView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  @Builder
  private taskGroup(group: string, items: HabitRecord[]) {
    if (items.length > 0) {
      CutSurface() {
        Column({ space: 3 }) {
          Row() {
            Text(group).fontSize(20).fontWeight(FontWeight.Bolder).fontColor(INK).transform(UNSHEAR);
            Blank().layoutWeight(1);
            Text(`${items.length}`).fontSize(25).fontStyle(FontStyle.Italic).fontWeight(FontWeight.Bolder)
              .fontColor(RED).transform(UNSHEAR);
          }.width('96%').padding({ left: 9, right: 10, top: 1, bottom: 1 }).backgroundColor(PAPER).transform(SHEAR);
          if (group === '未来') {
            ForEach(Array.from(new Set(items.map((item: HabitRecord) => item.day ?? ''))), (day: string) => {
              Text(humanDate(day)).fontSize(12).fontWeight(FontWeight.Bold).fontColor(PAPER)
                .padding({ left: 12, top: 7, bottom: 2 }).alignSelf(ItemAlign.Start);
              ForEach(items.filter((item: HabitRecord) => item.day === day), (item: HabitRecord) => {
                TaskRow({ state: this.state, item: item, ui: this.ui });
              }, (item: HabitRecord) => `${item.id}-${this.state.renderEpoch}`);
            }, (day: string) => `${day}-${this.state.renderEpoch}`);
          } else {
            ForEach(items, (item: HabitRecord) => {
              TaskRow({ state: this.state, item: item, ui: this.ui });
            }, (item: HabitRecord) => `${item.id}-${this.state.renderEpoch}`);
          }
        }.width('100%').padding({ left: 8, right: 8, top: 12, bottom: 14 });
      }
    }
  }
  build() {
    Scroll(this.ui.host.taskScroller) {
      Column({ space: 10 }) {
        Row({ space: 6 }) {
          ScreenIdentity().layoutWeight(1);
          Column() {
            CutButton({ label: '新建', selected: true, action: () => {
              if (this.state.taskSection === '委托') { this.ui.commissions.edit(); } else { this.ui.draft.openComposer(false); }
            } })
              .enabled(!this.state.selectionPage).opacity(this.state.selectionPage ? 0.45 : 1);
            CutButton({ label: '菜单', selected: false, action: () => this.ui.host.openWorkspace('menu') });
          }
        }.width('100%');
        Row() {
          CommissionChoice({ label: '事项', selected: this.state.taskSection === '事项', action: () => {
            this.ui.batch.exit(); this.state.taskSection = '事项';
          } });
          CommissionChoice({ label: '委托', selected: this.state.taskSection === '委托', action: () => {
            this.ui.batch.exit(); this.state.taskSection = '委托';
          } });
          Blank().layoutWeight(1);
          CutButton({ label: '重复计划', selected: false, action: () => this.ui.host.openWorkspace('repeats') });
        }.width('100%');
        if (this.state.taskSection === '委托') { CommissionList({ state: this.state, ui: this.ui }); }
        else {
        SelectionControls({ state: this.state, ui: this.ui, page: '任务' });
        if (this.state.composerOpen) { Composer({ state: this.state, ui: this.ui }) }
        if (this.ui.queries.libraryHabits(this.state.habits, this.state.today, '全部').length === 0) {
          EmptyState({ message: '没有待办事项' }).backgroundColor(INK);
        }
        ForEach(['待处理', '今天', '未来', '未安排'], (group: string) => {
          this.taskGroup(group, this.ui.queries.tasksIn(group, this.state.habits, this.state.today));
        }, (group: string) => `${group}-${this.state.renderEpoch}`);
        }
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 18, right: 18, top: 20, bottom: 24 });
    }.width('100%').height('100%').align(Alignment.TopStart).scrollBar(BarState.Off);
  }
}
