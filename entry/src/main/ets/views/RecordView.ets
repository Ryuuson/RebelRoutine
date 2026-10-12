import { UI_BODY_WEIGHT } from '../common/Typography';
import { EmptyState } from '../components/EmptyState';
import { humanDate } from '../common/DayUtil';
import { RoutineState } from '../common/RoutineState';
import { CommissionAward } from '../data/CommissionModel';
import { TraitPoints } from '../data/RoutineStore';
import { INK, PAPER, RED } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton } from '../components/CutWidgets';
import { ScreenIdentity } from '../components/ScreenIdentity';
import { CutSurface } from '../components/CutSurface';
import { Composer } from '../components/Composer';
import { RewardTags } from '../components/RewardTags';
import { HistoryEntry } from '../common/RecordUtil';
import { SelectionControls, SelectionMark, SelectionSurface } from '../components/SelectionControls';
import { RecordTabs } from '../components/RecordTabs';
@Component
export struct RecordView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  @Builder
  private rewards(points: TraitPoints[], entry: HistoryEntry) {
    RewardTags({ keys: points.map((point: TraitPoints) => point.key), points: points, ui: this.ui, onPaper: true,
      selected: !!this.state.selectionPage && this.state.selectedRefs.some((ref) => ref.id === entry.id && ref.action === entry.action) })
      .width('30%');
  }
  build() {
    Scroll(this.ui.host.recordScroller) {
      Column({ space: 12 }) {
        Row() {
          ScreenIdentity({ kind: 'journal' }).layoutWeight(1);
          Column() {
            CutButton({ label: '补记', selected: true, action: () => this.ui.draft.openComposer(true) }).enabled(!this.state.selectionPage)
              .opacity(this.state.selectionPage ? 0.45 : 1);
            CutButton({ label: '菜单', selected: false, action: () => this.ui.host.openWorkspace('menu') });
          }
        }.width('100%');
        RecordTabs({ state: this.state, ui: this.ui });
        SelectionControls({ state: this.state, ui: this.ui, page: '记录' });
        if (this.state.composerOpen) { Composer({ state: this.state, ui: this.ui }) }
        if (this.state.recordTargetDay) { CutButton({ label: `只看 ${this.state.recordTargetDay.slice(5).replace('-', '/')} · 查看全部`, selected:
          false, action: () => this.ui.feedback.clearRecordFilter() }); }
        if (this.state.recordTargetTrait) {
          CutButton({ label: `${this.ui.queries.traitLabel(this.state.recordTargetTrait)}来源 · 查看全部`, selected: false,
            action: () => this.ui.feedback.clearRecordFilter() });
        }
        if (this.state.recordTargetCommission >= 0) {
          CutButton({ label: '委托行动 · 查看全部', selected: false, action: () => this.ui.feedback.clearRecordFilter() });
        }
        if (this.ui.queries.recordDays(this.state.today, this.state.historyLimit, this.state.recordTargetDay, this.state.renderEpoch).length ===
          0) { EmptyState({ message: '这段时间还没有完成记录' }); }
        ForEach(this.ui.queries.recordDays(this.state.today, this.state.historyLimit, this.state.recordTargetDay, this.state.renderEpoch), (day: string) => {
          CutSurface({ kind: 'journal' }) {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Text(day.slice(5).replace('-', '/')).fontSize(37).fontWeight(FontWeight.Bolder)
                  .fontStyle(FontStyle.Italic).fontColor(INK);
                Text(humanDate(day).split(' ')[1]).fontSize(14).fontWeight(FontWeight.Bold).fontColor(RED);
              }.width('100%').padding({ left: 12, top: 10 });
              ForEach(this.ui.queries.recordsFor(day), (entry: HistoryEntry) => {
                SelectionSurface({ state: this.state, refId: entry.id, legacy: entry.action }) {
                  Row({ space: 10 }) {
                    if (this.state.selectionPage) { SelectionMark({ state: this.state, refId: entry.id, legacy: entry.action, onPaper: true }); }
                    Column({ space: 4 }) {
                    Text(entry.title).fontSize(15).fontWeight(FontWeight.Bold)
                      .fontColor(this.state.selectionPage && this.state.selectedRefs.some((ref) =>
                        ref.id === entry.id && ref.action === entry.action) ? PAPER : INK);
                    if (!entry.action && this.state.habits.some((item) => item.id === entry.id && item.commissionId !== undefined)) {
                      Text(entry.subtitle).fontWeight(UI_BODY_WEIGHT).fontSize(11).fontColor(this.state.selectionPage ? PAPER : RED).maxLines(2);
                    }
                    }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                    this.rewards(this.ui.queries.entryRewards(entry, this.state.habits, this.state.actions), entry);
                  }.width('100%').constraintSize({ minHeight: 52 }).padding(12)
                    .enabled(!this.state.mutationBusy).onClick(() => {
                      if (this.state.selectionPage) { this.ui.batch.toggle({ id: entry.id, action: entry.action }); }
                      else { this.ui.feedback.openAction(entry.id, entry.action); }
                    }).gesture(LongPressGesture({ repeat: false }).onAction(() => {
                      if (this.state.selectionPage) { return; }
                      this.ui.feedback.openAction(entry.id, entry.action);
                      if (!entry.action) { this.ui.lifecycle.sheetOperation('edit'); }
                    }));
                }
              }, (entry: HistoryEntry) => `${entry.action ? 'a' : 't'}-${entry.id}-${this.state.renderEpoch}`);
              if (!this.state.selectionPage) {
                ForEach(this.ui.queries.commissionReceipts().filter((award: CommissionAward) => award.day === day),
                  (award: CommissionAward) => {
                    Column({ space: 4 }) {
                      Text(award.title).fontSize(15).fontWeight(FontWeight.Bold).fontColor(INK);
                      Text(`委托达成来源 · ${award.points.map((point) => this.ui.queries.traitLabel(point.key)).join(' / ')}`).fontWeight(UI_BODY_WEIGHT)
                        .fontSize(11).fontColor(RED);
                    }.width('100%').alignItems(HorizontalAlign.Start).padding(12).onClick(() => this.ui.commissions.open(award.goalId));
                  }, (award: CommissionAward) => `${award.key}-${this.state.renderEpoch}`);
              }
            }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 24, right: 14, top: 8, bottom: 23 });
          }
        }, (day: string) => `${day}-${this.state.renderEpoch}-${this.state.historyLimit}`);
        if (!this.state.recordTargetDay && this.ui.queries.hasEarlier(this.state.today, this.state.historyLimit, this.state.renderEpoch)) {
          CutButton({ label: '更早', selected: false, action: () => this.state.historyLimit += 14 });
        }
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 18, right: 18, top: 20, bottom: 24 });
    }.width('100%').height('100%').align(Alignment.TopStart).scrollBar(BarState.Off);
  }

}
