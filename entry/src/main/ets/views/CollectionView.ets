import { UI_BODY_WEIGHT } from '../common/Typography';
import { EmptyState } from '../components/EmptyState';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { HabitRecord, ActionRecord } from '../data/RoutineModel';
import { PAPER, STEEL } from '../common/Theme';
import { CutButton } from '../components/CutWidgets';
import { TaskRow } from '../components/TaskRow';
import { SelectionControls, SelectionMark, SelectionSurface } from '../components/SelectionControls';

@Component
export struct CollectionView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Column({ space: 12 }) {
      if (this.ui.queries.hasHidden(this.state.habits)) {
        Row({ space: 8 }) {
          CutButton({ label: '回收站', selected: this.state.libraryFilter === '回收站', action: () => {
            this.ui.batch.exit(); this.state.libraryFilter = '回收站';
          } });
          CutButton({ label: '旧隐藏事项', selected: this.state.libraryFilter === '旧隐藏事项', action: () => {
            this.ui.batch.exit(); this.state.libraryFilter = '旧隐藏事项';
          } });
        }.width('100%');
      }
      if (this.state.libraryFilter === '回收站') { SelectionControls({ state: this.state, ui: this.ui, page: '回收站' }); }
      if (this.ui.queries.collectionEmpty(this.state.habits, this.state.today, this.state.libraryFilter, this.state.actions)) {
        EmptyState({ message: '暂无事项' });
      }
      ForEach(this.ui.queries.collectionHabits(this.state.habits, this.state.today, this.state.libraryFilter), (item: HabitRecord) => {
        TaskRow({ state: this.state, item: item, ui: this.ui });
      }, (item: HabitRecord) => `${item.id}-${this.state.renderEpoch}`);
      if (this.state.libraryFilter === '回收站') {
        ForEach(this.state.actions.filter((item: ActionRecord) => item.deletedAt !== undefined), (item: ActionRecord) => {
          SelectionSurface({ state: this.state, refId: item.id, legacy: true }) {
            Row({ space: 10 }) {
              if (this.state.selectionPage) { SelectionMark({ state: this.state, refId: item.id, legacy: true }); }
              Column({ space: 6 }) {
                Text(item.text).fontSize(17).fontWeight(FontWeight.Bold).fontColor(PAPER);
                Text('旧行动记录').fontWeight(UI_BODY_WEIGHT).fontSize(11).fontColor(STEEL);
              }.layoutWeight(1).alignItems(HorizontalAlign.Start);
            }.width('100%').padding(16)
              .enabled(!this.state.mutationBusy).onClick(() => {
              if (this.state.selectionPage) { this.ui.batch.toggle({ id: item.id, action: true }); }
              else { this.ui.feedback.openAction(item.id, true); }
            });
          }
        }, (item: ActionRecord) => `${item.id}-${this.state.renderEpoch}`);
      }
    }.width('100%').alignItems(HorizontalAlign.Start).enabled(!this.state.mutationBusy);
  }
}
