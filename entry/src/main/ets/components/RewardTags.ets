import { TraitPoints } from '../data/RoutineStore';
import { INK, PAPER, RED, SHEAR } from '../common/Theme';
import { PageActions } from '../common/PageActions';

@Component
export struct RewardTags {

  @Require ui: PageActions;

  @Prop keys: string[] = [];
  @Prop points: TraitPoints[] = [];
  @Prop onPaper: boolean = false;
  @Prop selected: boolean = false;
  build() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.keys, (key: string) => {
        Text(this.ui.queries.traitLabel(key)).fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(this.selected ? PAPER : this.onPaper ? RED : PAPER).backgroundColor(this.onPaper ? Color.Transparent : INK)
          .padding({ left: 5, right: 5, top: 2, bottom: 2 })
          .transform(SHEAR).margin({ right: 7, bottom: 4 });
      }, (key: string) => key);
    }
  }

}
