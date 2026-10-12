export function dateKey(date: Date): string {
  const year: string = date.getFullYear().toString();
  const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
  const day: string = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function dayKey(): string { return dateKey(new Date()); }
export function yesterdayKey(): string { return shiftDay(-1); }
export function shiftDay(offset: number): string { return offsetDay(dayKey(), offset); }

export function offsetDay(day: string, offset: number): string {
  try {
    const date: Date = new Date(`${day}T12:00:00`);
    date.setDate(date.getDate() + offset);
    return dateKey(date);
  } catch (error) { return day; }
}

export function humanDate(day: string): string {
  if (!day) { return '日期未知'; }
  const weekdays: string[] = ['日', '一', '二', '三', '四', '五', '六'];
  try {
    return `${day.slice(5).replace('-', '/')} 周${weekdays[new Date(`${day}T12:00:00`).getDay()]}`;
  } catch (error) { return day; }
}

export function dateLabel(today: string): string {
  const date: Date = new Date(`${today}T12:00:00`);
  const weekdays: string[] = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
  const day: string = date.getDate().toString().padStart(2, '0');
  return `${weekdays[date.getDay()]} // ${month}.${day}`;
}
