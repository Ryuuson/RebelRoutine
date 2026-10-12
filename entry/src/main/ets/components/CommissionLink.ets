import { UI_HINT_ON_INK } from '../common/Typography';
import { UI_BODY_WEIGHT, UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { Commission } from '../data/CommissionModel';
import { INK, PAPER, RED, STEEL } from '../common/Theme';
import { CutButton } from './CutWidgets';

@Component
export struct CommissionLink {
  @ObjectLink state: RoutineState;
  @Prop target: string = 'draft';
  private selected(): number {
    return this.target === 'edit' ? this.state.editCommissionId : this.target === 'repeat' ? this.state.repeatGoalId : this.state.draftCommissionId;
  }
  private select(id: number): void {
    if (this.target === 'edit') { this.state.editCommissionId = id; }
    else if (this.target === 'repeat') { this.state.repeatGoalId = id; }
    else { this.state.draftCommissionId = id; }
    if (this.state.m2?.goals.find((goal: Commission) => goal.id === id)?.mode === 'once') { this.change('1'); }
  }
  private value(): string {
    return this.target === 'edit' ? this.state.editProgressValue : this.target === 'repeat' ? this.state.repeatValue : this.state.draftProgressValue;
  }
  private change(value: string): void {
    if (this.target === 'edit') { this.state.editProgressValue = value; }
    else if (this.target === 'repeat') { this.state.repeatValue = value; }
    else { this.state.draftProgressValue = value; }
  }
  @Builder
  private choice(id: number, label: string) {
    CutButton({ label: label, selected: this.selected() === id, labelWeight: UI_BODY_WEIGHT,
      labelLines: 2, activeColor: RED, idleColor: INK, activeTextColor: PAPER, marginBottom: 8,
      action: () => this.select(id) }).constraintSize({ maxWidth: 240 });
  }
  build() {
    if (this.state.m2?.goals.some((goal: Commission) => goal.mode !== 'project')) {
      Column({ space: 6 }) {
        Text('关联委托').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL);
        Flex({ wrap: FlexWrap.Wrap }) {
          this.choice(-1,'独立行动');
          ForEach(this.state.m2?.goals.filter((goal: Commission) => goal.mode !== 'project') ?? [],
            (goal: Commission) => this.choice(goal.id,goal.title), (goal: Commission) => `${goal.id}-${this.state.renderEpoch}`);
        }.width('100%');
        if (this.selected() >= 0) {
          Row({ space: 8 }) {
            Text('计入进度').fontWeight(UI_BODY_WEIGHT).fontSize(13).fontColor(PAPER);
            TextInput({ text: this.value(), placeholder: '正数' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(14)).height(40).layoutWeight(1).fontSize(14).fontColor(PAPER)
              .backgroundColor('#242426').borderRadius(0).onChange((text: string) => this.change(text));
            Text(this.state.m2?.goals.find((goal: Commission) => goal.id === this.selected())?.unit ?? '').fontWeight(UI_BODY_WEIGHT).fontSize(13).fontColor(PAPER);
          }.width('100%');
        }
      }.width('100%').alignItems(HorizontalAlign.Start);
    }
  }
}
