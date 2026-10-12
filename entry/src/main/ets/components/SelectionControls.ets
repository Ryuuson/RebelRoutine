import { UI_BODY_WEIGHT } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { INK, PAPER, STEEL, RED, SHEAR } from '../common/Theme';
import { CutButton } from './CutWidgets';

@Component
export struct SelectionMark {
  @ObjectLink state: RoutineState;
  @Prop refId: number;
  @Prop legacy: boolean = false;
  @Prop onPaper: boolean = false;
  build() {
    Row() {
      Text(this.state.selectedRefs.some((ref) => ref.id === this.refId && ref.action === this.legacy) ? '◆' : '◇')
        .fontSize(17).fontWeight(FontWeight.Bolder)
        .fontColor(this.onPaper && !this.state.selectedRefs.some((ref) => ref.id === this.refId && ref.action === this.legacy) ? INK : PAPER);
    }.width(20).height(24).justifyContent(FlexAlign.Center);
  }
}

@Component
export struct SelectionSurface {
  @ObjectLink state: RoutineState;
  @Prop refId: number;
  @Prop legacy: boolean = false;
  @State frameWidth: number = 0;
  @State frameHeight: number = 0;
  @BuilderParam content: () => void;
  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.state.selectionPage && this.state.selectedRefs.some((ref) => ref.id === this.refId && ref.action === this.legacy)) {
        Row().width(Math.max(0, this.frameWidth - 12)).height(this.frameHeight).backgroundColor(RED).transform(SHEAR);
      }
      this.content();
    }.width('100%').onAreaChange((_previous: Area, current: Area) => {
      this.frameWidth = Number(current.width); this.frameHeight = Number(current.height);
    });
  }
}

@Component
export struct SelectionControls {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  @Prop page: string = '任务';
  build() {
    Row({ space: 8 }) {
      if (this.state.selectionPage === this.page) {
        Text(`已选 ${this.state.selectedRefs.length}`).fontWeight(UI_BODY_WEIGHT).layoutWeight(1).fontSize(12).fontColor(PAPER);
        CutButton({ label: '全选当前', selected: false, action: () => this.ui.batch.selectAll() });
        CutButton({ label: '清空', selected: false, action: () => this.ui.batch.clear() });
      } else {
        Blank().layoutWeight(1);
        CutButton({ label: '管理', selected: false, action: () => this.ui.batch.enter(this.page) });
      }
    }.width('100%').padding({ left: 8, right: 4 }).backgroundColor('#DB000000').enabled(!this.state.mutationBusy);
  }
}
