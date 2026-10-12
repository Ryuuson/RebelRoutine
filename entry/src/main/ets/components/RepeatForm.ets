import { UI_HINT_ON_INK } from '../common/Typography';
import { UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { PAPER, STEEL } from '../common/Theme';
import { TraitPicker } from './TraitPicker';
import { CommissionChoice } from './CommissionChoices';
import { CommissionLink } from './CommissionLink';
import { DateField } from './DateField';

@Component
export struct RepeatForm {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Column({ space: 12 }) {
      TextInput({ text: $$this.state.repeatTitle, placeholder: '重复事项名称' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(16)).height(44).fontSize(16).fontColor(PAPER)
        .backgroundColor('#242426').borderRadius(0);
      TextInput({ text: $$this.state.repeatSubtitle, placeholder: '备注' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(13)).height(40).fontSize(13).fontColor(PAPER)
        .backgroundColor('#242426').borderRadius(0);
      Row() {
        CommissionChoice({ label: '每天', selected: this.state.repeatRule === 'daily', action: () => this.state.repeatRule = 'daily' });
        CommissionChoice({ label: '每周指定日', selected: this.state.repeatRule === 'weekly', action: () => this.state.repeatRule = 'weekly' });
      }.width('100%');
      if (this.state.repeatRule === 'weekly') {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([1,2,3,4,5,6,0], (day: number) => {
            CommissionChoice({ label: ['日','一','二','三','四','五','六'][day], selected: this.state.repeatDays.includes(day), action: () => {
              this.state.repeatDays = this.state.repeatDays.includes(day) ? this.state.repeatDays.filter((value: number) => value !== day) :
                [...this.state.repeatDays,day];
            } });
          }, (day: number) => `${day}`);
        }.width('100%');
      }
      DateField({ state: this.state, ui: this.ui, target: 'repeat' });
      CommissionLink({ state: this.state, target: 'repeat' });
      TraitPicker({ state: this.state, target: 'repeat', ui: this.ui });
    }.width('100%').alignItems(HorizontalAlign.Start);
  }
}
