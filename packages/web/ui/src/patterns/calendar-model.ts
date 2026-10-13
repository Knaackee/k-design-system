import {
  addDays,
  dateKey,
  fromDateKey,
  zoneParts,
  resolveLocal,
  pad,
} from "../pickers/date-values.js";
import type { KTimeDisambiguation } from "../pickers/date-values.js";
import type {
  KCalendarSlot,
  KCalendarView,
  KCalendarSelection,
} from "./calendar-types.js";
export { addDays, fromDateKey };
export function slot(
  date: string,
  minutes: number,
  allDay: boolean,
  timeZone: string,
): KCalendarSlot {
  const offset = Math.floor(minutes / 1440);
  return {
    date: addDays(date, offset),
    minutes: minutes - offset * 1440,
    allDay,
    timeZone,
  };
}
export function slotNumber(value: KCalendarSlot) {
  return fromDateKey(value.date).getTime() / 60000 + value.minutes;
}
export function shiftSlot(value: KCalendarSlot, minutes: number) {
  return slot(
    value.date,
    value.minutes + minutes,
    value.allDay,
    value.timeZone,
  );
}
export function calendarMoveDuration(
  start: Date | null,
  end: Date | null,
  sourceAllDay: boolean,
  targetAllDay: boolean,
  durationOverride: number | undefined,
  defaultDuration: number,
  step: number,
) {
  const override =
    durationOverride != null &&
    Number.isFinite(durationOverride) &&
    durationOverride > 0
      ? durationOverride
      : null;
  const sourceDuration =
    start && end
      ? Math.max(step, (end.getTime() - start.getTime()) / 60000)
      : null;
  const requested =
    override ??
    (!targetAllDay && sourceAllDay ? null : sourceDuration) ??
    defaultDuration;
  return targetAllDay
    ? Math.max(1440, Math.ceil(requested / 1440) * 1440)
    : requested;
}
export function instantSlot(
  value: Date,
  allDay: boolean,
  timeZone: string,
): KCalendarSlot {
  if (allDay) return slot(dateKey(value), 0, true, timeZone);
  const parts = zoneParts(value, timeZone),
    [hour, minute] = parts.time.split(":").map(Number);
  return slot(parts.date, hour * 60 + minute, false, timeZone);
}
/** Rejects nonexistent/ambiguous wall times by default; consumer may choose earlier/later. */
export function kCalendarSlotToDate(
  value: KCalendarSlot,
  disambiguation: KTimeDisambiguation = "reject",
): Date | null {
  if (value.allDay) return fromDateKey(value.date);
  const normalized = slot(value.date, value.minutes, false, value.timeZone);
  const result = resolveLocal(
    normalized.date,
    `${pad(Math.floor(normalized.minutes / 60))}:${pad(normalized.minutes % 60)}`,
    value.timeZone,
    disambiguation,
  );
  return result.value ? new Date(result.value) : null;
}
export function calendarDays(
  date: Date,
  view: KCalendarView,
  zone: string,
  firstDay: number,
) {
  let key = zoneParts(date, zone).date;
  if (view === "month") key = `${key.slice(0, 8)}01`;
  if (view === "month" || view === "week")
    key = addDays(key, -((fromDateKey(key).getUTCDay() - firstDay + 7) % 7));
  return Array.from(
    {
      length:
        view === "month"
          ? 42
          : view === "week"
            ? 7
            : view === "three-day"
              ? 3
              : 1,
    },
    (_, i) => addDays(key, i),
  );
}
export function orderedSelection(
  a: KCalendarSlot,
  b: KCalendarSlot,
  step: number,
): KCalendarSelection {
  const [start, last] = slotNumber(a) <= slotNumber(b) ? [a, b] : [b, a];
  return { start, end: shiftSlot(last, a.allDay ? 1440 : step) };
}
export interface CalendarEntry<T> extends KCalendarSelection {
  event: T;
  id: string;
}
export function intersects<T>(
  entry: CalendarEntry<T>,
  first: string,
  last: string,
) {
  return (
    slotNumber(entry.start) < fromDateKey(addDays(last, 1)).getTime() / 60000 &&
    slotNumber(entry.end) > fromDateKey(first).getTime() / 60000
  );
}
/** Allocate stable non-overlapping lanes, including connected overlap clusters. */
export function timeLanes<T>(entries: CalendarEntry<T>[]) {
  const sorted = [...entries].sort(
    (a, b) =>
      slotNumber(a.start) - slotNumber(b.start) ||
      slotNumber(b.end) - slotNumber(a.end) ||
      a.id.localeCompare(b.id),
  );
  const result: { entry: CalendarEntry<T>; lane: number; lanes: number }[] = [];
  let cluster: typeof result = [],
    ends: number[] = [],
    clusterEnd = -Infinity;
  const flush = () => {
    for (const item of cluster) item.lanes = ends.length;
    cluster = [];
    ends = [];
  };
  for (const entry of sorted) {
    if (slotNumber(entry.start) >= clusterEnd) {
      flush();
      clusterEnd = -Infinity;
    }
    let lane = ends.findIndex((end) => end <= slotNumber(entry.start));
    if (lane < 0) lane = ends.length;
    ends[lane] = slotNumber(entry.end);
    clusterEnd = Math.max(clusterEnd, slotNumber(entry.end));
    const item = { entry, lane, lanes: 1 };
    cluster.push(item);
    result.push(item);
  }
  flush();
  return result;
}
