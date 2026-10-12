import { UI_HINT_ON_INK } from '../common/Typography';
import { UI_BODY_WEIGHT, UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { TraitPoints } from '../data/RoutineStore';
import { TRAIT_DEFINITIONS, TraitDefinition } from '../data/TraitAnalyzer';
import { INK, PAPER, STEEL, RED } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton } from './CutWidgets';

@Component
export struct TraitPicker {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  @Prop target: string;
  @State adjustingGrowth: boolean = false;

  private selection(): string[] { return this.target === 'goal' ? this.state.goalTraits : this.target === 'repeat' ? this.state.repeatTraits :
    this.target === 'draft' ? this.state.draftTraits : this.target === 'pinned' ? this.state.pinnedEditTraits : this.state.editTraits; }
  private points(): TraitPoints[] { return this.target === 'goal' ? this.state.goalPoints : this.target === 'repeat' ? this.state.repeatPoints :
    this.target === 'draft' ? this.state.draftPoints : this.target === 'pinned' ? this.state.pinnedEditPoints : this.state.editPoints; }
  private choose(key: string): void { this.ui.draft.chooseTrait(this.target, key, this.selection()); }
  private setPoints(key: string, text: string): void { this.ui.draft.setPoints(this.target, key, text); }
  @Builder
  private traitChoice(key: string, label: string) {
    CutButton({ label: label, selected: key === 'none' ? this.selection().length === 0 : this.selection().includes(key),
      buttonHeight: 32, activeColor: RED, idleColor: INK, activeTextColor: PAPER,
      marginEnd: 7, marginBottom: 6, action: () => this.choose(key) });
  
  }
  build() {
    Column({ space: 5 }) {
      Text('成长维度').fontWeight(UI_BODY_WEIGHT).fontSize(11).fontColor(STEEL);
      Flex({ wrap: FlexWrap.Wrap }) {
        if (this.target !== 'goal') { this.traitChoice( 'auto', '自动'); }
        ForEach(TRAIT_DEFINITIONS, (trait: TraitDefinition) => {
          this.traitChoice( trait.key, trait.label);
        }, (trait: TraitDefinition) => trait.key);
        this.traitChoice( 'none', '不影响成长');
      }.width('100%');
      if (this.selection().some((key: string) => key !== 'auto')) {
        Text(this.adjustingGrowth ? '收起调整' : '调整成长').fontWeight(UI_BODY_WEIGHT).fontSize(11).fontColor(STEEL).padding({ top: 4, bottom: 8 })
          .onClick(() => this.adjustingGrowth = !this.adjustingGrowth);
      }
      if (this.adjustingGrowth) {
        ForEach(this.selection().filter((key: string) => key !== 'auto'), (key: string) => {
        Row({ space: 8 }) {
          Text(this.ui.queries.traitLabel(key)).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER).layoutWeight(1);
          Text('成长幅度').fontWeight(UI_BODY_WEIGHT).fontSize(11).fontColor(STEEL);
          TextInput({ text: `${this.ui.queries.pointAmount(this.points(), key)}` }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(14))
            .type(InputType.Number).width(68).height(34).fontSize(14).fontColor(PAPER)
            .backgroundColor('#242426').borderRadius(0)
            .onChange((text: string) => this.setPoints(key, text));
        }.width('100%').height(37);
        }, (key: string) => key);
      }
    }.width('100%').alignItems(HorizontalAlign.Start);
  
  }
}
