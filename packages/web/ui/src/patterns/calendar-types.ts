import type { ReactNode } from "react";
export type KCalendarView = "day" | "three-day" | "week" | "month";
export type KCalendarMonthEventDisplay = "auto" | "appointments" | "indicators";
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
/** A host-owned pointer/touch drag into the calendar. Keep id stable per gesture. */
export interface KCalendarExternalDrag<T> {
  id: string;
  event: T;
  phase: "preview" | "commit" | "cancel";
  clientX: number;
  clientY: number;
  durationMinutes?: number;
}
export interface KCalendarDropOutside<T> {
  event: T;
  eventId: string;
  clientX: number;
  clientY: number;
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
  /** Requests the previous (-1) or next (1) visible period after a swipe. */
  onNavigate?: (direction: -1 | 1) => void;
  /** Auto uses indicators in compact month layouts and appointments otherwise. */
  monthEventDisplay?: KCalendarMonthEventDisplay;
  /** Opens the consumer-owned agenda/details surface for an indicator day. */
  onMonthDayOpen?: (date: string, events: readonly T[]) => void;
  onEventOpen?: (event: T) => void;
  onEventMove?: (move: KCalendarMove<T>) => void;
  /** Controlled host drag input. The calendar owns slot hit-testing and preview. */
  externalDrag?: KCalendarExternalDrag<T> | null;
  /** Receives a moved calendar event released outside every calendar slot. */
  onEventDropOutside?: (drop: KCalendarDropOutside<T>) => void;
  onEventResize?: (resize: KCalendarResize<T>) => void;
  onCreate?: (selection: KCalendarSelection) => void;
  /** Controlled create preview when onPendingCreateSelectionChange is set. */
  pendingCreateSelection?: KCalendarSelection | null;
  /** Set the controlled selection to null when a consumer create flow cancels. */
  onPendingCreateSelectionChange?: (
    selection: KCalendarSelection | null,
  ) => void;
  onInteraction?: (interaction: KCalendarInteraction<T>) => void;
  canCreate?: (selection: KCalendarSelection) => boolean;
  canMove?: (move: KCalendarMove<T>) => boolean;
  canDropOutside?: (drop: KCalendarDropOutside<T>) => boolean;
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
  /** Controlled portrait editing selection when onSelectedEventChange is supplied. */
  selectedEventId?: string | null;
  onSelectedEventChange?: (eventId: string | null) => void;
  hourHeight?: number;
  height?: number;
  minDayWidth?: number;
  labels?: Partial<KCalendarLabels>;
  className?: string;
  ariaLabel?: string;
}
