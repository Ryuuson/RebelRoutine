import { TraitPoints, RecordRef } from './RoutineModel';

export interface CommissionStage { id: number; title: string; percent: number; keys: string[]; points: TraitPoints[]; }
export interface Commission {
  id: number; title: string; parentId?: number; deadline?: string;
  mode: string; target: number; unit: string; weekly: boolean;
  rewardMode: string; keys: string[]; points: TraitPoints[]; stages: CommissionStage[];
  createdAt: number; updatedAt: number;
}
export interface CommissionAward {
  key: string; goalId: number; stageId: number; period: string; day: string;
  title: string; threshold: number; points: TraitPoints[]; active: boolean;
}
export interface LedgerEntry {
  id: number; kind: string; day: string; createdAt: number;
  points: TraitPoints[]; refs: RecordRef[]; awardKey?: string;
}
export interface RepeatPlan {
  id: number; title: string; subtitle: string; rule: string; weekdays: number[];
  startDay: string; through: string; paused: boolean; usedDays: string[];
  goalId?: number; value: number; traits?: string[]; points: TraitPoints[];
}
export interface CommissionData {
  schema: number; goals: Commission[]; awards: CommissionAward[]; ledger: LedgerEntry[]; repeats: RepeatPlan[];
}
