export interface TimelineItem {
  id: string;
  label: string;
  group: string;
  start: string;
  end?: string;
  readOnly?: boolean;
  tone?: string;
}

/** Date-only values stay calendar dates; never parse them as UTC instants. */
export function localDate(value: string): Date {
  const [year, month, day] = value.split("-").map(Number);
  return new Date(year!, month! - 1, day!);
}
export function dateKey(value: Date): string {
  return `${value.getFullYear()}-${String(value.getMonth() + 1).padStart(2, "0")}-${String(value.getDate()).padStart(2, "0")}`;
}
export function addDays(value: string, days: number): string {
  const date = localDate(value);
  date.setDate(date.getDate() + days);
  return dateKey(date);
}
export function isDateKey(value: string): boolean {
  return (
    /^\d{4}-\d{2}-\d{2}$/.test(value) && dateKey(localDate(value)) === value
  );
}
/** Reject invalid proposals without ever changing the canonical collection. */
export function applyProposal(
  items: readonly TimelineItem[],
  next: TimelineItem,
  groupIds: readonly string[],
  accept = true,
): readonly TimelineItem[] {
  const current = items.find((item) => item.id === next.id);
  if (
    !accept ||
    !current ||
    current.readOnly ||
    !groupIds.includes(next.group) ||
    !isDateKey(next.start) ||
    (current.end === undefined) !== (next.end === undefined) ||
    (next.end !== undefined && (!isDateKey(next.end) || next.end <= next.start))
  )
    return items;
  return items.map((item) =>
    item.id === next.id
      ? { ...item, start: next.start, end: next.end, group: next.group }
      : item,
  );
}
