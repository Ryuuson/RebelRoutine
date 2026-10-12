import { RoutineState } from '../common/RoutineState';
import { INK, PAPER } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton } from '../components/CutWidgets';

@Component
export struct MainNavigation {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  build() {
    Row({ space: 9 }) {
      ForEach(['今日', '任务', '记录', '成长'], (page: string) => {
        CutButton({ label: page, selected: this.state.mainPage === page, labelSize: 17,
          labelWeight: FontWeight.Bolder, idleColor: INK, horizontalInset: 10,
          marginEnd: 0, marginBottom: 0, stretch: true, action: () => this.ui.host.switchPage(page) }).layoutWeight(1);
      });
    }.width('100%').height(64).padding({ left: 18, right: 18, top: 9, bottom: 11 }).backgroundColor(INK);
  }
}
