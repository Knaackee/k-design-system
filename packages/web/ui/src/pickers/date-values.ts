export type KDateFormat = "iso" | "dayMonthYear" | "monthDayYear";
export type KTimeFormat = "h24" | "h12";
export type KPickerLocale = string;
export type KTimeDisambiguation = "reject" | "earlier" | "later";
export type PickerKind = "date" | "time" | "datetime";
export const pad = (n: number) => String(n).padStart(2, "0");
export function utcDate(year: number, month: number, day: number) {
  const value = new Date(0);
  value.setUTCFullYear(year, month - 1, day);
  value.setUTCHours(0, 0, 0, 0);
  return value;
}
export function dateKey(value: Date) {
  return `${String(value.getUTCFullYear()).padStart(4, "0")}-${pad(value.getUTCMonth() + 1)}-${pad(value.getUTCDate())}`;
}
export function validDate(value: string): boolean {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return false;
  const [, y, m, d] = match.map(Number);
  return y >= 1 && y <= 9999 && dateKey(utcDate(y, m, d)) === value;
}
export const validTime = (value: string) =>
  /^(?:[01]\d|2[0-3]):[0-5]\d$/.test(value);
export function fromDateKey(value: string) {
  const [y, m, d] = value.split("-").map(Number);
  return utcDate(y, m, d);
}
export function addDays(value: string, count: number) {
  const date = fromDateKey(value);
  date.setUTCDate(date.getUTCDate() + count);
  return dateKey(date);
}
export function addMonths(value: string, count: number) {
  const date = fromDateKey(value),
    day = date.getUTCDate();
  date.setUTCDate(1);
  date.setUTCMonth(date.getUTCMonth() + count);
  const last = utcDate(
    date.getUTCFullYear(),
    date.getUTCMonth() + 2,
    0,
  ).getUTCDate();
  date.setUTCDate(Math.min(day, last));
  return dateKey(date);
}
export function formatDate(value: string, format: KDateFormat) {
  const [year, month, day] = value.split("-");
  return format === "dayMonthYear"
    ? `${day}.${month}.${year}`
    : format === "monthDayYear"
      ? `${month}/${day}/${year}`
      : value;
}
export function parseDate(value: string, format: KDateFormat): string | null {
  const match = (
    format === "iso"
      ? /^(\d{4})-(\d{1,2})-(\d{1,2})$/
      : format === "dayMonthYear"
        ? /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/
        : /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/
  ).exec(value.trim());
  if (!match) return null;
  const [, a, b, c] = match;
  const key =
    format === "iso"
      ? `${a}-${pad(+b)}-${pad(+c)}`
      : format === "dayMonthYear"
        ? `${c}-${pad(+b)}-${pad(+a)}`
        : `${c}-${pad(+a)}-${pad(+b)}`;
  return validDate(key) ? key : null;
}
export function formatTime(value: string, format: KTimeFormat) {
  if (format === "h24") return value;
  const [hour, minute] = value.split(":").map(Number);
  return `${pad(hour % 12 || 12)}:${pad(minute)} ${hour < 12 ? "AM" : "PM"}`;
}
export function parseTime(value: string, format: KTimeFormat): string | null {
  const match = (
    format === "h24"
      ? /^(\d{1,2}):([0-5]\d)$/
      : /^(\d{1,2}):([0-5]\d)\s*(AM|PM)$/i
  ).exec(value.trim());
  if (!match) return null;
  let hour = +match[1];
  if (format === "h12") {
    if (hour < 1 || hour > 12) return null;
    hour = (hour % 12) + (match[3].toUpperCase() === "PM" ? 12 : 0);
  }
  const result = `${pad(hour)}:${match[2]}`;
  return validTime(result) ? result : null;
}
const formatters = new Map<string, Intl.DateTimeFormat>();
export function zoneParts(instant: Date, timeZone: string) {
  let formatter = formatters.get(timeZone);
  if (!formatter) {
    formatter = new Intl.DateTimeFormat("en-US-u-ca-gregory-nu-latn", {
      timeZone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hourCycle: "h23",
    });
    formatters.set(timeZone, formatter);
  }
  const parts = Object.fromEntries(
    formatter.formatToParts(instant).map((p) => [p.type, p.value]),
  );
  return {
    date: `${parts.year.padStart(4, "0")}-${parts.month}-${parts.day}`,
    time: `${parts.hour}:${parts.minute}`,
  };
}
export function validInstant(value: string) {
  return (
    /^\d{4}-\d{2}-\d{2}T(?:[01]\d|2[0-3]):[0-5]\d:00(?:\.000)?Z$/.test(value) &&
    validDate(value.slice(0, 10)) &&
    Number.isFinite(Date.parse(value))
  );
}
export type ResolveResult =
  | { value: string; error?: never }
  | { error: "invalid" | "nonexistent" | "ambiguous"; value?: never };
export function resolveLocal(
  date: string,
  time: string,
  timeZone: string,
  disambiguation: KTimeDisambiguation,
): ResolveResult {
  if (!validDate(date) || !validTime(time)) return { error: "invalid" };
  const wall = fromDateKey(date);
  const [hour, minute] = time.split(":").map(Number);
  wall.setUTCHours(hour, minute);
  const offsets = new Set<number>();
  for (const delta of [-48, -24, 0, 24, 48]) {
    const sample = new Date(wall.getTime() + delta * 3600000),
      parts = zoneParts(sample, timeZone);
    const local = fromDateKey(parts.date);
    const [h, m] = parts.time.split(":").map(Number);
    local.setUTCHours(h, m);
    offsets.add(local.getTime() - sample.getTime());
  }
  const candidates = [...offsets]
    .map((offset) => new Date(wall.getTime() - offset))
    .filter((instant) => {
      const parts = zoneParts(instant, timeZone);
      return parts.date === date && parts.time === time;
    })
    .sort((a, b) => a.getTime() - b.getTime());
  if (!candidates.length) return { error: "nonexistent" };
  if (candidates.length > 1 && disambiguation === "reject")
    return { error: "ambiguous" };
  return {
    value: (disambiguation === "later"
      ? candidates.at(-1)!
      : candidates[0]
    ).toISOString(),
  };
}
export function valueParts(
  value: string | null,
  kind: PickerKind,
  timeZone: string,
  now: Date,
) {
  const today = zoneParts(now, timeZone);
  if (!value) return today;
  if (kind === "datetime") return zoneParts(new Date(value), timeZone);
  return kind === "date"
    ? { date: value, time: "09:00" }
    : { date: today.date, time: value };
}
export function inRange(
  value: string,
  kind: PickerKind,
  min?: string,
  max?: string,
) {
  const comparable = (v: string) => (kind === "datetime" ? Date.parse(v) : v);
  return (
    (!min || comparable(value) >= comparable(min)) &&
    (!max || comparable(value) <= comparable(max))
  );
}
export function validateConfiguration(
  kind: PickerKind,
  value: string | null,
  min: string | undefined,
  max: string | undefined,
  timeZone: string,
) {
  zoneParts(new Date(), timeZone);
  const valid =
    kind === "date" ? validDate : kind === "time" ? validTime : validInstant;
  for (const v of [value, min, max])
    if (v != null && !valid(v))
      throw new RangeError(`Invalid ${kind} picker value: ${v}`);
  if (min && max && !inRange(min, kind, undefined, max))
    throw new RangeError("Picker min must not exceed max");
}
export function validateMinuteStep(step: number) {
  if (!Number.isInteger(step) || step < 1 || step > 30 || 60 % step !== 0)
    throw new RangeError(
      "minuteStep must be a positive divisor of 60 no greater than 30",
    );
}
