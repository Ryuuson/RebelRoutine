import { RoutineSnapshot } from './RoutineModel';
import { NoteRecord, NoteLink } from './NoteModel';

export class NoteQueries {
  static same(a: NoteLink | undefined, b: NoteLink | undefined): boolean {
    return a === undefined ? b === undefined : b !== undefined && a.kind === b.kind && a.id === b.id;
  }
  static resolve(state: RoutineSnapshot, kind: string, id: number): NoteLink | undefined {
    if (kind === 'habit') {
      const item = state.habits.find((item) => item.id === id && item.deletedAt === undefined);
      return item ? { kind, id, title: item.title } : undefined;
    }
    if (kind === 'action') {
      const item = state.actions.find((item) => item.id === id && item.deletedAt === undefined);
      return item ? { kind, id, title: item.text } : undefined;
    }
    if (kind === 'commission') {
      const item = state.m2?.goals.find((item) => item.id === id);
      return item ? { kind, id, title: item.title } : undefined;
    }
    return undefined;
  }
  static label(state: RoutineSnapshot, link: NoteLink | undefined): string {
    if (!link) { return '独立随笔'; }
    const target: NoteLink | undefined = NoteQueries.resolve(state,link.kind,link.id);
    const type: string = link.kind === 'commission' ? '委托' : link.kind === 'action' ? '行动' : '事项';
    return `${type} · ${target?.title ?? link.title}${target ? '' : '（已删除或不存在）'}`;
  }
  static targets(state: RoutineSnapshot, query: string): NoteLink[] {
    const targets: NoteLink[] = [];
    state.habits.filter((item) => item.deletedAt === undefined).forEach((item) =>
      targets.push({ kind: 'habit', id: item.id, title: item.title }));
    state.actions.filter((item) => item.deletedAt === undefined).forEach((item) =>
      targets.push({ kind: 'action', id: item.id, title: item.text }));
    state.m2?.goals.forEach((item) => targets.push({ kind: 'commission', id: item.id, title: item.title }));
    const keyword: string = query.trim().toLocaleLowerCase();
    return targets.filter((target: NoteLink) => !keyword || target.title.toLocaleLowerCase().includes(keyword));
  }
  static list(state: RoutineSnapshot, context: NoteLink | undefined, filter: string, query: string): NoteRecord[] {
    const keyword: string = query.trim().toLocaleLowerCase();
    return (state.notes ?? []).filter((note: NoteRecord) =>
      (filter === '回收站' ? note.deletedAt !== undefined : note.deletedAt === undefined) &&
      (!context || NoteQueries.same(note.link,context)) &&
      (filter !== '随笔' || !note.link) && (filter !== '关联' || !!note.link) &&
      (!keyword || `${note.title}\n${note.body}\n${NoteQueries.label(state,note.link)}`.toLocaleLowerCase().includes(keyword)))
      .sort((a: NoteRecord,b: NoteRecord) => b.updatedAt-a.updatedAt || b.id-a.id);
  }
}
