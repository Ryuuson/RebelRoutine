import { HabitRecord, TraitPoints, TraitTotal } from '../data/RoutineModel';

export function makeTraitTotal(key: string, score: number): TraitTotal {
  return { key, score };
}

export function makeHabitRecord(id: number, day: string, title: string, subtitle: string, done: boolean,
  awardedTraits: string[], assignedTraits?: string[], assignedPoints?: TraitPoints[], awardedPoints?: TraitPoints[]): HabitRecord {
  return { id, day, title, subtitle, done, awardedTraits, assignedTraits, assignedPoints, awardedPoints };
}

export interface HistoryEntry {
  id: number;
  day: string;
  title: string;
  subtitle: string;
  action: boolean;
}

export interface HistoryGroup {
  day: string;
  entries: HistoryEntry[];
}
