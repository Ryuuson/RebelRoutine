import { UI_HINT_ON_INK } from '../common/Typography';
import { UI_BODY_WEIGHT, UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { ActionRecord, HabitRecord } from '../data/RoutineStore';
import { INK, PAPER, STEEL, RED } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton } from '../components/CutWidgets';
import { TraitPicker } from './TraitPicker';
import { DateField } from './DateField';
import { CommissionLink } from './CommissionLink';
@Component
export struct ActionSheet {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  private close(): void {
    if (!this.state.mutationBusy) { this.state.actionMenuId = -1; this.state.editingHabitId = -1; }
  }
  @Builder
  private operation(label: string, operation: string, dangerous: boolean = false) {
    CutButton({ label: label, selected: dangerous, labelSize: 15,
      activeColor: RED, activeTextColor: PAPER, marginEnd: 0, marginBottom: 9, stretch: true,
      action: () => this.ui.lifecycle.sheetOperation(operation) }).width('100%');
  }
  @Builder
  private habitActions(item: HabitRecord) {
    if (this.state.sheetMode === 'edit') {
      TextInput({ text: $$this.state.editTitle, placeholder: '事项标题' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(16)).height(44).fontSize(16).fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
      TextInput({ text: $$this.state.editSubtitle, placeholder: '备注'
        }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(13)).height(40).fontSize(13).fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
      DateField({ state: this.state, ui: this.ui, target: 'edit', done: item.done });
      TraitPicker({ state: this.state, target: 'habit', ui: this.ui })
      CommissionLink({ state: this.state, target: 'edit' })
      if (this.ui.queries.canOperate(item, 'delete')) { this.operation('删除', 'delete', true); }
    } else {
      if (item.deletedAt === undefined) {
        CutButton({ label: '相关便签', selected: false, action: () => this.ui.notes.openFor('habit',item.id) });
      }
      if (this.ui.queries.canOperate(item, 'complete')) { this.operation('完成', 'complete'); }
      if (this.ui.queries.canOperate(item, 'undo')) { this.operation('撤销完成', 'undo'); }
      if (this.ui.queries.canOperate(item, 'edit')) { this.operation('编辑', 'edit'); }
      if (this.ui.queries.canOperate(item, 'focus')) { this.operation('开始专注', 'focus'); }
      if (this.ui.queries.canOperate(item, 'restore')) { this.operation('恢复', 'restore'); }
      if (this.ui.queries.canOperate(item, 'reopen')) { this.operation('恢复显示', 'reopen'); }
      if (this.ui.queries.canOperate(item, 'delete')) { this.operation(this.ui.queries.deleteLabel(item), 'delete', true); }
      if (this.ui.queries.canOperate(item, 'purge')) { this.operation('永久删除', 'purge', true); }
    }
  }
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column().width('100%').height('100%').backgroundColor('#99000000').onClick(() => this.close());
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Text(this.state.actionMenuLegacy ? this.state.actions.find((item: ActionRecord) => item.id === this.state.actionMenuId)?.text ?? '' :
            this.ui.queries.selectedHabit(this.state.actionMenuId, this.state.habits)?.title ?? '')
            .layoutWeight(1).fontSize(18).fontWeight(FontWeight.Bolder).fontColor(PAPER);
          CutButton({ label: '关闭', selected: false, action: () => this.close() });
        }.width('100%');
        Scroll() {
          Column({ space: 12 }) {
            if (this.state.actionMenuLegacy) {
              ForEach(this.state.actions.filter((item: ActionRecord) => item.id === this.state.actionMenuId), (item: ActionRecord) => {
                Text('旧版行动记录').fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL);
                if (item.deletedAt !== undefined) { this.operation('恢复', 'restore'); this.operation('永久删除', 'purge', true); }
                else {
                  CutButton({ label: '相关便签', selected: false, action: () => this.ui.notes.openFor('action',item.id) });
                  this.operation('删除', 'delete', true);
                }
              });
            } else {
              ForEach(this.state.habits.filter((item: HabitRecord) => item.id === this.state.actionMenuId), (item: HabitRecord) => this.habitActions(item));
            }
          }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 8, right: 8, bottom: 10 });
        }.width('100%').layoutWeight(1).align(Alignment.TopStart).scrollBar(BarState.Off);
        if (this.state.sheetMode === 'edit') { CutButton({ label: '保存修改', selected: true, action: () => this.ui.lifecycle.saveEditing() }); }
        if (this.state.notice) { Text(this.state.notice).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER); }
      }.width('100%').height('76%').padding({ left: 18, right: 18, top: 16, bottom: 16 }).backgroundColor(INK)
        .border({ width: { top: 3 }, color: PAPER }).enabled(!this.state.mutationBusy);
    }.width('100%').height('100%');
  }

}
