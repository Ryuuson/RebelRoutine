import { UI_LABEL_STYLE } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { RoutineHost } from '../common/RoutineHost';
import { MorganaEvent } from '../data/MorganaFeedback';
import { FOCUS_SECONDS, SEGMENT_COUNT, INK, PAPER, RED } from '../common/Theme';
import { PageActions } from '../common/PageActions';

export interface FocusViewBindings {
  state: RoutineState;
  ui: PageActions;
}

@Builder
export function FocusView($$: FocusViewBindings) {
            Text('专注计时').fontSize(18).fontWeight(FontWeight.Bold).fontColor(PAPER);
          Column() {
            Row() {
              Text($$.ui.focus.formattedTime($$.state.remainingSeconds)).fontSize(58).fontWeight(FontWeight.Bolder).fontColor(PAPER).shadow({
                radius: 0, color: RED, offsetX: 4, offsetY: 4 });
              Blank().layoutWeight(1);
            }
            .width('100%');
            Row({ space: 3 }) {
              ForEach(Array.from({ length: SEGMENT_COUNT }, (_value: undefined, index: number) => index), (index: number) => {
                Column().layoutWeight(1).height(10).backgroundColor($$.ui.focus.segmentFilled(index, $$.state.remainingSeconds) ? RED : '#1E1E1E');
              });
            }
            .width('100%')
            .height(13)
            .border({ width: 2, color: PAPER });
            Row({ space: 9 }) {
              Button($$.state.isFocusing ? '暂停专注' : '开始专注').fontStyle(UI_LABEL_STYLE)
                .layoutWeight(1)
                .height(42)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(INK)
                .backgroundColor(PAPER)
                .borderRadius(0)
                .onClick(() => $$.ui.focus.toggleFocus());
              Button('重置').fontStyle(UI_LABEL_STYLE)
                .layoutWeight(1)
                .height(42)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(PAPER)
                .backgroundColor(INK)
                .border({ width: 2, color: PAPER })
                .borderRadius(0)
                .onClick(() => $$.ui.focus.resetFocus());
            }
            .width('100%')
            .margin({ top: 13 });
          }
          .width('100%')
          .padding({ left: 18, right: 18 });


          
}



export class FocusClock {
  private timerId: number = -1;
  private readonly host: RoutineHost;
  private readonly ui: PageActions;
  constructor(host: RoutineHost, ui: PageActions) { this.host = host; this.ui = ui; }
  toggleFocus(): void {
    this.host.refreshToday();
    if (this.host.state.isFocusing) {
      this.stopTimer();
      return;
    }
    if (this.host.state.remainingSeconds === 0) {
      this.host.state.remainingSeconds = FOCUS_SECONDS;
    }
    this.host.state.isFocusing = true;
    this.timerId = setInterval(() => this.tick(), 1000);
  }

  resetFocus(): void {
    this.stopTimer();
    this.host.state.remainingSeconds = FOCUS_SECONDS;
  }

  tick(): void {
    if (this.host.state.remainingSeconds <= 1) {
      this.host.state.remainingSeconds = 0;
      this.stopTimer();
      this.ui.dialogue.queueFeedback(MorganaEvent.Focus);
      return;
    }
    this.host.state.remainingSeconds -= 1;
  }

  stopTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.host.state.isFocusing = false;
  }

  formattedTime(remaining: number = this.host.state.remainingSeconds): string {
    const minutes = Math.floor(remaining / 60);
    const seconds = remaining % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  segmentFilled(index: number, remaining: number = this.host.state.remainingSeconds): boolean {
    const progress = 1 - remaining / FOCUS_SECONDS;
    return index < Math.round(progress * SEGMENT_COUNT);
  }
}
