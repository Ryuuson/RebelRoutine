import { ActionRecord, HabitRecord, PinnedTask, TraitPoints, TraitTotal } from '../data/RoutineStore';
import { TRAIT_DEFINITIONS, TraitDefinition } from '../data/TraitAnalyzer';
import { RoutineEngine } from '../data/RoutineEngine';
import { yesterdayKey, dateKey, offsetDay, humanDate } from './DayUtil';
import { HistoryEntry } from './RecordUtil';
import { CommissionAward } from '../data/CommissionModel';
import { RoutineHost } from './RoutineHost';

import { PageActions } from './PageActions';

export class Queries {
  private readonly host: RoutineHost;
  private readonly ui: PageActions;
  constructor(host: RoutineHost, ui: PageActions) { this.host = host; this.ui = ui; }
  private historyCache: HistoryEntry[] = [];
  todayHabits(habits: HabitRecord[] = this.host.state.habits, today: string = this.host.state.today): HabitRecord[] {
    return habits.filter((habit: HabitRecord) => habit.day === today && RoutineEngine.visible(habit));
  }

  overdueCount(habits: HabitRecord[] = this.host.state.habits, today: string = this.host.state.today): number {
    return habits.filter((item: HabitRecord) => RoutineEngine.bucket(item, today) === '待处理').length;
  }

  recordDays(today: string = this.host.state.today, limit: number = this.host.state.historyLimit, target: string =
    this.host.state.recordTargetDay, epoch: number = this.host.state.renderEpoch): string[] {
    const days: string[] = Array.from(new Set([...this.historyEntries().map((entry: HistoryEntry) => entry.day),
      ...(this.host.state.selectionPage ? [] : this.commissionReceipts().map((award: CommissionAward) => award.day))])).sort().reverse();
    return target ? days.filter((day: string) => day === target) : days.filter((day: string) => day >= offsetDay(today, 1 - limit));
  }

  recordsFor(day: string): HistoryEntry[] { return this.historyEntries().filter((entry: HistoryEntry) => entry.day === day); }

  computeHistory(): HistoryEntry[] {
    const tasks: HistoryEntry[] = this.host.state.habits.filter((habit: HabitRecord) => habit.done && habit.deletedAt === undefined).map((habit:
      HabitRecord): HistoryEntry => ({
      id: habit.id, day: habit.activityDay ?? habit.day ?? '', title: habit.title,
      subtitle: habit.commissionId === undefined ? habit.subtitle : `${habit.progressValue ?? 1} ${
        this.host.state.m2?.goals.find((goal) => goal.id === habit.commissionId)?.unit ?? ''} · ${habit.subtitle}`, action: false
    }));
    const actions: HistoryEntry[] = this.host.state.actions.filter((record: ActionRecord) => record.deletedAt === undefined).map((record:
      ActionRecord): HistoryEntry => ({
      id: record.id, day: dateKey(new Date(record.createdAt)), title: record.text,
      subtitle: record.traits.map((key: string) => this.traitLabel(key)).join(' / '), action: true
    }));
    return [...tasks, ...actions].sort((a: HistoryEntry, b: HistoryEntry) => {
      if (a.day !== b.day) {
        return a.day < b.day ? 1 : -1;
      }
      return b.id - a.id;
    });
  }

  traitScore(key: string, totals: TraitTotal[] = this.host.state.traitTotals): number {
    const total = totals.find((item: TraitTotal) => item.key === key);
    return total ? total.score : 0;
  }

  traitRank(key: string, totals: TraitTotal[] = this.host.state.traitTotals): number {
    return Math.min(5, Math.floor(this.traitScore(key, totals) / (this.rankThreshold(2) - this.rankThreshold(1))) + 1);
  }

  rankName(key: string, totals: TraitTotal[] = this.host.state.traitTotals): string {
    const rank = this.traitRank(key, totals);
    if (key === 'knowledge') {
      return ['才疏学浅', '勤奋好学', '知识分子', '博学多闻', '百科字典'][rank - 1];
    }
    if (key === 'proficiency') {
      return ['笨手笨脚', '普普通通', '专业职人', '专业匠人', '点石成金'][rank - 1];
    }
    if (key === 'charm') {
      return ['一般程度', '令人在意', '潜力十足', '领袖魅力', '超凡脱俗'][rank - 1];
    }
    if (key === 'kindness') {
      return ['不甚关心', '倾听高手', '善解人意', '乐于助人', '圣母慈爱'][rank - 1];
    }
    return ['身心俱疲', '元气初显', '神清气爽', '身强体健', '生生不息'][rank - 1];
  }

