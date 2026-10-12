import { window } from '@kit.ArkUI';

export interface ScreenInsets { top: number; bottom: number; left: number; right: number; }
export interface ScreenSize { width: number; height: number; }

export class WindowLayout {
  static size(win: window.Window, previous: ScreenSize): ScreenSize {
    try {
      // RESIZE changes the page's usable area, not the physical window rectangle.
      const rect: window.Rect = win.getWindowProperties().windowRect;
      const ui = win.getUIContext();
      const width: number = ui.px2vp(rect.width);
      const height: number = ui.px2vp(rect.height);
      return width > 0 && height > 0 && Number.isFinite(width) && Number.isFinite(height) ? { width, height } : previous;
    } catch (error) {
      console.warn(`Window size unavailable: ${String(error)}`);
      return previous;
    }
  }

  static async immersive(win: window.Window): Promise<void> {
    await win.setWindowBackgroundColor('#000000');
    await win.setWindowLayoutFullScreen(true);
    await win.setWindowSystemBarEnable([]);
    await win.setSpecificSystemBarEnabled('navigationIndicator',false,false);
    await win.setWindowSystemBarProperties({
      statusBarColor: '#00000000', navigationBarColor: '#00000000',
      statusBarContentColor: '#FFFFFF', navigationBarContentColor: '#FFFFFF'
    });
  }

  static insets(win: window.Window, previous: ScreenInsets = { top: 0, bottom: 0, left: 0, right: 0 }): ScreenInsets {
    try {
    // Hidden system bars must not keep reserving strips. Only the physical cutout constrains controls.
    const areas: window.AvoidArea[] = [win.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT)];
    const ui = win.getUIContext();
    return {
      top: ui.px2vp(Math.max(0,...areas.map((area: window.AvoidArea) => area.topRect.height))),
      bottom: ui.px2vp(Math.max(0,...areas.map((area: window.AvoidArea) => area.bottomRect.height))),
      left: ui.px2vp(Math.max(0,...areas.map((area: window.AvoidArea) => area.leftRect.width))),
      right: ui.px2vp(Math.max(0,...areas.map((area: window.AvoidArea) => area.rightRect.width)))
    };
    } catch (error) {
      console.warn(`Window insets unavailable: ${String(error)}`);
      return previous;
    }
  }
}
