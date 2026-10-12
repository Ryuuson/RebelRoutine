import { UI_HINT_ON_INK } from '../common/Typography';
import { UI_BODY_WEIGHT, UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { PAPER, STEEL, RED } from '../common/Theme';
import { TraitPicker } from './TraitPicker';
import { CommissionChoice } from './CommissionChoices';
import { CommissionStageEditor } from './CommissionStageEditor';
import { CutButton } from './CutWidgets';
import { CommissionStage } from '../data/CommissionModel';
import { DateField } from './DateField';

@Component
export struct CommissionForm {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Column({ space: 12 }) {
      TextInput({ text: $$this.state.goalTitle, placeholder: '委托名称' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(16)).height(44).fontSize(16).fontColor(PAPER)
        .backgroundColor('#242426').borderRadius(0);
      Text('进度类型').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL);
      Flex({ wrap: FlexWrap.Wrap }) {
        CommissionChoice({ label: '一次完成', selected: this.state.goalMode === 'once', action: () => this.state.goalMode = 'once' });
        CommissionChoice({ label: '累计次数', selected: this.state.goalMode === 'count', action: () => this.state.goalMode = 'count' });
        CommissionChoice({ label: '数量 / 时长', selected: this.state.goalMode === 'quantity', action: () => this.state.goalMode = 'quantity' });
        if (this.state.goalParentId < 0) {
          CommissionChoice({ label: '分子任务推进', selected: this.state.goalMode === 'project', action: () => {
            this.state.goalMode = 'project'; this.state.goalWeekly = false; this.state.goalRewardMode = 'target';
          } });
        }
      }.width('100%');
      if (this.state.goalMode === 'count' || this.state.goalMode === 'quantity') {
        Row({ space: 8 }) {
          TextInput({ text: $$this.state.goalTarget, placeholder: '目标数量' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(14)).height(44).layoutWeight(1).fontSize(14)
            .fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
          if (this.state.goalMode === 'quantity') {
            TextInput({ text: $$this.state.goalUnit, placeholder: '单位' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(14)).height(44).width(88).fontSize(14)
              .fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
          } else { Text('次').fontWeight(UI_BODY_WEIGHT).fontSize(14).fontColor(PAPER); }
        }.width('100%');
      }
      if (this.state.goalParentId < 0 && this.state.goalMode !== 'project') {
        Row() {
          Text('每周重新累计').fontWeight(UI_BODY_WEIGHT).fontSize(14).fontColor(PAPER).layoutWeight(1);
          Toggle({ type: ToggleType.Switch, isOn: this.state.goalWeekly }).selectedColor(RED)
            .onChange((value: boolean) => this.state.goalWeekly = value);
        }.width('100%');
      }
      DateField({ state: this.state, ui: this.ui, target: 'deadline' });
      Text('成长方式').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL);
      Flex({ wrap: FlexWrap.Wrap }) {
        CommissionChoice({ label: '达成时', selected: this.state.goalRewardMode === 'target', action: () => this.state.goalRewardMode = 'target' });
        if (this.state.goalMode !== 'project') {
          CommissionChoice({ label: '每次记录', selected: this.state.goalRewardMode === 'entry', action: () => this.state.goalRewardMode = 'entry' });
        }
      }.width('100%');
      TraitPicker({ state: this.state, target: 'goal', ui: this.ui });
      Row() {
        Text('阶段节点').fontSize(14).fontWeight(FontWeight.Bold).fontColor(PAPER).layoutWeight(1);
        CutButton({ label: '增加阶段', selected: false, action: () => {
          const id: number = this.state.goalStages.reduce((value: number, stage: CommissionStage) => Math.max(value,stage.id+1),Date.now());
          this.state.goalStages = [...this.state.goalStages,{ id, title: '阶段达成', percent: 50, keys: [], points: [] }];
        } });
      }.width('100%');
      ForEach(this.state.goalStages, (stage: CommissionStage) => {
        CommissionStageEditor({ state: this.state, stageId: stage.id });
      }, (stage: CommissionStage) => `${stage.id}`);
    }.width('100%').alignItems(HorizontalAlign.Start);
  }
}