  traitLabel(key: string): string {
    if (key === 'thought') {
      return '思想（旧）';
    }
    const definition = TRAIT_DEFINITIONS.find((item: TraitDefinition) => item.key === key);
    return definition ? definition.label : key;
  }

  validTraitKeys(keys: string[]): string[] {
    return TRAIT_DEFINITIONS.filter((trait: TraitDefinition) => keys.includes(trait.key))
      .map((trait: TraitDefinition) => trait.key);
  }

  assignedSelection(keys: string[]): string[] | undefined {
    return keys.includes('auto') ? undefined : this.validTraitKeys(keys);
  }

  pointAmount(amounts: TraitPoints[], key: string): number {
    const value: number = amounts.find((item: TraitPoints) => item.key === key)?.points ?? 1;
    return Number.isFinite(value) ? Math.max(1, Math.floor(value)) : 1;
  }

  normalizedPoints(keys: string[], amounts: TraitPoints[]): TraitPoints[] {
    return keys.map((key: string): TraitPoints => ({ key, points: this.pointAmount(amounts, key) }));
  }

  pickerHeight(target: string, selection: string[] = this.ui.draft.selectionFor(target)): number {
    return 42 * (selection.includes('auto') ? 0 : selection.length);
  }

  traitIcon(trait: TraitDefinition): Resource {
    return $r(`app.media.${trait.icon}`);
  }

  libraryHabits(habits: HabitRecord[] = this.host.state.habits, today: string = this.host.state.today, filter: string =
    '全部'): HabitRecord[] {
    return habits.filter((item: HabitRecord) => {
      return !item.done && RoutineEngine.visible(item) && (filter === '全部' || RoutineEngine.bucket(item, today) === filter);
    }).sort((a: HabitRecord, b: HabitRecord) => b.id - a.id);
  }

  collectionHabits(habits: HabitRecord[] = this.host.state.habits, today: string = this.host.state.today, filter: string =
    this.host.state.libraryFilter): HabitRecord[] {
    return habits.filter((item: HabitRecord) => filter === '旧隐藏事项' ?
      item.deletedAt === undefined && !item.done && !!(item.cancelled || item.archived) : RoutineEngine.bucket(item, today) === filter)
      .sort((a: HabitRecord, b: HabitRecord) => b.id - a.id);
  }

  collectionEmpty(habits: HabitRecord[] = this.host.state.habits, today: string = this.host.state.today, filter: string =
    this.host.state.libraryFilter, actions: ActionRecord[] = this.host.state.actions): boolean {
    return this.collectionHabits(habits, today, filter).length === 0 && !(filter === '回收站' && actions.some((item: ActionRecord) => item.deletedAt
      !== undefined));
  }

  cacheHistory(): void { this.historyCache = this.computeHistory(); }

  historyEntries(): HistoryEntry[] {
    const trait: string = this.host.state.recordTargetTrait;
    const goalId: number = this.host.state.recordTargetCommission;
    const records: HistoryEntry[] = goalId < 0 ? this.historyCache : this.historyCache.filter((entry: HistoryEntry) => {
      const id: number | undefined = this.host.state.habits.find((item: HabitRecord) => !entry.action && item.id === entry.id)?.commissionId;
      return id === goalId || this.host.state.m2?.goals.some((goal) => goal.id === id && goal.parentId === goalId);
    });
    return trait ? records.filter((entry: HistoryEntry) =>
      this.entryRewards(entry, this.host.state.habits, this.host.state.actions).some((point: TraitPoints) => point.key === trait && point.points > 0)) :
      records;
  }
  commissionReceipts(): CommissionAward[] {
    const s = this.host.state;
    return s.m2?.awards.filter((award: CommissionAward) => award.active && award.points.length > 0 &&
      (!s.recordTargetTrait || award.points.some((point: TraitPoints) => point.key === s.recordTargetTrait)) &&
      (s.recordTargetCommission < 0 || award.goalId === s.recordTargetCommission ||
        s.m2?.goals.some((goal) => goal.id === award.goalId && goal.parentId === s.recordTargetCommission))) ?? [];
  }

  pinnedAdded(item: PinnedTask, habits: HabitRecord[] = this.host.state.habits, today: string = this.host.state.today): boolean {
    return this.todayHabits(habits, today).some((habit: HabitRecord) => habit.title.trim().toLowerCase() === item.title.trim().toLowerCase());
  }

