import type { ReactNode } from "react";
export type KCalendarView = "day" | "three-day" | "week" | "month";
export interface KCalendarSlot {
  date: string;
  minutes: number;
  allDay: boolean;
  timeZone: string;
}
/** End is exclusive, including date-only all-day ranges. */
export interface KCalendarSelection {
  start: KCalendarSlot;
  end: KCalendarSlot;
}
export interface KCalendarMove<T> {
  event: T;
  eventId: string;
  target: KCalendarSlot;
  durationMinutes: number;
}
export interface KCalendarResize<T> extends KCalendarSelection {
  event: T;
  eventId: string;
  edge: "start" | "end";
}
export interface KCalendarLabels {
  allDay: string;
  create: string;
  resizeStart: string;
  resizeEnd: string;
}
export interface KCalendarEventContext<T> {
  event: T;
  eventId: string;
  compact: boolean;
  start: Date | null;
  end: Date | null;
}
export interface KCalendarInteraction<T> {
  kind: "create" | "move" | "resize";
  phase: "start" | "preview" | "commit" | "cancel";
  selection: KCalendarSelection;
  event?: T;
}
export interface KCalendarProps<T> {
  date: Date;
  view: KCalendarView;
  events: readonly T[];
  getEventId: (event: T) => string;
  getEventStart: (event: T) => Date | null;
  getEventEnd: (event: T) => Date | null;
  /** All-day dates are civil dates encoded as UTC midnight, never zone-shifted. */
  getEventAllDay?: (event: T) => boolean;
  renderEvent: (context: KCalendarEventContext<T>) => ReactNode;
  onEventOpen?: (event: T) => void;
  onEventMove?: (move: KCalendarMove<T>) => void;
  onEventResize?: (resize: KCalendarResize<T>) => void;
  onCreate?: (selection: KCalendarSelection) => void;
  onInteraction?: (interaction: KCalendarInteraction<T>) => void;
  canCreate?: (selection: KCalendarSelection) => boolean;
  canMove?: (move: KCalendarMove<T>) => boolean;
  canResize?: (resize: KCalendarResize<T>) => boolean;
  locale?: string;
  timeZone?: string;
  firstDayOfWeek?: number;
  startHour?: number;
  endHour?: number;
  stepMinutes?: number;
  defaultDurationMinutes?: number;
  /** Use tap-to-create and reserve drag gestures for scrolling in compact layouts. */
  requireLongPress?: boolean;
  hourHeight?: number;
  height?: number;
  minDayWidth?: number;
  labels?: Partial<KCalendarLabels>;
  className?: string;
  ariaLabel?: string;
}
