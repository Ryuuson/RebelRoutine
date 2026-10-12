import { UI_HINT_ON_INK } from '../common/Typography';
import { UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { EmptyState } from '../components/EmptyState';
import { RoutineState } from '../common/RoutineState';
import { PinnedTask } from '../data/RoutineStore';
import { INK, PAPER, STEEL, RED } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton } from '../components/CutWidgets';
import { TraitPicker } from '../components/TraitPicker';


@Component
export struct PinnedView {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  build() {
    Column({ space: 8 }) {
            CutButton({ label: '新增模板', selected: true, action: () => this.ui.draft.startNewPinned() });
            if (this.state.editingPinnedId === -2) {
              Column({ space: 7 }) {
                      TextInput({ text: this.state.pinnedEditTitle, placeholder: '事项标题' }).placeholderColor(UI_HINT_ON_INK).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(15)).onChange((value: string) => { this.state.pinnedEditTitle = value; })
                        .width('100%').height(34).fontSize(15).fontWeight(FontWeight.Bold)
                        .fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
                      TextInput({ text: this.state.pinnedEditSubtitle, placeholder: '副标题' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(11)).onChange((value: string) => {
                        this.state.pinnedEditSubtitle = value; })
                        .width('100%').height(30).fontSize(11)
                        .fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
                      TraitPicker({ state: this.state, target: 'pinned', ui: this.ui });
                      Row({ space: 8 }) {
                        Button('保存').fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).layoutWeight(1).height(32).fontSize(11).fontColor(PAPER)
                          .backgroundColor(RED).borderRadius(0).onClick(() => this.ui.draft.savePinnedEditing());
                        Button('关闭').fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).layoutWeight(1).height(32).fontSize(11).fontColor(PAPER)
                          .backgroundColor('#353538').borderRadius(0)
                          .onClick(() => this.state.editingPinnedId = -1);
                      }
                      .width('100%');

              }.width('100%').padding(20).backgroundColor(INK);
            }
            if (this.state.pinnedTasks.length === 0) { EmptyState({ message: '暂无固定事项' }); }
              ForEach(this.state.pinnedTasks, (item: PinnedTask, index: number) => {
                Stack() {
                  Image(this.state.editingPinnedId === item.id ? $r('app.media.pinned_choice_edit') : $r('app.media.pinned_choice'))
                    .width('100%').height('100%').objectFit(ImageFit.Fill);
                  Image($r('app.media.pinned_choice_active'))
                    .width('100%').height('100%').objectFit(ImageFit.Fill)
                    .opacity(this.state.pressedPinnedId === item.id ? 1 : 0);
                  Column({ space: 7 }) {
                    if (this.state.editingPinnedId === item.id) {
                      TextInput({ text: this.state.pinnedEditTitle, placeholder: '事项标题' }).placeholderColor(UI_HINT_ON_INK).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(15)).onChange((value: string) => { this.state.pinnedEditTitle = value; })
                        .width('100%').height(34).fontSize(15).fontWeight(FontWeight.Bold)
                        .fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
                      TextInput({ text: this.state.pinnedEditSubtitle, placeholder: '副标题' }).placeholderColor(UI_HINT_ON_INK).fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).placeholderFont(uiPlaceholder(11)).onChange((value: string) => {
                        this.state.pinnedEditSubtitle = value; })
                        .width('100%').height(30).fontSize(11)
                        .fontColor(PAPER).backgroundColor('#242426').borderRadius(0);
                      TraitPicker({ state: this.state, target: 'pinned', ui: this.ui });
                      Row({ space: 8 }) {
                        Button('保存').fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).layoutWeight(1).height(32).fontSize(11).fontColor(PAPER)
                          .backgroundColor(RED).borderRadius(0).onClick(() => this.ui.draft.savePinnedEditing());
                        Button('移除').fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).layoutWeight(1).height(32).fontSize(11).fontColor(PAPER)
                          .backgroundColor('#353538').borderRadius(0)
                          .onClick(() => { this.state.editingPinnedId = -1; this.ui.draft.removePinned(item.id); });
                        Button('关闭').fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).layoutWeight(1).height(32).fontSize(11).fontColor(PAPER)
                          .backgroundColor('#353538').borderRadius(0)
                          .onClick(() => this.state.editingPinnedId = -1);
                      }
                      .width('100%');
                    } else {
                      Text(item.title).width('100%').fontSize(18).fontWeight(FontWeight.Bold)
                        .fontColor(this.state.pressedPinnedId === item.id ? INK : PAPER)
                        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
                    }
                  }
                  .width('100%').padding({ left: 27, right: 40 });
                }
                .width('100%')
                .height(this.state.editingPinnedId === item.id ? 260 + this.ui.queries.pickerHeight('pinned', this.state.pinnedEditTraits) :
                  (item.title.length > 12 ? 88 : 64))
                .margin({ top: index === 0 ? 0 : -3 })
                .onTouch((event: TouchEvent) => {
                  this.state.pressedPinnedId = event.type === TouchType.Down && this.state.editingPinnedId !== item.id ? item.id : -1;
                })
                .onClick(() => {
                  this.ui.draft.startPinnedEditing(item);
                })
                .gesture(LongPressGesture({ repeat: false }).onAction(() => {
                  if (this.state.editingPinnedId !== item.id) { this.ui.draft.startPinnedEditing(item); }
                }));
                Row() {
                  if (index > 0) { CutButton({ label: '上移', selected: false, action: () => this.ui.draft.movePinned(item.id, -1) }); }
                  if (index < this.state.pinnedTasks.length - 1) { CutButton({ label: '下移', selected: false, action: () =>
                    this.ui.draft.movePinned(item.id, 1) }); }
                }
              }, (item: PinnedTask) => `${item.id}-${this.state.renderEpoch}`);

          

    }.width('100%').alignItems(HorizontalAlign.Start);
  }
}
