import { UI_BODY_WEIGHT } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { RepeatPlan } from '../data/CommissionModel';
import { INK, PAPER, STEEL } from '../common/Theme';
import { CutButton } from '../components/CutWidgets';
import { CutSurface } from '../components/CutSurface';

@Component
export struct RepeatView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Column({ space: 16 }) {
      CutButton({ label: '新建重复计划', selected: true, action: () => this.ui.commissions.editRepeat() });
      ForEach(this.state.m2?.repeats ?? [], (plan: RepeatPlan) => {
        CutSurface() {
          Column({ space: 10 }) {
            Text(plan.title).fontSize(19).fontWeight(FontWeight.Bold).fontColor(PAPER);
            Text(plan.rule === 'daily' ? '每天' : `每周 ${plan.weekdays.map((day: number) => ['日','一','二','三','四','五','六'][day]).join(' / ')}`).fontWeight(UI_BODY_WEIGHT)
              .fontSize(12).fontColor(STEEL);
            Text(plan.paused ? '已暂停' : `从 ${plan.startDay} 起`).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL);
            Row({ space: 8 }) {
              CutButton({ label: '编辑', selected: false, action: () => this.ui.commissions.editRepeat(plan) });
              CutButton({ label: plan.paused ? '继续' : '暂停', selected: false, action: () => this.ui.commissions.toggleRepeat(plan.id) });
            }.width('100%');
          }.width('100%').alignItems(HorizontalAlign.Start).padding(20);
        }
      }, (plan: RepeatPlan) => `${plan.id}-${this.state.renderEpoch}`);
    }.width('100%').alignItems(HorizontalAlign.Start);
  }
}
