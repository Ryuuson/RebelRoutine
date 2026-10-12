import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { INK } from '../common/Theme';
import { CutButton } from './CutWidgets';

@Component
export struct BatchBar {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Row({ space: 8 }) {
      CutButton({ label: '取消', selected: false, action: () => this.ui.batch.exit() });
      Blank().layoutWeight(1);
      Row({ space: 8 }) {
        if (this.state.selectionPage === '回收站') {
          CutButton({ label: '恢复', selected: true, action: () => this.ui.batch.request('restore') });
          CutButton({ label: '永久删除', selected: false, action: () => this.ui.batch.request('purge') });
        } else {
          if (this.state.selectionPage === '任务') {
            CutButton({ label: '完成', selected: true, action: () => this.ui.batch.request('complete') });
          }
          CutButton({ label: '编辑', selected: false, action: () => this.ui.batch.openEdit() })
            .enabled(this.ui.batch.canEdit(this.state.selectedRefs));
          CutButton({ label: '删除', selected: false, action: () => this.ui.batch.request('delete') });
        }
      }.enabled(this.state.selectedRefs.length > 0).opacity(this.state.selectedRefs.length > 0 ? 1 : 0.4);
    }.width('100%').height(64).padding({ left: 18, right: 18, top: 9, bottom: 11 }).backgroundColor(INK)
      .enabled(!this.state.mutationBusy);
  }
}
