import { INK, PAPER } from '../common/Theme';

// Display labels use a separate painted plate, never a shear on the glyphs.
@Component
export struct CutWord {
  @Prop label: string;
  @Prop labelSize: number = 14;
  @Prop labelStyle: FontStyle = FontStyle.Normal;
  @Prop color: string = INK;
  @Prop plateColor: string = PAPER;
  @Prop edgeColor: string = PAPER;
  @Prop edgeWidth: number = 0;
  @State frameWidth: number = 0;
  @State frameHeight: number = 0;

  private platePathCommands(): string {
    const inset: number = this.getUIContext().vp2px(this.edgeWidth / 2);
    const width: number = this.getUIContext().vp2px(this.frameWidth);
    const height: number = this.getUIContext().vp2px(this.frameHeight);
    const w: number = Math.max(0, width - inset);
    const h: number = Math.max(0, height - inset);
    const cut: number = Math.min(height * Math.tan(9 * Math.PI / 180), width / 4);
    return `M ${cut + inset} ${inset} L ${w} ${inset} L ${w - cut} ${h} L ${inset} ${h} Z`;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Path().commands(this.platePathCommands()).width(this.frameWidth).height(this.frameHeight)
        .fill(this.plateColor).stroke(this.edgeColor).strokeWidth(this.edgeWidth)
        .hitTestBehavior(HitTestMode.None);
      Text(this.label).fontSize(this.labelSize).fontWeight(FontWeight.Bolder)
        .fontStyle(this.labelStyle).fontColor(this.color)
        .padding({ left: 9, right: 10, top: 3, bottom: 3 })
        .backgroundColor(this.frameWidth > 0 && this.frameHeight > 0 ? Color.Transparent : this.plateColor)
        .onAreaChange((_previous: Area, current: Area) => {
          const width: number = Number(current.width);
          const height: number = Number(current.height);
          if (width !== this.frameWidth) { this.frameWidth = width; }
          if (height !== this.frameHeight) { this.frameHeight = height; }
        });
    }
  }
}
