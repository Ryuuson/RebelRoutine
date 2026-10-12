/** App 原创拟写台词；原语音核验后再与具体情境绑定。 */
export enum MorganaEvent {
  Complete,
  Clear,
  Focus,
  RankUp,
  Undo
}

export interface TraitDelta {
  key: string;
  points: number;
}

export interface MorganaCue {
  event: MorganaEvent;
  text: string;
  deltas: TraitDelta[];
}

const COMPLETE_LINES: string[] = [
  '干得漂亮，Joker！', '又搞定一件！', '这次也很利落嘛！', '不错，照这个节奏来！'
];
const CLEAR_LINES: string[] = [
  '不愧是Joker！今天收工！', '今天的安排全搞定了！', '漂亮！可以歇一会儿了。', '都完成了，好好放松一下！'
];
const FOCUS_LINES: string[] = [
  '这次很投入嘛！', '专注结束！休息一下吧。', '干得好，Joker！喝口水吧。', '这一轮不错，活动一下吧！'
];
const RANK_LINES: string[] = [
  '看来你的本事又长进了！', '又迈上一个台阶了，Joker！', '这些努力开始见效了嘛！', '很有进步！继续这样来！'
];
const UNDO_LINES: string[] = [
  '再调整一下计划吧。', '记好了，重新安排一下。', '没问题，再确认一下吧。', '这件先留着，按你的节奏来。'
];

function eventPriority(event: MorganaEvent): number {
  if (event === MorganaEvent.RankUp) { return 4; }
  if (event === MorganaEvent.Clear) { return 3; }
  if (event === MorganaEvent.Focus) { return 2; }
  return 1;
}

/** 短时间的操作合成一条反馈，指数增减按实际净值展示。 */
export class MorganaFeedback {
  private pending: boolean = false;
  private event: MorganaEvent = MorganaEvent.Complete;
  private deltas: TraitDelta[] = [];
  private recentLines: string[] = [];

  queue(event: MorganaEvent, keys: string[] = [], sign: number = 1, amounts: TraitDelta[] = []): void {
    if (!this.pending || event === MorganaEvent.Undo || this.event === MorganaEvent.Undo ||
      eventPriority(event) >= eventPriority(this.event)) {
      this.event = event;
    }
    this.pending = true;
    keys.forEach((key: string) => {
      const points: number = sign * (amounts.find((item: TraitDelta) => item.key === key)?.points ?? 1);
      const existing = this.deltas.find((delta: TraitDelta) => delta.key === key);
      if (existing) {
        existing.points += points;
      } else {
        this.deltas.push({ key, points });
      }
    });
  }

  take(): MorganaCue {
    let lines: string[] = COMPLETE_LINES;
    if (this.event === MorganaEvent.Clear) { lines = CLEAR_LINES; }
    if (this.event === MorganaEvent.Focus) { lines = FOCUS_LINES; }
    if (this.event === MorganaEvent.RankUp) { lines = RANK_LINES; }
    if (this.event === MorganaEvent.Undo) { lines = UNDO_LINES; }
    const candidates: string[] = lines.filter((line: string) => !this.recentLines.includes(line));
    const text: string = candidates[Math.floor(Math.random() * candidates.length)];
    this.recentLines = [...this.recentLines, text].slice(-3);
    const cue: MorganaCue = {
      event: this.event, text, deltas: this.deltas.filter((delta: TraitDelta) => delta.points !== 0)
    };
    this.clear();
    return cue;
  }

  clear(): void {
    this.pending = false;
    this.event = MorganaEvent.Complete;
    this.deltas = [];
  }
}
