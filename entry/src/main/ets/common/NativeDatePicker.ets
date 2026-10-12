import { PageActions } from './PageActions';
import { dateKey } from './DayUtil';
import { RoutineEngine } from '../data/RoutineEngine';

export class NativeDatePicker {
  static open(ui: PageActions, target: string, done: boolean, current: string): void {
    const today: string = ui.host.state.today;
    const end: string = done ? today : '2100-12-31';
    let selected: string = RoutineEngine.validDay(current) ? current : today;
    if (selected > end) { selected = end; }
    const context = ui.host.getUIContext();
    context.getFocusController().clearFocus();
    context.showDatePickerDialog({
      start: new Date('1970-01-01T12:00:00'),
      end: new Date(`${end}T12:00:00`),
      selected: new Date(`${selected}T12:00:00`),
      lunar: false,
      showTime: false,
      onDateAccept: (value: Date) => {
        const day: string = dateKey(value);
        if (RoutineEngine.validDay(day) && day <= end && !ui.host.state.mutationBusy) {
          ui.draft.setDate(target, done, day);
        }
      }
    });
  }
}
