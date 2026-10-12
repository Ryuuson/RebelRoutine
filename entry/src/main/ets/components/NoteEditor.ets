import { UI_HINT_ON_PAPER } from '../common/Typography';
import { UI_BODY_WEIGHT, UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { PageActions } from '../common/PageActions';
import { NoteLink } from '../data/NoteModel';
import { NoteQueries } from '../data/NoteQueries';
import { PAPER, INK, RED } from '../common/Theme';
import { CutButton, cutLabel } from './CutWidgets';
import { Motion } from '../common/Motion';

@Component
export struct NoteEditor {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Column({ space: 10 }) {
      Row() {
        cutLabel('我的','便签',23);
        Blank().layoutWeight(1);
        CutButton({ label: '关闭', selected: false, action: () => this.ui.notes.requestClose() });
      }.width('100%');
      TextInput({ text: $$this.state.noteTitle, placeholder: '标题' }).placeholderColor(UI_HINT_ON_PAPER).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(19)).height(44).fontSize(19)
        .fontWeight(FontWeight.Bold).fontColor(INK).backgroundColor(PAPER).borderRadius(0).maxLength(120);
      Row({ space: 8 }) {
        Text(this.ui.notes.label(this.state.noteLink)).fontWeight(UI_BODY_WEIGHT).layoutWeight(1).fontSize(12).fontColor(PAPER).maxLines(2);
        CutButton({ label: this.state.noteLinkPicking ? '收起' : '关联', selected: false,
          action: () => this.state.noteLinkPicking = !this.state.noteLinkPicking });
      }.width('100%');
      if (this.state.noteLinkPicking) {
        TextInput({ text: $$this.state.noteLinkSearch, placeholder: '搜索要关联的事项或委托' }).placeholderColor(UI_HINT_ON_PAPER).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(13)).height(40).fontSize(13)
          .fontColor(INK).backgroundColor(PAPER).borderRadius(0);
        Scroll() {
          Column({ space: 6 }) {
            CutButton({ label: '独立随笔 · 不关联', selected: !this.state.noteLink, action: () => this.ui.notes.choose() });
            ForEach(NoteQueries.targets(this.ui.host.snapshot(),this.state.noteLinkSearch), (link: NoteLink) => {
              CutButton({ label: `${link.kind === 'commission' ? '委托' : link.kind === 'action' ? '行动' : '事项'} · ${link.title}`,
                selected: true, labelSize: 14, labelWeight: UI_BODY_WEIGHT, labelLines: 2, buttonHeight: 56,
                activeColor: RED, activeTextColor: PAPER, marginEnd: 0, marginBottom: 0, stretch: true,
                action: () => this.ui.notes.choose(link) }).width('100%');
            }, (link: NoteLink) => `${link.kind}-${link.id}`);
          }.width('100%').padding({ left: 8, right: 8 });
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off).transition(Motion.content());
      } else {
        TextArea({ text: $$this.state.noteBody, placeholder: '想到什么，就写下来…' }).placeholderColor(UI_HINT_ON_PAPER).fontWeight(UI_BODY_WEIGHT).placeholderFont(uiPlaceholder(16)).width('100%').layoutWeight(1)
          .fontSize(16).fontColor(INK).backgroundColor(PAPER).borderRadius(0).padding(16).maxLength(100000)
          .transition(Motion.content());
      }
      if (this.state.noteError) { Text(this.state.noteError).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER).maxLines(2); }
      Row() {
        Blank().layoutWeight(1);
        CutButton({ label: '保存', selected: true, action: () => this.ui.notes.save() });
      }.width('100%');
    }.width('100%').height('100%').padding(18).backgroundColor('#ED101010')
      .enabled(this.state.dataReady && !this.state.mutationBusy);
  }
}
