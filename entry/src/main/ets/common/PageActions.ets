import { LocalTraitAnalyzer } from '../data/TraitAnalyzer';
import { RoutineHost } from './RoutineHost';
import { FocusClock } from '../views/FocusView';
import { DialogueFeedback } from '../components/MorganaDialog';
import { Queries } from './Queries';
import { DraftState } from './DraftState';
import { LifecycleActions } from './LifecycleActions';
import { DataActions } from './DataActions';
import { UiFeedback } from './UiFeedback';
import { BatchActions } from './BatchActions';
import { CommissionActions } from './CommissionActions';
import { NoteActions } from './NoteActions';

export class PageActions {
  readonly analyzer: LocalTraitAnalyzer = new LocalTraitAnalyzer();
  readonly focus: FocusClock;
  readonly dialogue: DialogueFeedback;
  readonly queries: Queries;
  readonly draft: DraftState;
  readonly lifecycle: LifecycleActions;
  readonly data: DataActions;
  readonly feedback: UiFeedback;
  readonly batch: BatchActions;
  readonly commissions: CommissionActions;
  readonly notes: NoteActions;
  readonly host: RoutineHost;
  constructor(host: RoutineHost) {
    this.host = host;
    this.focus = new FocusClock(host, this);
    this.dialogue = new DialogueFeedback(host);
    this.queries = new Queries(host, this);
    this.draft = new DraftState(host, this);
    this.lifecycle = new LifecycleActions(host, this);
    this.data = new DataActions(host, this);
    this.feedback = new UiFeedback(host, this);
    this.batch = new BatchActions(host, this);
    this.commissions = new CommissionActions(host, this);
    this.notes = new NoteActions(host, this);
  }
  updateCompletedCount(): void {
    this.host.state.completedCount = this.queries.todayHabits().filter((item) => item.done).length;
  }
}
