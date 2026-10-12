import { UI_BODY_WEIGHT } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { offsetDay } from '../common/DayUtil';
import { PAPER, STEEL } from '../common/Theme';
import { CutButton } from './CutWidgets';
import { NativeDatePicker } from '../common/NativeDatePicker';

/** Shared date draft; choosing a date never writes data. */
@Component
export struct DateField {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  @Prop target: string = 'draft';
  @Prop done: boolean = false;

  private value(): string {
    if (this.target === 'draft') { return this.state.draftDay === '-' ? '' : this.state.draftDay || this.state.today; }
    if (this.target === 'batch') { return this.state.batchDay; }
    if (this.target === 'deadline') { return this.state.goalDeadline; }
    if (this.target === 'progress') { return this.state.progressDay; }
    if (this.target === 'repeat') { return this.state.repeatStart; }
    return this.done ? this.state.editActivityDay : this.state.editDay;
  }
  private set(value: string): void {
    this.ui.draft.setDate(this.target, this.done, value);
  }
  private choose(offset: number): void { this.ui.draft.chooseDate(this.target, this.done, offset); }
  private pick(): void { NativeDatePicker.open(this.ui, this.target, this.done, this.value()); }
  build() {
    Column({ space: 10 }) {
      Text(this.target === 'deadline' ? '截止日期' : this.target === 'repeat' ? '开始日期' :
        this.done ? '实际完成日期' : '安排日期').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL);
      Flex({ wrap: FlexWrap.Wrap }) {
        CutButton({ label: '今天', selected: this.value() === this.state.today, action: () => this.choose(0) });
        CutButton({ label: this.done ? '昨天' : '明天', selected: this.value() === offsetDay(this.state.today, this.done ? -1 : 1),
          action: () => this.choose(this.done ? -1 : 1) });
        if (this.done && this.target === 'draft') {
          CutButton({ label: '前天', selected: this.value() === offsetDay(this.state.today, -2), action: () => this.choose(-2) });
        }
        if (!this.done && this.target !== 'repeat') {
          CutButton({ label: this.target === 'deadline' ? '无截止日期' : '不安排', selected: !this.value(),
            action: () => this.set('') });
        }
        CutButton({ label: '选日期', selected: false, action: () => this.pick() });
      }.width('100%');
      Text(this.value() || (this.target === 'deadline' ? '无截止日期' : '不安排')).fontWeight(UI_BODY_WEIGHT).fontSize(14).fontColor(PAPER)
        .onClick(() => this.pick());
    }.width('100%').alignItems(HorizontalAlign.Start);
  }
}
