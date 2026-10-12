// Controls, hints and reading text stay upright. Italics are reserved for
// explicit headings and display numbers; placeholders have their own font.
export const UI_LABEL_WEIGHT: FontWeight = FontWeight.Bold;
export const UI_LABEL_STYLE: FontStyle = FontStyle.Normal;
export const UI_BODY_WEIGHT: FontWeight = FontWeight.Medium;
export const UI_HINT_ON_INK: string = '#A9A397';
export const UI_HINT_ON_PAPER: string = '#555555';

export function uiPlaceholder(size: number): Font {
  return { size: size, weight: UI_BODY_WEIGHT, style: UI_LABEL_STYLE };
}
