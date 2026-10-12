import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WindowLayout } from '../common/WindowLayout';

export default class EntryAbility extends UIAbility {
  onForeground(): void {
    AppStorage.setOrCreate('routineForeground', Date.now());
  }
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    WindowLayout.immersive(windowStage.getMainWindowSync()).catch((error: Error) => {
      hilog.error(0x0000,'RebelRoutine','Window layout: %{public}s',String(error));
    }).finally(() => windowStage.loadContent('pages/Index'));
  }
}
