export interface NoteLink { kind: string; id: number; title: string; }
export interface NoteRecord {
  id: number;
  title: string;
  body: string;
  createdAt: number;
  updatedAt: number;
  link?: NoteLink;
  deletedAt?: number;
}
