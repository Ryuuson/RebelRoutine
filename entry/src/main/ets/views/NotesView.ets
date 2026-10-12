import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { ScreenIdentity } from '../components/ScreenIdentity';
import { CutButton } from '../components/CutWidgets';
import { RecordTabs } from '../components/RecordTabs';
import { NoteList } from '../components/NoteList';

@Component
export struct NotesView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Scroll() {
      Column({ space: 15 }) {
        Row() {
          ScreenIdentity({ kind: 'notes' }).layoutWeight(1);
          Column() {
            CutButton({ label: '写随笔', selected: true, action: () => this.ui.notes.edit() });
            CutButton({ label: '菜单', selected: false, action: () => this.ui.host.openWorkspace('menu') });
          }
        }.width('100%');
        RecordTabs({ state: this.state, ui: this.ui });
        NoteList({ state: this.state, ui: this.ui });
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 18, right: 18, top: 20, bottom: 24 });
    }.width('100%').height('100%').align(Alignment.TopStart).scrollBar(BarState.Off);
  }
}
