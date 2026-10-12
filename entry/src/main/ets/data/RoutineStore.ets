import { fileIo as fs } from '@kit.CoreFileKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

import { ActionRecord, HabitRecord, PinnedTask, TraitPoints, TraitTotal, RoutineSnapshot, RoutineBackup } from './RoutineModel';
import { relationalStore } from '@kit.ArkData';
import { picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { RoutineEngine } from './RoutineEngine';
import { CommissionEngine } from './CommissionEngine';
import { LocalTraitAnalyzer, TRAIT_DEFINITIONS, TraitDefinition, TraitHit } from './TraitAnalyzer';

export { ActionRecord, HabitRecord, PinnedTask, TraitPoints, TraitTotal, RoutineSnapshot } from './RoutineModel';

const STORE_NAME: string = 'rebel_routine';
const HABITS_KEY: string = 'habits';
const ACTIONS_KEY: string = 'actions';
const TRAITS_KEY: string = 'traits';
const ACTIVE_DAY_KEY: string = 'active_day';
const PINNED_KEY: string = 'pinned_tasks';

export class RoutineStore {
  private readonly context: common.UIAbilityContext;

  private database?: relationalStore.RdbStore;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  private async db(): Promise<relationalStore.RdbStore> {
    if (!this.database) {
      this.database = await relationalStore.getRdbStore(this.context, {
        name: 'routine_v2.db', securityLevel: relationalStore.SecurityLevel.S1
      });
      await this.database.executeSql('CREATE TABLE IF NOT EXISTS app_state (id INTEGER PRIMARY KEY, payload TEXT NOT NULL)');
    }
    return this.database;
  }

  private async readRow(id: number): Promise<RoutineSnapshot | undefined> {
    const db: relationalStore.RdbStore = await this.db();
    const result: relationalStore.ResultSet = await db.querySql('SELECT payload FROM app_state WHERE id = ?', [id]);
    try {
      return result.goToFirstRow() ? RoutineEngine.validate(RoutineEngine.migrate(JSON.parse(result.getString(0)) as RoutineSnapshot)) : undefined;
    } finally { result.close(); }
  }

  async loadSnapshot(today: string): Promise<RoutineSnapshot> {
    const existing: RoutineSnapshot | undefined = await this.readRow(1);
    if (existing) { return existing; }
    const prefs: preferences.Preferences = await preferences.getPreferences(this.context, STORE_NAME);
    // Preserve exact legacy values before parsing or doing any migration write.
    const raw = await prefs.getAll();
    this.writeFile(`${this.context.filesDir}/legacy-preferences-before-m1.json`, JSON.stringify(raw), true);
    const savedDay: string = await this.loadActiveDay();
    const day: string = RoutineEngine.validDay(savedDay) ? savedDay : today;
    const habits: HabitRecord[] = await this.loadHabits([]);
    const pinnedTasks: PinnedTask[] = await this.loadPinnedTasks();
    const analyzer: LocalTraitAnalyzer = new LocalTraitAnalyzer();
    const migrated: HabitRecord[] = [];
    for (const habit of habits) {
      const item: HabitRecord = JSON.parse(JSON.stringify(habit)) as HabitRecord;
      item.day = habit.day ?? day;
      if (item.done) {
        if (item.activityDay === undefined) { item.activityDay = item.day; item.inferredDay = true; }
        if (item.awardedTraits === undefined) {
          item.awardedTraits = item.assignedTraits ?? (await analyzer.analyzeLegacy(`${item.title} ${item.subtitle}`)).hits.map((hit: TraitHit) => hit.key);
        }
        item.awardedPoints = item.awardedTraits.map((key: string): TraitPoints => ({ key, points: RoutineEngine.amount(item.awardedPoints ??
          item.assignedPoints ?? [], key) }));
      }
      migrated.push(item);
    }
    const legacy: HabitRecord[] = habits.filter((item: HabitRecord) => item.day === undefined);
    const state: RoutineSnapshot = {
      version: 2, revision: 0, habits: migrated,
      pinnedTasks: pinnedTasks.length > 0 ? pinnedTasks : legacy.map((item: HabitRecord): PinnedTask => ({
        id: item.id, title: item.title, subtitle: item.subtitle,
        assignedTraits: item.assignedTraits, assignedPoints: item.assignedPoints
      })),
      actions: await this.loadActions(),
      traitTotals: await this.loadTraits(TRAIT_DEFINITIONS.map((trait: TraitDefinition): TraitTotal => ({ key: trait.key, score: 0 }))),
      activeDay: today
    };
    await this.saveSnapshot(state);
    return state;
  }

  async loadM2Snapshot(today: string): Promise<RoutineSnapshot> {
    const state: RoutineSnapshot = await this.loadSnapshot(today);
    if (state.m2) { return state; }
    this.writeFile(`${this.context.filesDir}/snapshot-before-m2.json`, JSON.stringify(state), true);
    const next: RoutineSnapshot = CommissionEngine.bootstrap(state);
    await this.saveSnapshot(next); return next;
  }

  async saveSnapshot(state: RoutineSnapshot): Promise<void> {
    const checked: RoutineSnapshot = RoutineEngine.validate(state);
    const db: relationalStore.RdbStore = await this.db();
    db.beginTransaction();
    try {
      await db.executeSql('INSERT OR REPLACE INTO app_state (id, payload) VALUES (?, ?)', [1, JSON.stringify(checked)]);
      db.commit();
    } catch (error) { db.rollBack(); throw new Error(String(error)); }
  }

  /** @throws {Error} File, picker or database failures propagate to the caller's recovery handler. */
  async replaceSnapshot(state: RoutineSnapshot): Promise<void> {
    const checked: RoutineSnapshot = RoutineEngine.validate(state);
    const current: string | undefined = await this.rawRow();
    const db: relationalStore.RdbStore = await this.db();
    db.beginTransaction();
    try {
      if (current !== undefined) { await db.executeSql('INSERT OR REPLACE INTO app_state (id, payload) VALUES (?, ?)', [2, current]); }
      await db.executeSql('INSERT OR REPLACE INTO app_state (id, payload) VALUES (?, ?)', [1, JSON.stringify(checked)]);
      db.commit();
    } catch (error) { db.rollBack(); throw new Error(String(error)); }
  }

  /** @throws {Error} Invalid or unavailable previous snapshots leave the current row unchanged. */
  async previousRestore(): Promise<RoutineSnapshot> {
    const previous: RoutineSnapshot | undefined = await this.readRow(2);
    if (!previous) { throw new Error('暂无可撤回的恢复'); }
    await this.replaceSnapshot(previous);
    return previous;
  }

  async previousM2Restore(): Promise<RoutineSnapshot> {
    const previous: RoutineSnapshot | undefined = await this.readRow(2);
    if (!previous) { throw new Error('暂无可撤回的恢复'); }
    const next: RoutineSnapshot = CommissionEngine.bootstrap(previous);
    await this.replaceSnapshot(next); return next;
  }

  private writeFile(uri: string, text: string, exclusive: boolean = false): void {
    if (exclusive && fs.accessSync(uri)) { return; }
    const file: fs.File = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try { fs.writeSync(file.fd, text); fs.fsyncSync(file.fd); } finally { fs.closeSync(file); }
  }

  async exportFile(state: RoutineSnapshot, csv: boolean): Promise<boolean> {
    const view: picker.DocumentViewPicker = new picker.DocumentViewPicker(this.context);
    const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    options.newFileNames = [`RebelRoutine-${Date.now()}.${csv ? 'csv' : 'json'}`];
    options.fileSuffixChoices = csv ? ['CSV|.csv'] : ['完整备份|.json'];
    const uris: string[] = await view.save(options);
    if (uris.length === 0) { return false; }
    const backup: RoutineBackup = { format: 'RebelRoutine', exportedAt: Date.now(), state: RoutineEngine.validate(state) };
    this.writeFile(uris[0], csv ? RoutineEngine.csv(state) : JSON.stringify(backup, null, 2));
    return true;
  }

  /** @throws {Error} File, picker or database failures propagate to the caller's recovery handler. */
  async selectBackup(): Promise<RoutineSnapshot | undefined> {
    const view: picker.DocumentViewPicker = new picker.DocumentViewPicker(this.context);
    const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
    options.maxSelectNumber = 1;
    const uris: string[] = await view.select(options);
    if (uris.length === 0) { return undefined; }
    const file: fs.File = fs.openSync(uris[0], fs.OpenMode.READ_ONLY);
    try {
      const size: number = fs.statSync(file.fd).size;
      const bytes: Uint8Array = new Uint8Array(size);
      let total: number = 0;
      while (total < size) {
        const chunk: ArrayBuffer = new ArrayBuffer(size - total);
        const count: number = fs.readSync(file.fd, chunk);
        if (count <= 0) { throw new Error('备份文件未读取完整'); }
        bytes.set(new Uint8Array(chunk, 0, count), total); total += count;
      }
      return RoutineEngine.readBackup(util.TextDecoder.create('utf-8', { fatal: true }).decodeToString(bytes));
    } finally { fs.closeSync(file); }
  }

  /** @throws {Error} File, picker or database failures propagate to the caller's recovery handler. */
  private async rawRow(): Promise<string | undefined> {
    const db: relationalStore.RdbStore = await this.db();
    const result: relationalStore.ResultSet = await db.querySql('SELECT payload FROM app_state WHERE id = ?', [1]);
    try { return result.goToFirstRow() ? result.getString(0) : undefined; }
    finally { result.close(); }
  }

  /** @throws {Error} File, picker or database failures propagate to the caller's recovery handler. */
  async exportRaw(): Promise<boolean> {
    const raw: string | undefined = await this.rawRow();
    if (raw === undefined) { throw new Error('数据库中没有原始数据行；旧偏好仍保留在应用私有目录'); }
    const view: picker.DocumentViewPicker = new picker.DocumentViewPicker(this.context);
    const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
    options.newFileNames = [`RebelRoutine-raw-${Date.now()}.json`];
    const uris: string[] = await view.save(options);
    if (uris.length === 0) { return false; }
    this.writeFile(uris[0], raw); return true;
  }

  async loadHabits(fallback: HabitRecord[]): Promise<HabitRecord[]> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    const saved = await store.get(HABITS_KEY, '');
    if (typeof saved !== 'string' || saved.length === 0) {
      return fallback;
    }

    try {
      const parsed = JSON.parse(saved) as HabitRecord[];
      if (!Array.isArray(parsed)) { throw new Error('旧任务数据损坏'); }
      return parsed;
    } catch (error) { throw new Error(String(error)); }
  }

  async saveHabits(habits: HabitRecord[]): Promise<void> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    await store.put(HABITS_KEY, JSON.stringify(habits));
    await store.flush();
  }

  async loadPinnedTasks(): Promise<PinnedTask[]> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    const saved = await store.get(PINNED_KEY, '');
    if (typeof saved !== 'string' || saved.length === 0) {
      return [];
    }
    try {
      const parsed = JSON.parse(saved) as PinnedTask[];
      if (!Array.isArray(parsed)) { throw new Error('旧记录数据损坏'); }
      return parsed;
    } catch (error) { throw new Error(String(error)); }
  }

  async savePinnedTasks(tasks: PinnedTask[]): Promise<void> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    await store.put(PINNED_KEY, JSON.stringify(tasks));
    await store.flush();
  }

  async loadActions(): Promise<ActionRecord[]> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    const saved = await store.get(ACTIONS_KEY, '');
    if (typeof saved !== 'string' || saved.length === 0) {
      return [];
    }
    try {
      const parsed = JSON.parse(saved) as ActionRecord[];
      if (!Array.isArray(parsed)) { throw new Error('旧记录数据损坏'); }
      return parsed;
    } catch (error) { throw new Error(String(error)); }
  }

  async saveActions(actions: ActionRecord[]): Promise<void> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    await store.put(ACTIONS_KEY, JSON.stringify(actions));
    await store.flush();
  }

  async loadTraits(fallback: TraitTotal[]): Promise<TraitTotal[]> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    const saved = await store.get(TRAITS_KEY, '');
    if (typeof saved !== 'string' || saved.length === 0) {
      return fallback;
    }
    try {
      const parsed = JSON.parse(saved) as TraitTotal[];
      if (!Array.isArray(parsed)) { throw new Error('旧成长数据损坏'); }
      // 新增维度补初始值，已有分数和旧维度仍保留以支持历史撤销。
      const totals: TraitTotal[] = fallback.map((initial: TraitTotal): TraitTotal => {
        const existing = parsed.find((item: TraitTotal) => item.key === initial.key);
        return existing ?? initial;
      });
      return [...totals, ...parsed.filter((item: TraitTotal) =>
        !fallback.some((initial: TraitTotal) => initial.key === item.key))];
    } catch (error) { throw new Error(String(error)); }
  }

  async saveTraits(traits: TraitTotal[]): Promise<void> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    await store.put(TRAITS_KEY, JSON.stringify(traits));
    await store.flush();
  }

  async loadActiveDay(): Promise<string> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    const saved = await store.get(ACTIVE_DAY_KEY, '');
    return typeof saved === 'string' ? saved : '';
  }

  async saveActiveDay(day: string): Promise<void> {
    const store = await preferences.getPreferences(this.context, STORE_NAME);
    await store.put(ACTIVE_DAY_KEY, day);
    await store.flush();
  }
}
