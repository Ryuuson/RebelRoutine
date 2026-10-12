@Component
export struct CutSurface {
  @Prop kind: string = 'mission';
  @State frameWidth: number = 0;
  @State frameHeight: number = 0;
  @BuilderParam content: () => void;
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image(this.kind === 'journal' ? $r('app.media.journal_paper') : this.kind === 'stat' ?
        $r('app.media.stat_silhouette') : $r('app.media.mission_sheet'))
        .width(this.frameWidth).height(this.frameHeight).objectFit(ImageFit.Fill);
      Column() {
        this.content();
      }.width('100%').onAreaChange((_previous: Area, current: Area) => {
        this.frameWidth = Number(current.width); this.frameHeight = Number(current.height);
      });
    }.width('100%');
  }
}
