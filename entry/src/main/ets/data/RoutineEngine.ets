import { HabitRecord, RoutineSnapshot, RoutineBackup, TraitPoints, TraitTotal } from './RoutineModel';
import { CommissionValidation } from './CommissionValidation';
import { NoteValidation } from './NoteValidation';

/** Pure record transitions. Persistence commits the returned snapshot before the UI adopts it. */
export class RoutineEngine {
  static migrate(raw: RoutineSnapshot): RoutineSnapshot {
    if (!raw || raw.version !== 2) { throw new Error('数据版本不支持，请保留原始数据并使用兼容版本恢复'); }
    return raw;
  }

  static localDay(date: Date): string {
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }

  static localTime(date: Date): string {
    return `${RoutineEngine.localDay(date)} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }
  static clone(state: RoutineSnapshot): RoutineSnapshot {
    return JSON.parse(JSON.stringify(state)) as RoutineSnapshot;
  }

  static validDay(day: string): boolean {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(day)) { return false; }
    const date: Date = new Date(`${day}T12:00:00`);
    return Number.isFinite(date.getTime()) && date.getFullYear() >= 1970 &&
      `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}` === day;
  }

  static visible(item: HabitRecord): boolean {
    return item.deletedAt === undefined && (item.done || (!item.cancelled && !item.archived));
  }

  static bucket(item: HabitRecord, today: string): string {
    if (item.deletedAt !== undefined) { return '回收站'; }
    if (item.done) { return '已完成'; }
    if (item.archived) { return '已归档'; }
    if (item.cancelled) { return '已取消'; }
    if (item.day === undefined) { return '未安排'; }
    return item.day < today ? '待处理' : item.day > today ? '未来' : '今天';
  }

  static amount(amounts: TraitPoints[], key: string): number {
    return amounts.find((item: TraitPoints) => item.key === key)?.points ?? 1;
  }

  static award(state: RoutineSnapshot, keys: string[], amounts: TraitPoints[], sign: number): void {
    keys.forEach((key: string) => {
      let total: TraitTotal | undefined = state.traitTotals.find((item: TraitTotal) => item.key === key);
      if (!total) { total = { key, score: 0 }; state.traitTotals.push(total); }
      total.score = Math.max(0, total.score + sign * RoutineEngine.amount(amounts, key));
    });
  }

  static removal(state: RoutineSnapshot, keys: string[], amounts: TraitPoints[]): TraitPoints[] {
    return keys.map((key: string): TraitPoints => ({ key,
      points: Math.min(state.traitTotals.find((item: TraitTotal) => item.key === key)?.score ?? 0,
        RoutineEngine.amount(amounts, key))
    })).filter((item: TraitPoints) => item.points > 0);
  }

  static complete(state: RoutineSnapshot, id: number, day: string, keys: string[], amounts: TraitPoints[]): RoutineSnapshot {
    if (!RoutineEngine.validDay(day)) { throw new Error('请输入有效日期（YYYY-MM-DD）'); }
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    const item: HabitRecord | undefined = next.habits.find((habit: HabitRecord) => habit.id === id);
    if (!item || !RoutineEngine.visible(item)) { throw new Error('事项不可操作'); }
    if (item.done) {
      RoutineEngine.award(next, item.awardedTraits ?? [], item.awardedPoints ?? [], -1);
      item.done = false;
      item.awardedTraits = []; item.awardedPoints = []; item.activityDay = undefined;
    } else {
      item.done = true; item.activityDay = day; item.inferredDay = false;
      item.awardedTraits = [...keys];
      item.awardedPoints = keys.map((key: string): TraitPoints => ({ key, points: RoutineEngine.amount(amounts, key) }));
      RoutineEngine.award(next, keys, item.awardedPoints, 1);
    }
    item.updatedAt = Date.now();
    return next;
  }

  static edit(state: RoutineSnapshot, edited: HabitRecord): RoutineSnapshot {
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    const index: number = next.habits.findIndex((item: HabitRecord) => item.id === edited.id);
    if (index < 0 || next.habits[index].deletedAt !== undefined) { throw new Error('事项不存在'); }
    const previous: HabitRecord = next.habits[index];
    if (previous.done) {
      const keys: string[] = Array.from(new Set([...(previous.awardedTraits ?? []), ...(edited.awardedTraits ?? [])]));
      keys.forEach((key: string) => {
        const before: number = previous.awardedTraits?.includes(key) ? RoutineEngine.amount(previous.awardedPoints ?? [], key) : 0;
        const after: number = edited.awardedTraits?.includes(key) ? RoutineEngine.amount(edited.awardedPoints ?? [], key) : 0;
        let total: TraitTotal | undefined = next.traitTotals.find((item: TraitTotal) => item.key === key);
        if (!total) { total = { key, score: 0 }; next.traitTotals.push(total); }
        total.score = Math.max(0, total.score + after - before);
      });
    }
    next.habits[index] = edited;
    return next;
  }

  static lifecycle(state: RoutineSnapshot, id: number, operation: string): RoutineSnapshot {
    if (!['delete', 'restore', 'purge', 'reopen'].includes(operation)) { throw new Error('不支持的事项状态操作'); }
    const next: RoutineSnapshot = RoutineEngine.clone(state);
    const item: HabitRecord | undefined = next.habits.find((habit: HabitRecord) => habit.id === id);
    if (!item) { throw new Error('事项不存在'); }
    if (operation === 'delete' && item.deletedAt === undefined) {
      if (item.done) {
        item.deletedPoints = RoutineEngine.removal(next, item.awardedTraits ?? [], item.awardedPoints ?? []);
        RoutineEngine.award(next, item.awardedTraits ?? [], item.awardedPoints ?? [], -1);
      }
      item.deletedAt = Date.now();
    } else if (operation === 'restore' && item.deletedAt !== undefined) {
      if (item.done) {
        const receipt: TraitPoints[] = item.deletedPoints ?? item.awardedPoints ?? (item.awardedTraits ?? []).map((key: string): TraitPoints =>
          ({ key, points: 1 }));
        RoutineEngine.award(next, receipt.map((point: TraitPoints) => point.key), receipt, 1);
      }
      item.deletedAt = undefined;
      item.deletedPoints = undefined;
    } else if (operation === 'purge' && item.deletedAt !== undefined) {
      next.habits = next.habits.filter((habit: HabitRecord) => habit.id !== id);
    } else if (item.deletedAt === undefined) {
      if (operation === 'reopen') { item.cancelled = false; item.archived = false; }
    }
    item.updatedAt = Date.now();
    return next;
  }

  static validatePoints(points: TraitPoints[] | undefined): void {
    if (points === undefined) { return; }
    if (!Array.isArray(points) || points.some((item: TraitPoints) => !item || typeof item.key !== 'string' ||
      !Number.isSafeInteger(item.points) || item.points < 1) ||
      new Set(points.map((item: TraitPoints) => item.key)).size !== points.length) {
      throw new Error('备份点数无效');
    }
  }

  static validateKeys(keys: string[] | undefined): void {
    if (keys !== undefined && (!Array.isArray(keys) || keys.some((key: string) => typeof key !== 'string') ||
      new Set(keys).size !== keys.length)) { throw new Error('备份维度无效'); }
  }

  static validate(state: RoutineSnapshot): RoutineSnapshot {
    if (!state || state.version !== 2 || !Number.isSafeInteger(state.revision) || state.revision < 0 ||
      !Array.isArray(state.habits) || !Array.isArray(state.actions) || !Array.isArray(state.pinnedTasks) ||
      !Array.isArray(state.traitTotals) || !RoutineEngine.validDay(state.activeDay)) { throw new Error('备份格式或版本不支持'); }
    const ids: number[] = [];
    state.habits.forEach((item: HabitRecord) => {
      if (!item || !Number.isSafeInteger(item.id) || item.id < 0 || ids.includes(item.id) ||
        typeof item.title !== 'string' || !item.title.trim() || typeof item.subtitle !== 'string' || typeof item.done !== 'boolean' ||
        (item.day !== undefined && !RoutineEngine.validDay(item.day)) ||
        (item.activityDay !== undefined && !RoutineEngine.validDay(item.activityDay)) ||
        (item.cancelled !== undefined && typeof item.cancelled !== 'boolean') ||
        (item.archived !== undefined && typeof item.archived !== 'boolean') ||
        (item.inferredDay !== undefined && typeof item.inferredDay !== 'boolean') || (item.cancelled && item.done)) {
        throw new Error('备份事项无效');
      }
      [item.createdAt, item.updatedAt, item.deletedAt].forEach((stamp: number | undefined) => {
        if (stamp !== undefined && (!Number.isSafeInteger(stamp) || stamp < 0)) { throw new Error('备份时间无效'); }
      });
      ids.push(item.id); RoutineEngine.validateKeys(item.assignedTraits); RoutineEngine.validateKeys(item.awardedTraits);
      RoutineEngine.validatePoints(item.assignedPoints); RoutineEngine.validatePoints(item.awardedPoints);
      RoutineEngine.validatePoints(item.deletedPoints);
      if (item.done && item.awardedTraits === undefined) { throw new Error('备份缺少奖励来源'); }
      if (item.awardedPoints?.some((point: TraitPoints) => !item.awardedTraits?.includes(point.key))) {
        throw new Error('备份奖励来源不一致');
      }
    });
    const pinnedIds: number[] = [];
    state.pinnedTasks.forEach((item) => {
      if (!item || !Number.isSafeInteger(item.id) || item.id < 0 || pinnedIds.includes(item.id) ||
        typeof item.title !== 'string' || !item.title.trim() || typeof item.subtitle !== 'string') { throw new Error('备份模板无效'); }
      pinnedIds.push(item.id); RoutineEngine.validateKeys(item.assignedTraits); RoutineEngine.validatePoints(item.assignedPoints);
    });
    const actionIds: number[] = [];
    state.actions.forEach((item) => {
      if (!item || !Number.isSafeInteger(item.id) || actionIds.includes(item.id) || typeof item.text !== 'string' ||
        typeof item.summary !== 'string' || !Number.isSafeInteger(item.createdAt) || item.createdAt < 0 ||
        (item.deletedAt !== undefined && (!Number.isSafeInteger(item.deletedAt) || item.deletedAt < 0))) { throw new Error('备份旧记录无效'); }
      actionIds.push(item.id); RoutineEngine.validateKeys(item.traits);
      RoutineEngine.validatePoints(item.deletedPoints);
      if (!Array.isArray(item.traits)) { throw new Error('备份旧记录缺少维度'); }
    });
    const traitKeys: string[] = [];
    state.traitTotals.forEach((item: TraitTotal) => {
      if (!item || typeof item.key !== 'string' || traitKeys.includes(item.key) || !Number.isSafeInteger(item.score) || item.score < 0) {
        throw new Error('备份成长数据无效');
      }
      traitKeys.push(item.key);
    });
    NoteValidation.validate(state.notes);
    if (state.m2) { CommissionValidation.validate(state); }
    return RoutineEngine.clone(state);
  }

  static readBackup(text: string): RoutineSnapshot {
    const backup: RoutineBackup = JSON.parse(text) as RoutineBackup;
    if (!backup || backup.format !== 'RebelRoutine' || !Number.isSafeInteger(backup.exportedAt)) { throw new Error('不是 RebelRoutine 完整备份'); }
    return RoutineEngine.validate(RoutineEngine.migrate(backup.state));
  }

  static csv(state: RoutineSnapshot): string {
    const rows: string[][] = [['类型','编号','标题','备注','安排日期','实际日期','日期推定','状态','维度与点数','录入时间',
      '委托编号','进度','单位','关联类型','关联编号','关联标题','最后修改']];
    state.habits.forEach((item: HabitRecord) => {
      rows.push(['事项', `${item.id}`, item.title, item.subtitle, item.day ?? '', item.activityDay ?? '',
        item.inferredDay ? '是' : '否', item.deletedAt !== undefined ? '已删除' : item.archived ? '已归档' : item.cancelled ? '已取消' : item.done ? '已完成' : '待办',
        (item.awardedTraits ?? item.assignedTraits ?? []).map((key: string) =>
          `${key}:${RoutineEngine.amount(item.done ? item.awardedPoints ?? [] : item.assignedPoints ?? [], key)}`).join(' / '),
        item.createdAt === undefined ? '' : RoutineEngine.localTime(new Date(item.createdAt)),
        item.commissionId === undefined ? '' : `${item.commissionId}`, item.progressValue === undefined ? '' : `${item.progressValue}`,
        state.m2?.goals.find((goal) => goal.id === item.commissionId)?.unit ?? '']);
    });
    state.actions.forEach((item) => rows.push(['旧行动', `${item.id}`, item.text, item.summary, '',
      RoutineEngine.localDay(new Date(item.createdAt)), '否', item.deletedAt === undefined ? '已完成' : '已删除', item.traits.join(' / '),
        RoutineEngine.localTime(new Date(item.createdAt)),'','','']));
    state.notes?.forEach((note) => rows.push(['便签', `${note.id}`, note.title, note.body, '',
      RoutineEngine.localDay(new Date(note.createdAt)), '否', note.deletedAt === undefined ? '便签' : '已删除', '',
      RoutineEngine.localTime(new Date(note.createdAt)), '', '', '', note.link?.kind ?? '',
      note.link ? `${note.link.id}` : '', note.link?.title ?? '', RoutineEngine.localTime(new Date(note.updatedAt))]));
    return '\uFEFF' + rows.map((row: string[]) => {
      while (row.length < rows[0].length) { row.push(''); }
      return row.map((cell: string) => `"${cell.replace(/"/g, '""')}"`).join(',');
    }).join('\r\n');
  }
}
