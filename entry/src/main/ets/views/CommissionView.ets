import { UI_BODY_WEIGHT } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { Commission, CommissionStage, CommissionAward } from '../data/CommissionModel';
import { CommissionProgress } from '../data/CommissionProgress';
import { INK, PAPER, RED, STEEL, SHEAR } from '../common/Theme';
import { CutButton } from '../components/CutWidgets';
import { CutSurface } from '../components/CutSurface';

@Component
export struct CommissionView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  private progress(goal: Commission, period: string): string {
    const value: number = CommissionProgress.value(this.ui.host.snapshot(),goal,period);
    return `${goal.mode === 'project' ? Math.round(value*10)/10 : value} / ${goal.target} ${goal.unit}`;
  }
  build() {
    Column({ space: 16 }) {
      ForEach(this.state.m2?.goals.filter((goal: Commission) => goal.id === this.state.commissionId) ?? [], (goal: Commission) => {
        Text(goal.title).fontSize(27).fontWeight(FontWeight.Bolder).fontColor(PAPER).backgroundColor(INK).padding(8);
        CutSurface() {
          Column({ space: 10 }) {
            Text(goal.weekly ? '本周进度' : '累计进度').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL);
            Text(this.progress(goal,CommissionProgress.period(goal,this.state.today))).fontSize(30).fontWeight(FontWeight.Bolder)
              .fontStyle(FontStyle.Italic).fontColor(PAPER).maxLines(2);
            Text(`${Math.round(CommissionProgress.ratio(this.ui.host.snapshot(),goal,CommissionProgress.period(goal,this.state.today))*100)}%`)
              .fontSize(21).fontWeight(FontWeight.Bold).fontColor(RED);
            if (goal.deadline) { Text(`截止 ${goal.deadline}`).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL); }
          }.width('100%').alignItems(HorizontalAlign.Start).padding(20);
        }
        Flex({ wrap: FlexWrap.Wrap }) {
          if (goal.mode !== 'project') {
            CutButton({ label: '记录进度', selected: true, action: () => this.ui.commissions.startProgress(goal) });
          }
          CutButton({ label: '编辑委托', selected: false, action: () => this.ui.commissions.edit(goal) });
          CutButton({ label: '查看行动', selected: false, action: () => this.ui.commissions.records(goal.id) });
          CutButton({ label: '相关便签', selected: false, action: () => this.ui.notes.openFor('commission',goal.id) });
        }.width('100%');
        if (goal.mode === 'project') {
          CutButton({ label: '增加子任务', selected: true, action: () => this.ui.commissions.edit(undefined,goal.id) });
          ForEach(this.state.m2?.goals.filter((item: Commission) => item.parentId === goal.id) ?? [], (child: Commission) => {
            Column({ space: 8 }) {
              Text(child.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(INK).backgroundColor(PAPER).padding(6).transform(SHEAR);
              Text(this.progress(child,'all')).fontWeight(UI_BODY_WEIGHT).fontSize(16).fontColor(PAPER);
            }.width('100%').alignItems(HorizontalAlign.Start).padding(12).backgroundColor(INK)
              .onClick(() => this.ui.commissions.open(child.id));
          }, (child: Commission) => `${child.id}-${this.state.renderEpoch}`);
        }
        ForEach(goal.stages, (stage: CommissionStage) => {
          Row({ space: 10 }) {
            Text(`${stage.percent}%`).fontSize(18).fontWeight(FontWeight.Bold).fontColor(RED);
            Text(stage.title).fontSize(15).fontWeight(FontWeight.Bold).fontColor(PAPER).layoutWeight(1);
            Text(CommissionProgress.ratio(this.ui.host.snapshot(),goal,CommissionProgress.period(goal,this.state.today))*100 >= stage.percent ?
              '达成' : '推进中').fontWeight(UI_BODY_WEIGHT).fontSize(11).fontColor(STEEL);
          }.width('100%').padding(10).backgroundColor(INK);
        }, (stage: CommissionStage) => `${stage.id}-${this.state.renderEpoch}`);
        if (goal.weekly) {
          ForEach(CommissionProgress.periods(this.ui.host.snapshot(),goal).filter((period: string) =>
            period !== CommissionProgress.week(this.state.today)).sort().reverse(), (period: string) => {
            Text(`${period} 起的一周 · ${this.progress(goal,period)}`).fontWeight(UI_BODY_WEIGHT).fontSize(14).fontColor(PAPER).padding(10).backgroundColor(INK);
          }, (period: string) => `${period}-${this.state.renderEpoch}`);
        }
        ForEach(this.state.m2?.awards.filter((award: CommissionAward) => award.goalId === goal.id && award.active) ?? [],
          (award: CommissionAward) => {
            Text(`${award.title} · ${award.day}`).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER).padding(8).backgroundColor(INK);
          }, (award: CommissionAward) => `${award.key}-${this.state.renderEpoch}`);
      }, (goal: Commission) => `${goal.id}-${this.state.renderEpoch}`);
    }.width('100%').alignItems(HorizontalAlign.Start);
  }
}