  hasYesterday(habits: HabitRecord[], today: string): boolean {
    return habits.some((item: HabitRecord) => item.day === yesterdayKey() && RoutineEngine.visible(item));
  }

  quickSummary(day: string, done: boolean, keys: string[], points: TraitPoints[], today: string): string {
    const parts: string[] = [];
    if (done) { parts.push('已做'); }
    if (day === '-') { parts.push('不安排'); }
    else if (day && day !== today) { parts.push(day === offsetDay(today, 1) ? '明天' : day === offsetDay(today, -1) ? '昨天' : humanDate(day)); }
    if (!keys.includes('auto')) { parts.push(keys.length ? keys.map((key: string) =>
      this.traitLabel(key)).join(' / ') : '不影响成长'); }
    return parts.join(' · ');
  }

  todaySorted(habits: HabitRecord[], today: string): HabitRecord[] {
    return this.todayHabits(habits, today).sort((a: HabitRecord, b: HabitRecord) => Number(a.done) - Number(b.done));
  }

  tasksIn(group: string, habits: HabitRecord[], today: string): HabitRecord[] {
    return this.libraryHabits(habits, today, group).sort((a: HabitRecord, b: HabitRecord) => (a.day ?? '').localeCompare(b.day ?? '') || b.id - a.id);
  }



  entryRewards(entry: HistoryEntry, habits: HabitRecord[], actions: ActionRecord[]): TraitPoints[] {
    if (entry.action) { return (actions.find((item: ActionRecord) => item.id === entry.id)?.traits ?? []).map((key: string): TraitPoints => ({
      key, points: 1 })); }
    const item: HabitRecord | undefined = habits.find((habit: HabitRecord) => habit.id === entry.id);
    return (item?.awardedTraits ?? []).map((key: string): TraitPoints => ({ key, points: this.pointAmount(item?.awardedPoints ?? [], key) }));
  }

  dayRewards(day: string, habits: HabitRecord[], actions: ActionRecord[]): TraitPoints[] {
    const points: TraitPoints[] = [];
    this.recordsFor(day).forEach((entry: HistoryEntry) => this.entryRewards(entry, habits, actions).forEach((reward: TraitPoints) => {
      const found: TraitPoints | undefined = points.find((point: TraitPoints) => point.key === reward.key);
      if (found) { found.points += reward.points; } else { points.push({ key: reward.key, points: reward.points }); }
    })); return points;
  }

  hasEarlier(today: string, limit: number, epoch: number): boolean {
    return this.historyEntries().some((entry: HistoryEntry) => entry.day < offsetDay(today, 1 - limit));
  }

  rankThreshold(rank: number): number { return (rank - 1) * 5; }

  rankProgress(key: string, totals: TraitTotal[]): number {
    const rank: number = this.traitRank(key, totals);
    if (rank === 5) { return 1; }
    const lower: number = this.rankThreshold(rank); const upper: number = this.rankThreshold(rank + 1);
    return (this.traitScore(key, totals) - lower) / (upper - lower);
  }

  nextRankText(key: string, totals: TraitTotal[]): string {
    const rank: number = this.traitRank(key, totals);
    return rank === 5 ? '已满阶' : `再 ${this.rankThreshold(rank + 1) - this.traitScore(key, totals)} 点升阶`;
  }

  hasHidden(habits: HabitRecord[]): boolean {
    return habits.some((item: HabitRecord) => item.deletedAt === undefined && !item.done && !!(item.cancelled || item.archived));
  }

  canUndo(item: HabitRecord): boolean {
    return item.done && item.day !== undefined && !item.archived && !item.cancelled && RoutineEngine.visible(item);
  }

  selectedHabit(id: number = this.host.state.actionMenuId, habits: HabitRecord[] = this.host.state.habits): HabitRecord | undefined {
    return habits.find((item: HabitRecord) => item.id === id);
  }

  canOperate(item: HabitRecord, operation: string): boolean {
    if (item.deletedAt !== undefined) { return operation === 'restore' || operation === 'purge'; }
    if (!item.done && (item.cancelled || item.archived)) { return operation === 'reopen' || operation === 'delete'; }
    if (operation === 'undo') { return this.canUndo(item); }
    if (operation === 'complete' || operation === 'focus') { return !item.done; }
    return operation === 'edit' || operation === 'delete';
  }

  legacyRemoval(item: ActionRecord): number { return RoutineEngine.removal(this.host.snapshot(), item.traits, []).reduce((sum: number, point:
    TraitPoints) => sum + point.points, 0); }

  deleteLabel(item: HabitRecord): string {
    return '删除';
  }
}
