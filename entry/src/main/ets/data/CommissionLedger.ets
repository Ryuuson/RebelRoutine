import { RoutineSnapshot, TraitPoints, RecordRef, TraitTotal } from './RoutineModel';
import { CommissionData, LedgerEntry } from './CommissionModel';

export class CommissionLedger {
  static initialize(state: RoutineSnapshot): CommissionData {
    return { schema: 1, goals: [], awards: [], repeats: [], ledger: state.traitTotals.map((total: TraitTotal, index: number): LedgerEntry => ({
      id: index + 1, kind: 'opening', day: state.activeDay, createdAt: Date.now(),
      points: [{ key: total.key, points: total.score }], refs: []
    })) };
  }
  static append(state: RoutineSnapshot, kind: string, day: string, points: TraitPoints[], refs: RecordRef[] = [], awardKey?: string): void {
    const data: CommissionData = state.m2!;
    const changes: TraitPoints[] = points.filter((point: TraitPoints) => point.points !== 0);
    if (!changes.length) { return; }
    data.ledger.push({ id: data.ledger.reduce((max: number, item: LedgerEntry) => Math.max(max, item.id), 0) + 1,
      kind, day, createdAt: Date.now(), points: changes, refs, awardKey });
  }
  static recordChanges(before: RoutineSnapshot, after: RoutineSnapshot, day: string): void {
    const keys: string[] = Array.from(new Set([...before.traitTotals, ...after.traitTotals].map((t: TraitTotal) => t.key)));
    const changes: TraitPoints[] = keys.map((key: string): TraitPoints => ({ key,
      points: (after.traitTotals.find((t: TraitTotal) => t.key === key)?.score ?? 0) -
        (before.traitTotals.find((t: TraitTotal) => t.key === key)?.score ?? 0)
    }));
    const refs: RecordRef[] = [];
    Array.from(new Set([...before.habits, ...after.habits].map((item) => item.id))).forEach((id: number) => {
      if (JSON.stringify(before.habits.find((item) => item.id === id)) !== JSON.stringify(after.habits.find((item) => item.id === id))) {
        refs.push({ id, action: false });
      }
    });
    Array.from(new Set([...before.actions, ...after.actions].map((item) => item.id))).forEach((id: number) => {
      if (JSON.stringify(before.actions.find((item) => item.id === id)) !== JSON.stringify(after.actions.find((item) => item.id === id))) {
        refs.push({ id, action: true });
      }
    });
    CommissionLedger.append(after, 'record', day, changes, refs);
  }
  static balances(data: CommissionData): TraitPoints[] {
    const balances: TraitPoints[] = [];
    data.ledger.forEach((entry: LedgerEntry) => entry.points.forEach((point: TraitPoints) => {
      const total: TraitPoints | undefined = balances.find((value: TraitPoints) => value.key === point.key);
      if (total) { total.points += point.points; } else { balances.push({ key: point.key, points: point.points }); }
    }));
    return balances;
  }
  static applyTotals(state: RoutineSnapshot): void {
    const balances: TraitPoints[] = CommissionLedger.balances(state.m2!);
    state.traitTotals = balances.map((point: TraitPoints): TraitTotal => ({ key: point.key, score: Math.max(0, point.points) }));
  }
}
