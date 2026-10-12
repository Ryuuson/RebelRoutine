import { UI_BODY_WEIGHT } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { INK, PAPER } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton, cutLabel } from '../components/CutWidgets';

@Component
export struct ConfirmDialog {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  build() {
    Stack() {
      Column({ space: 14 }) {
        cutLabel('确认', '操作', 23);
        Text(this.state.confirmText).width('100%').fontSize(15).fontWeight(FontWeight.Bold).fontColor(PAPER);
        if (this.state.notice) { Text(this.state.notice).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER); }
        Row() {
          CutButton({ label: '确认', selected: true, action: () => this.ui.data.confirmOperation() });
          CutButton({ label: '取消', selected: false, action: () => {
            this.state.pendingConfirm = ''; this.state.pendingBackup = undefined; this.state.pendingBatch = undefined;
          } });
        }
      }.width('88%').padding(24).backgroundColor(INK).border({ width: 3, color: PAPER }).rotate({ angle: -1 })
        .enabled(!this.state.mutationBusy);
    }.width('100%').height('100%').backgroundColor('#E5000000');
  
  }
}
