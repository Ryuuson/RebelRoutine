import { PAPER, INK, RED } from '../common/Theme';
import { CutButton } from './CutWidgets';

@Component
export struct CommissionChoice {
  @Prop label: string;
  @Prop selected: boolean = false;
  @Require action: () => void;
  build() {
    CutButton({ label: this.label, selected: this.selected, labelSize: 13,
      activeColor: RED, idleColor: INK, activeTextColor: PAPER, marginBottom: 5, action: this.action });
  }
}
