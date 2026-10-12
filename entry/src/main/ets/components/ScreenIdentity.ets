import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { dateLabel } from '../common/DayUtil';
import { INK, PAPER, RED, YELLOW } from '../common/Theme';
import { CutButton } from './CutWidgets';
import { CutWord } from './CutWord';

@Component
export struct ScreenIdentity {
  @Prop kind: string = 'mission';
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.kind === 'mission') {
        Text('REQUEST').fontSize(23).fontWeight(FontWeight.Bolder).fontStyle(FontStyle.Italic).fontColor(RED)
          .backgroundColor(INK).padding({ left: 7, right: 7 }).position({ left: 8, top: 0 });
        CutWord({ label: '任务', labelSize: 39, labelStyle: FontStyle.Italic }).rotate({ angle: -6 })
          .position({ left: 0, top: 23 });
        Text('清单').fontSize(19).fontWeight(FontWeight.Bolder).fontColor(PAPER).backgroundColor(INK).padding(4)
          .rotate({ angle: -6 }).position({ left: 95, top: 54 });
      } else if (this.kind === 'journal' || this.kind === 'notes') {
        Text(this.kind === 'notes' ? 'NOTE BOOK' : 'DAILY LOG').fontSize(25)
          .fontWeight(FontWeight.Bolder).fontStyle(FontStyle.Italic).fontColor(INK)
          .backgroundColor(PAPER).padding({ left: 7, right: 10 }).rotate({ angle: -5 }).position({ left: 3, top: 0 });
        Text(this.kind === 'notes' ? '便签随笔' : '行动记录').fontSize(29)
          .fontWeight(FontWeight.Bolder).fontColor(PAPER).backgroundColor(INK).padding(5)
          .rotate({ angle: -3 }).position({ left: 14, top: 31 });
      } else {
        Text('STATUS').fontSize(24).fontWeight(FontWeight.Bolder).fontStyle(FontStyle.Italic).fontColor(YELLOW)
          .backgroundColor(INK).padding({ left: 7, right: 7 }).position({ left: 7, top: 0 });
        Text('人格指数').fontSize(31).fontWeight(FontWeight.Bolder).fontStyle(FontStyle.Italic).fontColor(PAPER)
          .backgroundColor(INK).padding(5).rotate({ angle: -5 }).position({ left: 0, top: 28 });
      }
    }.width('100%').height(93);
  }
}

@Component
export struct TodayIdentity {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($r('app.media.date_splash')).width(205).height(142).objectFit(ImageFit.Fill).position({ left: 5, top: 0 });
      Text(`${Number(this.state.today.slice(5, 7))}/${Number(this.state.today.slice(8, 10))}`)
        .width(155).height(66).fontSize(60).minFontSize(42).maxFontSize(60).maxLines(1)
        .padding({ left: 8, right: 8, top: 3, bottom: 3 })
        .fontWeight(FontWeight.Bolder).fontStyle(FontStyle.Italic).fontColor(PAPER).textAlign(TextAlign.Center)
        .shadow({ radius: 0, color: INK, offsetX: 3, offsetY: 3 }).rotate({ angle: -7 }).position({ left: 28, top: 23 });
      CutWord({ label: dateLabel(this.state.today).slice(0, 3), labelSize: 22, labelStyle: FontStyle.Italic })
        .rotate({ angle: -12 }).position({ left: 67, top: 84 });
      Text('今日').fontSize(23).fontWeight(FontWeight.Bolder).fontStyle(FontStyle.Normal).fontColor(PAPER)
        .backgroundColor(INK).padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .rotate({ angle: -10 }).position({ left: 18, top: 112 });
      CutButton({ label: '菜单', selected: false, action: () => this.ui.host.openWorkspace('menu') })
        .position({ right: 10, top: 14 });
      CutWord({ label: `${this.state.completedCount}/${this.ui.queries.todayHabits(this.state.habits, this.state.today).length}`,
        labelSize: 31, labelStyle: FontStyle.Italic, color: PAPER, plateColor: RED }).rotate({ angle: 6 })
        .position({ right: 18, top: 103 });
    }.width('100%').height(165);
  }
}
