import { UI_BODY_WEIGHT, UI_LABEL_STYLE } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { INK, PAPER, STEEL, RED } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutWord } from './CutWord';

@Component
export struct PageHeader {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  @Prop red: string;
  @Prop white: string;

  build() {
    Row() {
      cutLabel(this.red, this.white, 25);
      Blank().layoutWeight(1);
      CutButton({ label: '菜单', selected: false, action: () => this.ui.host.openWorkspace('menu') });
    }.width('100%').padding({ left: 18, right: 18, top: 20 });
  
  }
}

@Component
export struct LoadingNotice {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  build() {
    if (!this.state.dataReady || this.state.notice) {
      Column({ space: 8 }) {
        Text(this.state.notice || '正在载入数据…').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER);
        if (!this.state.dataReady && this.state.notice) { CutButton({ label: '重新载入', selected: true, action: () => this.ui.host.restoreState() }); }
      }.width('100%').padding(16).backgroundColor(RED);
    }
  
  }
}

@Component
export struct DataChoice {

  @Require ui: PageActions;
  @Prop title: string;
  @Prop subtitle: string = '';
  action: () => void = () => {};

  build() {
    Stack() {
      Image($r('app.media.pinned_choice')).width('100%').height('100%').objectFit(ImageFit.Fill);
      Column({ space: 9 }) {
        Text(this.title).fontSize(20).fontWeight(FontWeight.Bolder).fontColor(PAPER);
        if (this.subtitle) { Text(this.subtitle).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL).maxLines(2); }
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 28, right: 35 });
    }.width('100%').height(105).onClick(this.action);
  
  }
}

@Builder
export function cutLabel(first: string, second: string, size: number = 14) {
    Row({ space: 0 }) {
      CutWord({ label: first, labelSize: size, color: PAPER, plateColor: RED }).rotate({ angle: -5 });
      CutWord({ label: second, labelSize: size + 2 }).rotate({ angle: 4 })
        .margin({ left: -2 }).translate({ y: 3 });
    }
  }

@Component
export struct CutButton {
  @Prop label: string;
  @Prop selected: boolean;
  @Prop labelSize: number = 12;
  @Prop labelWeight: FontWeight = FontWeight.Bold;
  @Prop buttonHeight: number = 44;
  @Prop horizontalInset: number = 12;
  @Prop labelLines: number = 1;
  @Prop activeColor: string = PAPER;
  @Prop idleColor: string = '#292929';
  @Prop activeTextColor: string = INK;
  @Prop idleTextColor: string = PAPER;
  @Prop marginEnd: number = 8;
  @Prop marginBottom: number = 7;
  @Prop stretch: boolean = false;
  @State frameWidth: number = 0;
  action: () => void = () => {};

  private platePathCommands(): string {
    const w: number = this.getUIContext().vp2px(this.frameWidth);
    const h: number = this.getUIContext().vp2px(this.buttonHeight);
    const cut: number = Math.min(h * Math.tan(9 * Math.PI / 180), w / 4);
    return `M ${cut} 0 L ${w} 0 L ${w - cut} ${h} L 0 ${h} Z`;
  }

  @Builder
  private labelControl() {
    if (this.stretch) {
      Button(this.label, { type: ButtonType.Normal }).width('100%')
        .fontStyle(UI_LABEL_STYLE).fontSize(this.labelSize).fontWeight(this.labelWeight)
        .fontColor(this.selected ? this.activeTextColor : this.idleTextColor)
        .labelStyle({ maxLines: this.labelLines, minFontSize: this.labelSize - 1,
          maxFontSize: this.labelSize, overflow: TextOverflow.Ellipsis })
        .backgroundColor(this.frameWidth > 0 ? Color.Transparent : this.selected ? this.activeColor : this.idleColor)
        .borderRadius(0).height(this.buttonHeight).stateEffect(false)
        .padding({ left: this.horizontalInset, right: this.horizontalInset, top: 4, bottom: 4 })
        .onClick(this.action);
    } else {
      Button(this.label, { type: ButtonType.Normal })
        .fontStyle(UI_LABEL_STYLE).fontSize(this.labelSize).fontWeight(this.labelWeight)
        .fontColor(this.selected ? this.activeTextColor : this.idleTextColor)
        .labelStyle({ maxLines: this.labelLines, minFontSize: this.labelSize - 1,
          maxFontSize: this.labelSize, overflow: TextOverflow.Ellipsis })
        .backgroundColor(this.frameWidth > 0 ? Color.Transparent : this.selected ? this.activeColor : this.idleColor)
        .borderRadius(0).height(this.buttonHeight).stateEffect(false)
        .padding({ left: this.horizontalInset, right: this.horizontalInset, top: 4, bottom: 4 })
        .onClick(this.action);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // Keep paint below the native label in the normal, previewable component tree.
      Path().commands(this.platePathCommands()).width(this.frameWidth).height(this.buttonHeight)
        .fill(this.selected ? this.activeColor : this.idleColor).strokeWidth(0)
        .hitTestBehavior(HitTestMode.None);
      this.labelControl();
    }.height(this.buttonHeight)
      .margin({ right: this.marginEnd, bottom: this.marginBottom })
      .onAreaChange((_previous: Area, current: Area) => {
        const width: number = Number(current.width);
        if (width !== this.frameWidth) { this.frameWidth = width; }
      })
      .stateStyles({
        normal: { .scale({ x: 1, y: 1 }).animation({ duration: 100, curve: Curve.EaseOut }) },
        pressed: { .scale({ x: 0.96, y: 0.96 }).animation({ duration: 70, curve: Curve.Sharp }) }
      });
  }
}
