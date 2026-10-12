import { UI_BODY_WEIGHT } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { HabitRecord } from '../data/RoutineStore';
import { PAPER, STEEL } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { RewardTags } from './RewardTags';
import { SelectionMark, SelectionSurface } from './SelectionControls';
@Component
export struct TaskRow {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  @Prop item: HabitRecord;
  @Prop todayStyle: boolean = false;
  build() {
    SelectionSurface({ state: this.state, refId: this.item.id }) {
      Row({ space: 10 }) {
        if (this.state.selectionPage) {
          SelectionMark({ state: this.state, refId: this.item.id });
        }
        Column({ space: 4 }) {
          Text(this.item.title).width('100%').fontSize(this.todayStyle ? 17 : 15).fontWeight(FontWeight.Bold)
            .fontColor(this.item.done && !this.state.selectionPage ? STEEL : PAPER)
            .decoration({ type: this.item.done ? TextDecorationType.LineThrough : TextDecorationType.None });
          if (this.item.subtitle) { Text(this.item.subtitle).fontWeight(UI_BODY_WEIGHT).fontSize(11)
            .fontColor(this.state.selectionPage && this.state.selectedRefs.some((ref) => ref.id === this.item.id && !ref.action) ? PAPER : STEEL); }
        }.layoutWeight(1).alignItems(HorizontalAlign.Start);
        if (this.item.done) {
          RewardTags({ keys: this.item.awardedTraits ?? [], points: this.item.awardedPoints ?? [], ui: this.ui }).width('33%');
        }
      }.width('100%').constraintSize({ minHeight: this.todayStyle ? 54 : 50 })
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .enabled(!this.state.mutationBusy)
        .onClick(() => { if (this.state.selectionPage) { this.ui.batch.toggle({ id: this.item.id, action: false }); }
          else if (this.todayStyle && (!this.item.done || this.ui.queries.canUndo(this.item))) {
          this.ui.lifecycle.toggleHabit(this.item.id); } else { this.ui.feedback.openAction(this.item.id); } })
        .gesture(LongPressGesture({ repeat: false }).onAction(() => {
          if (this.state.selectionPage) { return; }
          if (this.ui.queries.canOperate(this.item, 'edit')) { this.ui.feedback.openAction(this.item.id); this.ui.lifecycle.sheetOperation('edit'); }
          else { this.ui.feedback.openAction(this.item.id); }
        }));
    }
  }

}
