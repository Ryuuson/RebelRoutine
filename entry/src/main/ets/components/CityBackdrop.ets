import { RoutineState } from '../common/RoutineState';

@Component
export struct CityBackdrop {
  @ObjectLink state: RoutineState;
  @State viewportWidth: number = 0;
  @State viewportHeight: number = 0;

  private windowWidth(): number { return this.state.windowSize.width || this.viewportWidth; }
  private windowHeight(): number { return this.state.windowSize.height || this.viewportHeight; }

  private panoramaWidth(): number {
    // Four equal horizontal regions of the original 2730 × 1536 city.
    return Math.max(this.windowWidth() * 4, this.windowHeight() * 2730 / 1536);
  }

  private region(): number {
    return this.state.mainPage === '今日' ? 0 : this.state.mainPage === '任务' ? 1 : this.state.mainPage === '记录' ? 2 : 3;
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($r('app.media.bg_city')).width(this.panoramaWidth()).height(this.panoramaWidth() * 1536 / 2730)
        .objectFit(ImageFit.Fill).position({
          left: this.windowWidth() / 2 - this.panoramaWidth() * (this.region() + 0.5) / 4,
          top: (this.windowHeight() - this.panoramaWidth() * 1536 / 2730) / 2
        });
      Column().width('100%').height('100%').backgroundColor('#59000000');
    }.width(this.state.windowSize.width || '100%').height(this.state.windowSize.height || '100%')
      .align(Alignment.TopStart).clip(true).onAreaChange((_previous: Area, current: Area) => {
      this.viewportWidth = Number(current.width); this.viewportHeight = Number(current.height);
    });
  }
}
