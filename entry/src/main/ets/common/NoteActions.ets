import { RoutineHost } from './RoutineHost';
import { PageActions } from './PageActions';
import { RoutineSnapshot } from '../data/RoutineModel';
import { NoteRecord, NoteLink } from '../data/NoteModel';
import { NoteCommands } from '../data/NoteCommands';
import { NoteQueries } from '../data/NoteQueries';

export class NoteActions {
  private readonly host: RoutineHost;
  private readonly ui: PageActions;
  private initial: string = '';
  constructor(host: RoutineHost, ui: PageActions) { this.host = host; this.ui = ui; }
  private signature(): string {
    const state = this.host.state;
    return JSON.stringify({ title: state.noteTitle, body: state.noteBody, link: state.noteLink });
  }
  list(): NoteRecord[] {
    const state = this.host.state;
    return NoteQueries.list(this.host.snapshot(),state.workspace === 'notes' ? state.noteContext : undefined,
      state.noteFilter,state.noteSearch);
  }
  label(link: NoteLink | undefined): string { return NoteQueries.label(this.host.snapshot(),link); }
  selectSection(section: string): void {
    if (this.host.state.mutationBusy) { return; }
    this.ui.batch.exit(); this.host.state.recordSection = section;
  }
  openFor(kind: string, id: number): void {
    if (this.host.state.mutationBusy || !this.host.state.dataReady) { return; }
    const link: NoteLink | undefined = NoteQueries.resolve(this.host.snapshot(),kind,id);
    if (!link) { this.ui.feedback.toast('关联对象已删除，便签仍可在记录页查看'); return; }
    this.host.state.noteContext = link; this.host.state.noteFilter = '全部'; this.host.state.noteSearch = '';
    this.host.state.actionMenuId = -1; this.host.state.editingHabitId = -1;
    this.host.openWorkspace('notes');
  }
  edit(note?: NoteRecord): void {
    const state = this.host.state;
    if (state.mutationBusy || !state.dataReady || note?.deletedAt !== undefined) { return; }
    state.noteEditId = note?.id ?? -1; state.noteExpected = note?.updatedAt ?? -1;
    state.noteTitle = note?.title ?? ''; state.noteBody = note?.body ?? '';
    const link: NoteLink | undefined = note ? note.link : state.workspace === 'notes' ? state.noteContext : undefined;
    state.noteLink = link ? { kind: link.kind, id: link.id, title: link.title } : undefined;
    state.noteLinkPicking = false; state.noteLinkSearch = ''; state.noteError = ''; state.notice = '';
    state.noteEditing = true; this.initial = this.signature(); this.ui.dialogue.dismissFeedback();
  }
  choose(link?: NoteLink): void {
    this.host.state.noteLink = link; this.host.state.noteLinkPicking = false; this.host.state.noteLinkSearch = '';
  }
  requestClose(): void {
    if (this.host.state.mutationBusy) { return; }
    if (this.signature() !== this.initial) {
      this.ui.feedback.confirm('note-discard','便签有未保存的修改，确认放弃这些修改？');
    } else { this.host.state.noteEditing = false; this.host.getUIContext().getFocusController().clearFocus(); }
  }
  async save(): Promise<void> {
    const state = this.host.state;
    state.noteError = '';
    const saved: boolean = await this.host.mutate(async (): Promise<RoutineSnapshot> =>
      NoteCommands.save(this.host.snapshot(),state.noteEditId,state.noteTitle,state.noteBody,
        state.noteLink,state.noteExpected,Date.now()),false);
    if (saved) {
      state.noteEditing = false; state.noteLinkPicking = false;
      state.noteFilter = state.noteFilter === '回收站' || (state.noteFilter === '随笔' && state.noteLink) ||
        (state.noteFilter === '关联' && !state.noteLink) ? '全部' : state.noteFilter;
      state.noteSearch = ''; this.host.getUIContext().getFocusController().clearFocus();
      this.ui.feedback.toast('便签已保存');
    } else { state.noteError = state.notice || '便签尚未保存'; }
  }
  request(note: NoteRecord, operation: string): void {
    this.host.state.pendingNoteId = note.id;
    this.ui.feedback.confirm(`note-${operation}`,operation === 'purge' ? '永久删除这条便签？此操作无法撤回。' :
      `将“${note.title}”移到便签回收站？关联事项不会改变。`);
  }
  async restore(note: NoteRecord): Promise<void> {
    await this.host.mutate(async (): Promise<RoutineSnapshot> =>
      NoteCommands.lifecycle(this.host.snapshot(),note.id,'restore',Date.now()),false);
  }
  async confirm(operation: string): Promise<void> {
    if (operation === 'note-discard') {
      this.host.state.noteEditing = false; this.host.state.noteLinkPicking = false;
      this.host.getUIContext().getFocusController().clearFocus(); this.host.state.pendingConfirm = ''; return;
    }
    if (!['note-delete','note-purge'].includes(operation)) { return; }
    const saved: boolean = await this.host.mutate(async (): Promise<RoutineSnapshot> =>
      NoteCommands.lifecycle(this.host.snapshot(),this.host.state.pendingNoteId,operation.slice(5),Date.now()),false);
    if (saved) { this.host.state.pendingConfirm = ''; this.host.state.pendingNoteId = -1; }
  }
}
