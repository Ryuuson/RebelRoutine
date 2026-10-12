import { RoutineState } from '../common/RoutineState';
import { RoutineHost } from '../common/RoutineHost';
import { TraitPoints } from '../data/RoutineStore';
import { MorganaEvent, MorganaFeedback, TraitDelta } from '../data/MorganaFeedback';
import { INK, PAPER, YELLOW, SHEAR } from '../common/Theme';
import { PageActions } from '../common/PageActions';

@Component
export struct MorganaBubble {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($r('app.media.box_medium'))
        .width('100%').height('100%').objectFit(ImageFit.Fill);
      Row({ space: 0 }) {
        Text('摩').fontSize(10).fontWeight(FontWeight.Bolder).fontColor(INK);
        Text('尔').fontSize(10).fontWeight(FontWeight.Bolder).fontColor(PAPER)
          .backgroundColor(INK).padding({ left: 1, right: 1, top: 1, bottom: 1 });
        Text('加纳').fontSize(10).fontWeight(FontWeight.Bolder).fontColor(INK);
      }
      .width(54).height(14).justifyContent(FlexAlign.Center)
      .position({ x: '25.2%', y: '25.1%' })
      .markAnchor({ x: '50%', y: '50%' })
      // Follow the white plate's centre line after the 950x266 asset is resized.
      .rotate({ angle: Math.atan2(-68.5 * 120 / 266, 277.5 * this.state.dialogFrameWidth / 950) * 180 / Math.PI });
      Text(this.state.dialogText)
        .fontSize(15).lineHeight(19).fontWeight(FontWeight.Bold).fontColor(PAPER)
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('60%').height('36%')
        .position({ x: '18%', y: '43%' });
    }
    .width('100%').height(120)
    .onAreaChange((_old: Area, now: Area) => { this.state.dialogFrameWidth = Number(now.width); });
  
  }
}

@Component
export struct MorganaScene {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Image($r('app.media.portrait_morgana')).width(92).height(116).objectFit(ImageFit.Contain)
        .position({ left: 0, bottom: 88 });
      MorganaBubble({ state: this.state, ui: this.ui });
    }
    .width('100%').height(204);
  
  }
}

@Component
export struct MorganaSnsPrompt {

  @Require ui: PageActions;

  build() {
    Row({ space: 0 }) {
      Stack() {
        Image($r('app.media.sns_avatar_plate')).width('100%').height('100%').objectFit(ImageFit.Fill);
        Image($r('app.media.morgana_sns')).width(54).height(54).objectFit(ImageFit.Contain)
          .rotate({ angle: -5 }).translate({ x: 1, y: -3 });
      }
      .width(60).height(60);
      Stack() {
        Image($r('app.media.sns_message')).width('100%').height('100%').objectFit(ImageFit.Fill);
        Text('今天想做些什么，Joker？').width('100%')
          .fontSize(15).fontWeight(FontWeight.Bold).fontColor(PAPER)
          .maxLines(2).lineHeight(20).textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 28, right: 20 });
      }
      .layoutWeight(1).height(72).margin({ left: -6 }).rotate({ angle: -2 });
    }
    .width('100%').height(76).margin({ bottom: 6 });
  
  }
}


export class DialogueFeedback {
  private readonly feedback: MorganaFeedback = new MorganaFeedback();
  private feedbackTimerId: number = -1;
  private flashTimerId: number = -1;
  private readonly host: RoutineHost;
  constructor(host: RoutineHost) { this.host = host; }
  queueFeedback(event: MorganaEvent, keys: string[] = [], sign: number = 1, amounts: TraitPoints[] = []): void {
    this.feedback.queue(event, keys, sign, amounts);
    if (this.feedbackTimerId !== -1) {
      clearTimeout(this.feedbackTimerId);
    }
    if (this.flashTimerId !== -1) {
      clearTimeout(this.flashTimerId);
      this.flashTimerId = -1;
    }
    this.feedbackTimerId = setTimeout(() => {
      this.feedbackTimerId = -1;
      const cue = this.feedback.take();
      this.host.state.dialogText = cue.text;
      this.host.state.dialogDeltas = cue.deltas;
      this.host.getUIContext().animateTo({ duration: 160 }, () => this.host.state.dialogVisible = true);
      this.flashTimerId = setTimeout(() => this.dismissFeedback(), Math.max(3200, cue.text.length * 130));
    }, 350);
  }

  dismissFeedback(): void {
    if (this.feedbackTimerId !== -1) {
      clearTimeout(this.feedbackTimerId);
      this.feedbackTimerId = -1;
    }
    if (this.flashTimerId !== -1) {
      clearTimeout(this.flashTimerId);
      this.flashTimerId = -1;
    }
    this.feedback.clear();
    this.host.state.dialogVisible = false;
  }
}

@Component
export struct MorganaDialog {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
        Stack({ alignContent: Alignment.BottomStart }) {
          MorganaScene({ state: this.state, ui: this.ui });
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.End }) {
            ForEach(this.state.dialogDeltas, (delta: TraitDelta) => {
              Text(`${this.ui.queries.traitLabel(delta.key)}${delta.points > 0 ? '提升' : '调整'}`)
                .fontSize(12).fontWeight(FontWeight.Bolder)
                .fontColor(delta.points > 0 ? YELLOW : PAPER)
                .padding({ left: 8, right: 8, top: 5, bottom: 5 })
                .backgroundColor(INK).transform(SHEAR).rotate({ angle: -3 })
                .margin({ left: 6, bottom: 4 });
            }, (delta: TraitDelta) => `${delta.key}-${delta.points}`);
          }
          .width('67%').position({ right: 12, bottom: 130 });
        }
        .width('100%')
        .height(232).padding({ left: 18, right: 18, bottom: 10 })
        .position({ left: 0, right: 0, bottom: this.state.keyboardVisible ? 0 : 64 })
        .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: 12 })))
        .onClick(() => this.ui.dialogue.dismissFeedback());

  }
}
