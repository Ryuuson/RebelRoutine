import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { RED, PAPER, INK } from '../common/Theme';
import { CutButton } from './CutWidgets';

@Component
export struct RecordTabs {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Row({ space: 12 }) {
      ForEach(['行动','便签'], (section: string) => {
        CutButton({ label: section, selected: this.state.recordSection === section, labelSize: 15,
          labelWeight: FontWeight.Bolder, buttonHeight: 40, horizontalInset: 18,
          activeColor: RED, idleColor: INK, activeTextColor: PAPER, marginEnd: 0, marginBottom: 0,
          action: () => this.ui.notes.selectSection(section) });
      });
    }.width('100%');
  }
}
