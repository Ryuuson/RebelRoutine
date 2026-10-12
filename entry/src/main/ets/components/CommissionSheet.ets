import { UI_HINT_ON_INK } from '../common/Typography';
import { UI_BODY_WEIGHT, UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { INK, PAPER, STEEL } from '../common/Theme';
import { CutButton, cutLabel } from './CutWidgets';
import { CommissionForm } from './CommissionForm';
import { RepeatForm } from './RepeatForm';
import { DateField } from './DateField';

@Component
export struct CommissionSheet {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  private close(): void {
    if (!this.state.mutationBusy) { this.state.goalEditing = false; this.state.repeatEditing = false; this.state.progressOpen = false; }
  }
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column().width('100%').height('100%').backgroundColor('#99000000').onClick(() => this.close());
      Column({ space: 12 }) {
        Row() {
          cutLabel(this.state.repeatEditing ? '重复' : '委托',this.state.progressOpen ? '进度' : '设置',20);
          Blank().layoutWeight(1);
          CutButton({ label: '关闭', selected: false, action: () => this.close() });
        }.width('100%');
        Scroll() {
          Column({ space: 12 }) {
            if (this.state.goalEditing) { CommissionForm({ state: this.state, ui: this.ui }); }
            else if (this.state.repeatEditing) { RepeatForm({ state: this.state, ui: this.ui }); }
            else {
              Text(this.state.m2?.goals.find((goal) => goal.id === this.state.commissionId)?.title ?? '').fontSize(18)
                .fontWeight(FontWeight.Bold).fontColor(PAPER);
              Row({ space: 8 }) {
                TextInput({ text: $$this.state.progressValue, placeholder: '本次进度' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(15)).height(44).fontSize(15)
                  .layoutWeight(1).fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
                Text(this.state.m2?.goals.find((goal) => goal.id === this.state.commissionId)?.unit ?? '').fontWeight(UI_BODY_WEIGHT).fontSize(14).fontColor(PAPER);
              }.width('100%');
              DateField({ state: this.state, ui: this.ui, target: 'progress', done: true });
              TextInput({ text: $$this.state.progressNote, placeholder: '这次做了什么' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(13)).height(44).fontSize(13)
                .fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
            }
          }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 6, right: 6, bottom: 16 });
        }.width('100%').layoutWeight(1).align(Alignment.TopStart).scrollBar(BarState.Off);
        if (this.state.notice) { Text(this.state.notice).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER); }
        CutButton({ label: this.state.progressOpen ? '保存进度' : '保存设置', selected: true, action: () => {
          if (this.state.goalEditing) { this.ui.commissions.save(); }
          else if (this.state.repeatEditing) { this.ui.commissions.saveRepeat(); }
          else { this.ui.commissions.saveProgress(); }
        } });
      }.width('100%').height(this.state.keyboardVisible ? '100%' : '86%').padding(18).backgroundColor(INK)
        .border({ width: { top: 3 }, color: PAPER }).enabled(!this.state.mutationBusy);
    }.width('100%').height('100%');
  }
}
