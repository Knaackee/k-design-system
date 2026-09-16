import { resolveLocale } from "../localization/data.js";
import type { KPickerLocale } from "./date-values.js";
export interface KPickerLabels {
  hours: string;
  minutes: string;
  period: string;
  month: string;
  year: string;
  previousYear: string;
  nextYear: string;
  previousYears: string;
  nextYears: string;
  date: string;
  time: string;
  chooseDate: string;
  chooseTime: string;
  chooseDateTime: string;
  previousMonth: string;
  nextMonth: string;
  apply: string;
  cancel: string;
  clear: string;
  invalid: string;
  outOfRange: string;
  nonexistent: string;
  ambiguous: string;
}
export function pickerLabels(
  locale: KPickerLocale,
  overrides?: Partial<KPickerLabels>,
): KPickerLabels {
  return { ...resolveLocale(locale).messages, ...overrides };
}
