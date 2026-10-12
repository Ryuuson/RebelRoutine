import { matrix4 } from '@kit.ArkUI';

export const FOCUS_SECONDS: number = 25 * 60;
export const SEGMENT_COUNT: number = 16;
export const INK: string = '#000000';
export const PAPER: string = '#F2EFE9';
export const STEEL: string = '#8B8579';
export const RED: string = '#E60012';
export const YELLOW: string = '#F5C400';
export const LINE: string = '#2A2A2A';
export const PANEL: string = '#151515';
export const SHEAR: matrix4.Matrix4Transit = matrix4.init([
  1, 0, 0, 0,
  Math.tan(-9 * Math.PI / 180), 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1
]);
export const UNSHEAR: matrix4.Matrix4Transit = matrix4.init([
  1, 0, 0, 0,
  Math.tan(9 * Math.PI / 180), 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1
]);
