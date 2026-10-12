import { UI_BODY_WEIGHT, UI_LABEL_STYLE, UI_LABEL_WEIGHT, uiPlaceholder } from '../common/Typography';
import { RoutineState } from '../common/RoutineState';
import { INK, PAPER, STEEL, RED } from '../common/Theme';
import { PageActions } from '../common/PageActions';
import { CutButton } from './CutWidgets';

@Component
export struct Composer {
  @ObjectLink state: RoutineState;
  @Require ui: PageActions;
  @Prop inputId: string = 'routine-title';

  build() {
    Column({ space: 5 }) {
      Stack() {
        Image($r('app.media.task_cut_a')).width('100%').height('100%').objectFit(ImageFit.Fill);
        Row({ space: 5 }) {
          TextInput({ text: $$this.state.newTaskDraft, placeholder: this.state.draftDone ? '已经做了什么' : '写下一件想做的事' })
            .id(this.inputId).layoutWeight(1).height(48).fontSize(16).fontWeight(FontWeight.Bold).fontStyle(FontStyle.Normal)
            .fontColor(PAPER).placeholderColor(STEEL).placeholderFont(uiPlaceholder(16))
            .backgroundColor(Color.Transparent).borderRadius(0).padding({ left: 6, right: 2 })
            .onSubmit(() => this.ui.draft.submitQuick());
          Button('⋯').fontWeight(UI_LABEL_WEIGHT).fontStyle(UI_LABEL_STYLE).width(32).height(44).fontSize(23).fontColor(PAPER).backgroundColor(INK).borderRadius(0).padding(0)
            .onClick(() => this.ui.draft.openOptions());
          CutButton({ label: 'ADD+', selected: true, labelWeight: FontWeight.Bolder,
            activeColor: RED, activeTextColor: PAPER, horizontalInset: 8, marginEnd: 0, marginBottom: 0, stretch: true,
            action: () => this.ui.draft.submitQuick() }).width(58);
        }.width('100%').padding({ left: 12, right: 18 });
      }.width('100%').height(62);
      if (this.ui.queries.quickSummary(this.state.draftDay, this.state.draftDone, this.state.draftTraits, this.state.draftPoints, this.state.today)) {
        Text(this.ui.queries.quickSummary(this.state.draftDay, this.state.draftDone, this.state.draftTraits, this.state.draftPoints, this.state.today)).fontWeight(UI_BODY_WEIGHT)
          .width('100%').fontSize(12).fontColor(PAPER).padding({ left: 12, right: 12, bottom: 4 })
          .onClick(() => this.ui.draft.openOptions());
      }
      if (this.state.draftError) { Text(this.state.draftError).fontWeight(UI_BODY_WEIGHT).fontSize(12).fontColor(PAPER).backgroundColor(RED).padding(8); }
    }.width('100%').enabled(this.state.dataReady && !this.state.mutationBusy);
  }

}
