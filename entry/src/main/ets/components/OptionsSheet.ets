import { UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { INK, PAPER, STEEL, RED } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton, cutLabel } from '../components/CutWidgets';
import { Composer } from './Composer';
import { TraitPicker } from './TraitPicker';
import { DateField } from './DateField';
import { CommissionLink } from './CommissionLink';
@Component
export struct OptionsSheet {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column().width('100%').height('100%').backgroundColor('#99000000').onClick(() => {
        if (!this.state.mutationBusy) { this.state.optionsOpen = false; }
      });
      Column({ space: 10 }) {
        Row() {
          cutLabel('行动', '选项', 18);
          Blank().layoutWeight(1);
          CutButton({ label: '完成设置', selected: true, action: () => { this.state.optionsOpen = false; this.ui.feedback.focusDraft(); } });
        }.width('100%');
        Composer({ state: this.state, inputId: 'routine-options-title', ui: this.ui })
        Scroll() {
          Column({ space: 12 }) {
            Row() {
              Text('已经做了').fontSize(16).fontWeight(FontWeight.Bold).fontColor(PAPER).layoutWeight(1);
              Toggle({ type: ToggleType.Switch, isOn: this.state.draftDone }).selectedColor(RED)
                .onChange((value: boolean) => { this.ui.draft.setQuickDone(value); });
            }.width('100%');
            DateField({ state: this.state, ui: this.ui, target: 'draft', done: this.state.draftDone });
            TextInput({ text: $$this.state.draftSubtitle, placeholder: '备注' }).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(13)).height(40).fontSize(13).placeholderColor(STEEL)
              .fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
            TraitPicker({ state: this.state, target: 'draft', ui: this.ui })
            CommissionLink({ state: this.state })
          }.width('100%').alignItems(HorizontalAlign.Start).padding({ bottom: 16 });
        }.width('100%').layoutWeight(1).align(Alignment.TopStart).scrollBar(BarState.Off);
      }.width('100%').height('76%').padding({ left: 18, right: 18, top: 16, bottom: 16 })
        .backgroundColor(INK).border({ width: { top: 3 }, color: PAPER }).enabled(!this.state.mutationBusy);
    }.width('100%').height('100%');
  }

}
