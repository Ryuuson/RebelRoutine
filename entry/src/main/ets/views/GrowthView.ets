import { RoutineState } from '../common/RoutineState';
import { TRAIT_DEFINITIONS, TraitDefinition } from '../data/TraitAnalyzer';
import { INK, PAPER, STEEL, YELLOW } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton } from '../components/CutWidgets';
import { ScreenIdentity } from '../components/ScreenIdentity';
import { LoadingNotice } from '../components/CutWidgets';
import { CutWord } from '../components/CutWord';

@Component
export struct GrowthView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  build() {
    Scroll(this.ui.host.growthScroller) {
      Column({ space: 20 }) {
        Row({ space: 8 }) {
          ScreenIdentity({ kind: 'stat' }).layoutWeight(1);
          CutButton({ label: '菜单', selected: false, action: () => this.ui.host.openWorkspace('menu') });
        }.width('100%').padding({ left: 18, right: 18, top: 20 });
        LoadingNotice({ state: this.state, ui: this.ui });
          Column() {
            Column({ space: 12 }) {
              ForEach(TRAIT_DEFINITIONS, (trait: TraitDefinition) => {
                  Row({ space: 15 }) {
                    Image(this.ui.queries.traitIcon(trait)).width(82).height(36).objectFit(ImageFit.Contain);
                    Column({ space: 8 }) {
                      Row({ space: 2 }) {
                        CutWord({ label: trait.label.slice(0, 1), labelSize: 23, color: YELLOW,
                          plateColor: INK, edgeColor: YELLOW, edgeWidth: 2 }).rotate({ angle: -4 });
                        CutWord({ label: trait.label.slice(1), labelSize: 22, plateColor: YELLOW })
                          .margin({ left: -3 }).rotate({ angle: 3 });
                        CutWord({ label: `${this.ui.queries.traitRank(trait.key, this.state.traitTotals)}`,
                          labelSize: 18, plateColor: YELLOW }).rotate({ angle: 5 }).translate({ y: 4 });
                      }
                      Text(this.ui.queries.rankName(trait.key, this.state.traitTotals)).fontSize(16).fontWeight(FontWeight.Bolder)
                        .fontStyle(FontStyle.Italic).fontColor(PAPER).backgroundColor(INK)
                        .padding({ left: 8, right: 10, top: 3, bottom: 3 }).rotate({ angle: -3 });
                    }
                    .alignItems(HorizontalAlign.Start).layoutWeight(1);
                  }
                  .width('100%').height(82).padding({ left: 8 }).enabled(!this.state.mutationBusy)
                    .onClick(() => this.ui.feedback.jumpToTrait(trait.key));
              }, (trait: TraitDefinition) => `${trait.key}-${this.state.renderEpoch}`);
            }
            .width('100%').margin({ top: 8 });
          }
          .width('100%')
          .padding({ left: 18, right: 18 });
      }.width('100%').padding({ bottom: 24 });
    }.width('100%').height('100%').align(Alignment.TopStart).scrollBar(BarState.Off);
  
  }
}
