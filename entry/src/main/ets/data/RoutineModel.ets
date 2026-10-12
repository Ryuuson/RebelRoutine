import { CommissionData, CommissionStage } from './CommissionModel';
import { NoteRecord } from './NoteModel';

export interface TraitPoints { key: string; points: number; }
export interface RecordRef { id: number; action: boolean; }
export interface BatchRequest { refs: RecordRef[]; operation: string; day?: string; }
export interface CompletionReward { id: number; keys: string[]; points: TraitPoints[]; }
export interface HabitRecord {
  id: number;
  day?: string;
  title: string;
  subtitle: string;
  done: boolean;
  awardedTraits?: string[];
  assignedTraits?: string[];
  assignedPoints?: TraitPoints[];
  awardedPoints?: TraitPoints[];
  activityDay?: string;
  createdAt?: number;
  updatedAt?: number;
  inferredDay?: boolean;
  cancelled?: boolean;
  archived?: boolean;
  deletedAt?: number;
  deletedPoints?: TraitPoints[];
  commissionId?: number;
  progressValue?: number;
  progressEntry?: boolean;
  commissionPoints?: TraitPoints[];
  commissionStages?: CommissionStage[];
  commissionParentPoints?: TraitPoints[];
  commissionParentStages?: CommissionStage[];
  repeatId?: number;
  repeatDay?: string;
}
export interface PinnedTask {
  id: number; title: string; subtitle: string;
  assignedTraits?: string[]; assignedPoints?: TraitPoints[];
}
export interface ActionRecord {
  id: number; text: string; summary: string; traits: string[]; createdAt: number;
  deletedAt?: number;
  deletedPoints?: TraitPoints[];
}
export interface TraitTotal { key: string; score: number; }
export interface RoutineSnapshot {
  notes?: NoteRecord[];
  m2?: CommissionData;
  version: number;
  revision: number;
  habits: HabitRecord[];
  pinnedTasks: PinnedTask[];
  actions: ActionRecord[];
  traitTotals: TraitTotal[];
  activeDay: string;
}
export interface RoutineBackup {
  format: string;
  exportedAt: number;
  state: RoutineSnapshot;
}
