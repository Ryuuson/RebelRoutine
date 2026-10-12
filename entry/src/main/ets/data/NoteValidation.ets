import { NoteRecord, NoteLink } from './NoteModel';

export class NoteValidation {
  static link(link: NoteLink | undefined): void {
    if (link === undefined) { return; }
    if (!link || !['habit','action','commission'].includes(link.kind) || !Number.isSafeInteger(link.id) || link.id < 0 ||
      typeof link.title !== 'string' || !link.title.trim()) { throw new Error('便签关联无效'); }
  }
  static validate(notes: NoteRecord[] | undefined): void {
    if (notes === undefined) { return; }
    if (!Array.isArray(notes)) { throw new Error('便签数据无效'); }
    const ids: number[] = [];
    notes.forEach((note: NoteRecord) => {
      if (!note || !Number.isSafeInteger(note.id) || note.id < 0 || ids.includes(note.id) ||
        typeof note.title !== 'string' || !note.title.trim() || note.title.length > 120 ||
        typeof note.body !== 'string' || note.body.length > 100000 ||
        !Number.isSafeInteger(note.createdAt) || note.createdAt < 0 ||
        !Number.isSafeInteger(note.updatedAt) || note.updatedAt < note.createdAt ||
        (note.deletedAt !== undefined && (!Number.isSafeInteger(note.deletedAt) || note.deletedAt < 0))) {
        throw new Error('便签内容或时间无效');
      }
      ids.push(note.id); NoteValidation.link(note.link);
    });
  }
}
