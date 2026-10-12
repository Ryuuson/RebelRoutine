import { RoutineState } from '../common/RoutineState';
import { PAPER } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { DataChoice } from '../components/CutWidgets';

export interface DataViewBindings {
  state: RoutineState;
  ui: PageActions;
}

@Builder
export function DataView($$: DataViewBindings) {
            DataChoice({ title: '完整备份', subtitle: 'JSON', action: () => $$.ui.data.exportData(false), ui: $$.ui });
            DataChoice({ title: '导出记录', subtitle: 'CSV', action: () => $$.ui.data.exportData(true), ui: $$.ui });
            DataChoice({ title: '恢复备份', action: () => $$.ui.data.importData(), ui: $$.ui });
            DataChoice({ title: '撤回恢复', action: () => $$.ui.data.requestRestoreUndo(), ui: $$.ui });
          
}

