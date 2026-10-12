import { UI_BODY_WEIGHT } from '../common/Typography';
import { EmptyState } from '../components/EmptyState';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { Commission } from '../data/CommissionModel';
import { CommissionProgress } from '../data/CommissionProgress';
import { INK, PAPER, RED, SHEAR, STEEL } from '../common/Theme';
import { CutSurface } from '../components/CutSurface';
import { CutButton } from '../components/CutWidgets';

@Component
export struct CommissionList {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  private value(goal: Commission): string {
    const value: number = CommissionProgress.value(this.ui.host.snapshot(),goal,CommissionProgress.period(goal,this.state.today));
    return `${goal.mode === 'project' ? Math.round(value*10)/10 : value}`;
  }
  build() {
    Column({ space: 12 }) {
      if (!this.state.m2?.goals.length) {
        Column({ space: 12 }) {
          EmptyState({ message: '暂无委托', inset: 0 });
          CutButton({ label: '建立委托', selected: true, action: () => this.ui.commissions.edit() });
        }.width('100%').alignItems(HorizontalAlign.Start).padding(16).backgroundColor(INK);
      }
      ForEach(this.state.m2?.goals.filter((goal: Commission) => goal.parentId === undefined) ?? [],
        (goal: Commission) => {
          CutSurface() {
            Column({ space: 10 }) {
              Text(goal.title).fontSize(21).fontWeight(FontWeight.Bolder).fontColor(INK).backgroundColor(PAPER)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 }).transform(SHEAR).maxLines(3);
              Text(this.value(goal))
                .width('100%').fontSize(33).minFontSize(18).maxFontSize(33).maxLines(1)
                .fontStyle(FontStyle.Italic).fontWeight(FontWeight.Bolder).fontColor(PAPER);
              Row() {
                Text(`目标 ${goal.target} ${goal.unit}`).fontWeight(UI_BODY_WEIGHT).fontSize(13).fontColor(PAPER).layoutWeight(1).maxLines(2);
                Text(`${Math.round(CommissionProgress.ratio(this.ui.host.snapshot(),goal,CommissionProgress.period(goal,this.state.today))*100)}%`)
                  .fontSize(18).fontWeight(FontWeight.Bold).fontColor(RED);
              }.width('100%');
              Text(goal.weekly ? '本周 · 周一至周日' : goal.deadline ? `截止 ${goal.deadline}` : '持续推进').fontWeight(UI_BODY_WEIGHT)
                .fontSize(11).fontColor(STEEL);
            }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 18, right: 18, top: 16, bottom: 18 })
              .onClick(() => this.ui.commissions.open(goal.id));
          }
        }, (goal: Commission) => `${goal.id}-${this.state.renderEpoch}`);
    }.width('100%').alignItems(HorizontalAlign.Start);
  }
}
