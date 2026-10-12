import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { CutButton, cutLabel } from '../components/CutWidgets';
import { FocusView } from '../views/FocusView';
import { CollectionView } from './CollectionView';
import { BatchBar } from '../components/BatchBar';
import { DataChoice } from '../components/CutWidgets';
import { PinnedView } from '../views/PinnedView';
import { LoadingNotice } from '../components/CutWidgets';
import { DataView } from '../views/DataView';
import { CommissionView } from './CommissionView';
import { RepeatView } from './RepeatView';
import { NoteList } from '../components/NoteList';

@Component
export struct MenuView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;

  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor('#33000000');
      Column() {
        Scroll() {
          Column({ space: 15 }) {
            Row() {
              cutLabel(this.ui.feedback.workspaceTitleRed(this.state.workspace), this.ui.feedback.workspaceTitleWhite(this.state.workspace), 25);
              Blank().layoutWeight(1);
              CutButton({ label: '返回', selected: true, action: () => {
                if (this.state.workspace === 'commission') { this.ui.commissions.back(); } else { this.ui.host.closeWorkspace(); }
              } });
            }.width('100%').margin({ top: 20 });
            LoadingNotice({ state: this.state, ui: this.ui });
            if (this.state.workspace === 'menu') {
              DataChoice({ title: '回收站', action: () => {
                this.state.libraryFilter = '回收站'; this.ui.host.openWorkspace('manage');
              }, ui: this.ui });
              DataChoice({ title: '数据管理', action: () => this.ui.host.openWorkspace('data'), ui: this.ui });
            } else if (this.state.workspace === 'manage') {
              CollectionView({ state: this.state, ui: this.ui });
            } else if (this.state.workspace === 'pinned') {
              PinnedView({ state: this.state, ui: this.ui });
            } else if (this.state.workspace === 'focus') {
              FocusView({ state: this.state, ui: this.ui });
            } else if (this.state.workspace === 'data') {
              DataView({ state: this.state, ui: this.ui });
            } else if (this.state.workspace === 'commission') {
              CommissionView({ state: this.state, ui: this.ui });
            } else if (this.state.workspace === 'repeats') {
              RepeatView({ state: this.state, ui: this.ui });
            } else if (this.state.workspace === 'notes') {
              NoteList({ state: this.state, ui: this.ui });
            }
            Image($r('app.media.logo_takeyourheart')).width(70).height(70).objectFit(ImageFit.Contain).alignSelf(ItemAlign.End);
          }.width('100%').padding({ left: 18, right: 18, bottom: 24 });
        }.width('100%').layoutWeight(1).align(Alignment.TopStart).scrollBar(BarState.Off);
        if (this.state.selectionPage) { BatchBar({ state: this.state, ui: this.ui }); }
      }.width('100%').height('100%');
    }.width('100%').height('100%');
  
  }
}
