import { RoutineState } from './RoutineState';
import { UIContext } from '@kit.ArkUI';
import { RoutineStore, RoutineSnapshot } from '../data/RoutineStore';

export interface RoutineHost {
  state: RoutineState;
  store?: RoutineStore;
  todayScroller: Scroller;
  taskScroller: Scroller;
  recordScroller: Scroller;
  growthScroller: Scroller;
  getUIContext(): UIContext;
  snapshot(): RoutineSnapshot;
  adopt(state: RoutineSnapshot): void;
  mutate(operation: () => Promise<RoutineSnapshot>, settle?: boolean): Promise<boolean>;
  showError(error: Error): void;
  restoreState(): Promise<void>;
  refreshToday(): void;
  switchPage(page: string): void;
  openWorkspace(name: string): void;
  closeWorkspace(): void;
}
