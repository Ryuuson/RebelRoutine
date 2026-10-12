import { UI_BODY_WEIGHT } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { INK, PAPER, STEEL } from '../common/Theme';
import { CutButton, cutLabel } from './CutWidgets';
import { DateField } from './DateField';

@Component
export struct BatchEditSheet {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column().width('100%').height('100%').backgroundColor('#99000000').onClick(() => {
        if (!this.state.mutationBusy) { this.state.batchEditing = false; }
      });
      Column({ space: 16 }) {
        Row() {
          cutLabel('批量', '编辑', 20);
          Blank().layoutWeight(1);
          CutButton({ label: '关闭', selected: false, action: () => this.state.batchEditing = false });
        }.width('100%');
        Text(`修改 ${this.state.selectedRefs.length} 条的日期`).fontSize(16).fontWeight(FontWeight.Bold).fontColor(PAPER);
        DateField({ state: this.state, ui: this.ui, target: 'batch', done: this.state.selectionPage === '记录' });
        if (this.state.notice) { Text(this.state.notice).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER); }
        CutButton({ label: '保存修改', selected: true, action: () => this.ui.batch.request('date') });
      }.width('100%').padding({ left: 26, right: 26, top: 20, bottom: 24 }).backgroundColor(INK)
        .border({ width: { top: 3 }, color: PAPER }).alignItems(HorizontalAlign.Start).enabled(!this.state.mutationBusy);
    }.width('100%').height('100%');
  }
}
