import { UI_HINT_ON_INK } from '../common/Typography';
import { UI_BODY_WEIGHT, UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { CommissionStage } from '../data/CommissionModel';
import { TraitPoints } from '../data/RoutineModel';
import { TRAIT_DEFINITIONS, TraitDefinition } from '../data/TraitAnalyzer';
import { PAPER, INK, STEEL, RED } from '../common/Theme';
import { CommissionChoice } from './CommissionChoices';

@Component
export struct CommissionStageEditor {
  @ObjectLink state: RoutineState;
  @Prop stageId: number;
  @State rewardsOpen: boolean = false;
  private stage(): CommissionStage {
    return this.state.goalStages.find((stage: CommissionStage) => stage.id === this.stageId) ??
      { id: this.stageId, title: '', percent: 50, keys: [], points: [] };
  }
  private update(stage: CommissionStage): void {
    this.state.goalStages = this.state.goalStages.map((item: CommissionStage) => item.id === stage.id ? stage : item);
  }
  private copy(): CommissionStage { return JSON.parse(JSON.stringify(this.stage())) as CommissionStage; }
  private title(text: string): void { const stage: CommissionStage = this.copy(); stage.title = text; this.update(stage); }
  private percent(text: string): void { const stage: CommissionStage = this.copy(); stage.percent = Number(text); this.update(stage); }
  private choose(key: string): void {
    const stage: CommissionStage = this.stage();
    const keys: string[] = stage.keys.includes(key) ? stage.keys.filter((item: string) => item !== key) : [...stage.keys,key];
    const next: CommissionStage = this.copy(); next.keys = keys;
    next.points = keys.map((item: string): TraitPoints => ({ key: item,
      points: stage.points.find((point: TraitPoints) => point.key === item)?.points ?? 1 })); this.update(next);
  }
  build() {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        TextInput({ text: this.stage().title, placeholder: '阶段名称' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(13)).height(40).layoutWeight(1).fontSize(13)
          .fontColor(PAPER).backgroundColor('#242426').borderRadius(0).onChange((text: string) => this.title(text));
        TextInput({ text: `${this.stage().percent}` }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(13)).height(40).width(54).fontSize(13).fontColor(PAPER)
          .backgroundColor('#242426').borderRadius(0).onChange((text: string) => this.percent(text));
        Text('%').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER);
        Text('移除').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER).padding(6).backgroundColor(INK).onClick(() => {
          this.state.goalStages = this.state.goalStages.filter((item: CommissionStage) => item.id !== this.stageId);
        });
      }.width('100%');
      Text(this.rewardsOpen ? '收起阶段成长' : '设置阶段成长').fontWeight(UI_BODY_WEIGHT).fontSize(11).fontColor(STEEL).padding(6)
        .onClick(() => this.rewardsOpen = !this.rewardsOpen);
      if (this.rewardsOpen) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(TRAIT_DEFINITIONS, (trait: TraitDefinition) => {
            CommissionChoice({ label: trait.label, selected: this.stage().keys.includes(trait.key), action: () => this.choose(trait.key) });
          }, (trait: TraitDefinition) => trait.key);
        }.width('100%');
        ForEach(this.stage().points, (point: TraitPoints) => {
          Row({ space: 8 }) {
            Text(`${TRAIT_DEFINITIONS.find((trait: TraitDefinition) => trait.key === point.key)?.label ?? point.key}成长`).fontWeight(UI_BODY_WEIGHT)
              .fontSize(11).fontColor(STEEL);
            TextInput({ text: `${point.points}` }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(13)).height(36).width(68).fontSize(13).fontColor(PAPER)
              .backgroundColor('#242426').borderRadius(0).type(InputType.Number).onChange((text: string) => {
                const stage: CommissionStage = this.stage();
                const next: CommissionStage = this.copy();
                next.points = stage.points.map((value: TraitPoints): TraitPoints => value.key === point.key ?
                  { key: value.key, points: Number(text) } : value); this.update(next);
              });
          }.width('100%');
        }, (point: TraitPoints) => point.key);
      }
    }.width('100%').alignItems(HorizontalAlign.Start).padding(8).backgroundColor('#202020');
  }
}
