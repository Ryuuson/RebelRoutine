import { curves } from '@kit.ArkUI';

// Only entering/leaving foreground components animate. Window size and city never participate.
export class Motion {
  private static move(x: number, y: number, enter: number, exit: number): TransitionEffect {
    const appear = TransitionEffect.opacity(0).combine(TransitionEffect.translate({ x, y }))
      .animation({ duration: enter, curve: curves.cubicBezierCurve(0.14, 0.78, 0.22, 1) });
    const disappear = TransitionEffect.opacity(0).animation({ duration: exit, curve: Curve.EaseIn });
    return TransitionEffect.asymmetric(appear, disappear);
  }
  static page(): TransitionEffect { return Motion.move(14, 0, 180, 90); }
  static workspace(): TransitionEffect { return Motion.move(20, 0, 190, 100); }
  static editor(): TransitionEffect { return Motion.move(24, 0, 200, 100); }
  static sheet(): TransitionEffect { return Motion.move(0, 20, 180, 100); }
  static content(): TransitionEffect { return Motion.move(8, 0, 130, 70); }
  static dialog(): TransitionEffect {
    const appear = TransitionEffect.opacity(0).combine(TransitionEffect.scale({ x: 0.97, y: 0.97 }))
      .animation({ duration: 160, curve: Curve.EaseOut });
    return TransitionEffect.asymmetric(appear,
      TransitionEffect.opacity(0).animation({ duration: 90, curve: Curve.EaseIn }));
  }
}
