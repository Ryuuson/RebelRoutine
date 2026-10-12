import { PAPER } from '../common/Theme';
import { UI_LABEL_WEIGHT, UI_LABEL_STYLE } from '../common/Typography';

@Component
export struct EmptyState {
  @Prop message: string = '';
  @Prop inset: number = 18;

  build() {
    Text(this.message).fontSize(17).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE)
      .fontColor(PAPER).width('100%').maxLines(3).padding(this.inset);
  }
}
