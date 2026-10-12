import { RoutineSnapshot } from './RoutineModel';
import { NoteRecord, NoteLink } from './NoteModel';
import { NoteQueries } from './NoteQueries';
import { RoutineEngine } from './RoutineEngine';
import { NoteValidation } from './NoteValidation';

export class NoteCommands {
  static save(state: RoutineSnapshot, id: number, title: string, body: string, link: NoteLink | undefined,
    expected: number, now: number): RoutineSnapshot {
    if (!title.trim() && !body.trim()) { throw new Error('先写些内容，再保存便签'); }
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    if (!next.notes) { next.notes = []; }
    const existing: NoteRecord | undefined = next.notes.find((note: NoteRecord) => note.id === id);
    if (id >= 0 && (!existing || existing.deletedAt !== undefined || existing.updatedAt !== expected)) {
      throw new Error('便签已改变，请重新打开后编辑');
    }
    NoteValidation.link(link);
    const target: NoteLink | undefined = link ? NoteQueries.resolve(next,link.kind,link.id) : undefined;
    if (link && !target && (!existing || !NoteQueries.same(existing.link,link))) { throw new Error('关联对象已不存在'); }
    const note: NoteRecord = {
      id: existing?.id ?? Math.max(now,...next.notes.map((note: NoteRecord) => note.id+1)),
      title: title.trim() || body.trim().split('\n')[0].slice(0,60), body,
      createdAt: existing?.createdAt ?? now, updatedAt: Math.max(now,(existing?.updatedAt ?? now-1)+1), link: target ?? link
    };
    if (existing) { next.notes[next.notes.indexOf(existing)] = note; } else { next.notes.push(note); }
    NoteValidation.validate(next.notes); return next;
  }
  static lifecycle(state: RoutineSnapshot, id: number, operation: string, now: number): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    const note: NoteRecord | undefined = next.notes?.find((item: NoteRecord) => item.id === id);
    if (!note) { throw new Error('便签不存在'); }
    if (operation === 'delete' && note.deletedAt === undefined) { note.deletedAt = now; }
    else if (operation === 'restore' && note.deletedAt !== undefined) { note.deletedAt = undefined; }
    else if (operation === 'purge' && note.deletedAt !== undefined) { next.notes = next.notes!.filter((item) => item.id !== id); }
    else { throw new Error('便签当前状态不可执行该操作'); }
    note.updatedAt = Math.max(now,note.updatedAt+1);
    return next;
  }
}
