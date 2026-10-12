import { UI_HINT_ON_INK } from '../common/Typography';
import { UI_BODY_WEIGHT, UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { EmptyState } from './EmptyState';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { NoteRecord } from '../data/NoteModel';
import { RoutineEngine } from '../data/RoutineEngine';
import { INK, PAPER, RED, STEEL } from '../common/Theme';
import { CutButton } from './CutWidgets';
import { CutSurface } from './CutSurface';

@Component
export struct NoteList {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Column({ space: 13 }) {
      if (this.state.workspace === 'notes') {
        Text(this.ui.notes.label(this.state.noteContext)).fontSize(16).fontWeight(FontWeight.Bold).fontColor(PAPER)
          .width('100%').padding(10).backgroundColor(INK);
        CutButton({ label: '写便签', selected: true, action: () => this.ui.notes.edit() });
      }
      TextInput({ text: $$this.state.noteSearch, placeholder: '搜索标题、正文或关联事项' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(13)).height(44).fontSize(13)
        .fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.state.workspace === 'notes' ? ['全部','回收站'] : ['全部','随笔','关联','回收站'], (filter: string) => {
          CutButton({ label: filter, selected: this.state.noteFilter === filter, buttonHeight: 34,
            activeColor: RED, idleColor: INK, activeTextColor: PAPER, marginEnd: 10, marginBottom: 6,
            action: () => this.state.noteFilter = filter });
        });
      }.width('100%');
      if (!this.ui.notes.list().length) {
        EmptyState({ message: this.state.noteSearch ? '没有找到匹配的便签' : this.state.noteFilter === '回收站' ? '回收站是空的' : '暂无便签' });
      }
      ForEach(this.ui.notes.list(), (note: NoteRecord) => {
        CutSurface({ kind: 'journal' }) {
          Column({ space: 9 }) {
            Text(note.title).fontSize(21).fontWeight(FontWeight.Bolder).fontColor(INK).maxLines(2)
              .onClick(() => this.ui.notes.edit(note));
            Text(this.ui.notes.label(note.link)).fontSize(11).fontWeight(FontWeight.Bold).fontColor(RED).maxLines(2);
            if (note.body) { Text(note.body).fontWeight(UI_BODY_WEIGHT).fontSize(14).fontColor(INK).maxLines(3); }
            Text(RoutineEngine.localTime(new Date(note.updatedAt))).fontWeight(UI_BODY_WEIGHT).fontSize(10).fontColor('#555555');
            Flex({ wrap: FlexWrap.Wrap }) {
              if (note.deletedAt === undefined) {
                CutButton({ label: '打开', selected: false, action: () => this.ui.notes.edit(note) });
                CutButton({ label: '删除', selected: false, action: () => this.ui.notes.request(note,'delete') });
              } else {
                CutButton({ label: '恢复', selected: false, action: () => this.ui.notes.restore(note) });
                CutButton({ label: '永久删除', selected: false, action: () => this.ui.notes.request(note,'purge') });
              }
            }.width('100%');
          }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 30, right: 24, top: 19, bottom: 26 });
        }
      }, (note: NoteRecord) => `${note.id}-${note.updatedAt}-${this.state.renderEpoch}`);
      if (this.state.notice) { Text(this.state.notice).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(STEEL).padding(8).backgroundColor(INK); }
    }.width('100%').alignItems(HorizontalAlign.Start).enabled(this.state.dataReady && !this.state.mutationBusy);
  }
}
