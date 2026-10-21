import type { KMapZoneAvailability } from "../maps/map-zone-geometry.js";

const WEEKDAYS = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"] as const;
const MAX_PREVIEW_DAYS = 4_000;

export interface ZoneWeeklyRecurrence {
  frequency?: "DAILY" | "WEEKLY" | "MONTHLY" | "YEARLY";
  ordinal?: number;
  weekdayIds: string[];
  intervalWeeks: number;
  monthIds: number[];
  endDate?: string;
}

export function isIsoDate(value: string) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00Z`);
  return (
    !Number.isNaN(parsed.valueOf()) &&
    parsed.toISOString().slice(0, 10) === value
  );
}

export function isTimeZone(value: string) {
  try {
    new Intl.DateTimeFormat("en", { timeZone: value }).format();
    return true;
  } catch {
    return false;
  }
}

export function parseZoneWeeklyRRule(
  rrule: string,
): ZoneWeeklyRecurrence | null {
  const entries = rrule.split(";").map((part) => part.split("="));
  if (entries.some((entry) => entry.length !== 2)) return null;
  const values = new Map(entries.map(([key, value]) => [key, value]));
  if (
    values.size !== entries.length ||
    !["DAILY", "WEEKLY", "MONTHLY", "YEARLY"].includes(
      values.get("FREQ") ?? "",
    ) ||
    (values.get("FREQ") === "WEEKLY" && !values.get("BYDAY")) ||
    [...values.keys()].some(
      (key) =>
        !["FREQ", "INTERVAL", "BYDAY", "BYMONTH", "UNTIL", "BYSETPOS"].includes(
          key,
        ),
    )
  )
    return null;
  const frequency = values.get("FREQ") as NonNullable<
    ZoneWeeklyRecurrence["frequency"]
  >;
  const ordinal = values.has("BYSETPOS")
    ? Number(values.get("BYSETPOS"))
    : undefined;
  const weekdayIds = values.get("BYDAY")?.split(",") ?? [];
  if (
    ordinal !== undefined &&
    (frequency !== "MONTHLY" ||
      ![1, 2, 3, 4, -1].includes(ordinal) ||
      weekdayIds.length !== 1)
  )
    return null;
  if (weekdayIds.some((day) => !/^(MO|TU|WE|TH|FR|SA|SU)$/.test(day)))
    return null;
  const intervalWeeks = Number(values.get("INTERVAL") ?? "1");
  if (
    !Number.isInteger(intervalWeeks) ||
    intervalWeeks < 1 ||
    intervalWeeks > 52
  )
    return null;
  const rawMonths = values.get("BYMONTH");
  if (values.has("BYMONTH") && !rawMonths) return null;
  const monthIds = rawMonths ? rawMonths.split(",").map(Number) : [];
  if (
    monthIds.some(
      (month) => !Number.isInteger(month) || month < 1 || month > 12,
    )
  )
    return null;
  const rawUntil = values.get("UNTIL");
  if (values.has("UNTIL") && !rawUntil) return null;
  const endDate = rawUntil
    ? `${rawUntil.slice(0, 4)}-${rawUntil.slice(4, 6)}-${rawUntil.slice(6, 8)}`
    : undefined;
  if (rawUntil && (!/^\d{8}$/.test(rawUntil) || !isIsoDate(endDate!)))
    return null;
  return {
    ...(frequency !== "WEEKLY" ? { frequency } : {}),
    ...(ordinal !== undefined ? { ordinal } : {}),
    weekdayIds: [...new Set(weekdayIds)],
    intervalWeeks,
    monthIds: [...new Set(monthIds)].sort((a, b) => a - b),
    endDate,
  };
}

export function createZoneWeeklyRRule({
  frequency = "WEEKLY",
  ordinal,
  weekdayIds,
  intervalWeeks,
  monthIds = [],
  endDate,
}: ZoneWeeklyRecurrence) {
  const parts = [
    `FREQ=${frequency}`,
    ...(intervalWeeks === 1 ? [] : [`INTERVAL=${intervalWeeks}`]),
    ...(frequency === "WEEKLY" || weekdayIds.length
      ? [`BYDAY=${[...new Set(weekdayIds)].join(",")}`]
      : []),
    ...(ordinal !== undefined ? [`BYSETPOS=${ordinal}`] : []),
    ...(monthIds.length
      ? [`BYMONTH=${[...new Set(monthIds)].sort((a, b) => a - b).join(",")}`]
      : []),
    ...(endDate ? [`UNTIL=${endDate.replaceAll("-", "")}`] : []),
  ];
  return parts.join(";");
}

export function zonedToday(timeZone: string, now = new Date()) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: isTimeZone(timeZone) ? timeZone : "UTC",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(now);
  const value = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((part) => part.type === type)?.value ?? "";
  return `${value("year")}-${value("month")}-${value("day")}`;
}

export function defaultZoneRecurrence(
  timeZone: string,
  weekdayIds: readonly string[],
  now = new Date(),
): Extract<KMapZoneAvailability, { kind: "recurring" }> {
  const enabled = weekdayIds.length ? [...weekdayIds] : ["MO"];
  const startDate = nextMatchingDate(zonedToday(timeZone, now), enabled, true);
  return {
    kind: "recurring",
    rrule: createZoneWeeklyRRule({
      weekdayIds: enabled,
      intervalWeeks: 1,
      monthIds: [],
    }),
    startDate,
    timeZone,
  };
}

export function nextMatchingDate(
  from: string,
  weekdayIds: readonly string[],
  includeFrom = false,
  monthIds: readonly number[] = [],
) {
  const date = parseDate(from);
  for (let offset = includeFrom ? 0 : 1; offset < 370; offset += 1) {
    const candidate = addDays(date, offset);
    if (
      weekdayIds.includes(WEEKDAYS[candidate.getUTCDay()]) &&
      (!monthIds.length || monthIds.includes(candidate.getUTCMonth() + 1))
    )
      return formatDate(candidate);
  }
  return from;
}

export function matchingDateInAnchorWeek(
  anchor: string,
  weekdayIds: readonly string[],
  monthIds: readonly number[] = [],
) {
  if (!isIsoDate(anchor)) return anchor;
  const week = startOfWeek(parseDate(anchor));
  for (let offset = 0; offset < 7; offset += 1) {
    const candidate = addDays(week, offset);
    if (
      weekdayIds.includes(WEEKDAYS[candidate.getUTCDay()]) &&
      (!monthIds.length || monthIds.includes(candidate.getUTCMonth() + 1))
    )
      return formatDate(candidate);
  }
  return nextMatchingDate(anchor, weekdayIds, true, monthIds);
}

export function nextZoneOccurrences(
  availability: Extract<KMapZoneAvailability, { kind: "recurring" }>,
  now = new Date(),
  limit = 3,
) {
  const parsed = parseZoneWeeklyRRule(availability.rrule);
  if (
    !parsed ||
    !isIsoDate(availability.startDate) ||
    !isTimeZone(availability.timeZone) ||
    limit < 1
  )
    return [];
  const today = zonedToday(availability.timeZone, now);
  const first = availability.startDate > today ? availability.startDate : today;
  const anchorWeek = startOfWeek(parseDate(availability.startDate));
  const results: string[] = [];
  for (
    let offset = 0;
    offset <
      Math.max(
        MAX_PREVIEW_DAYS,
        Math.min(60000, 366 * parsed.intervalWeeks * limit),
      ) && results.length < limit;
    offset += 1
  ) {
    const candidate = addDays(parseDate(first), offset);
    const value = formatDate(candidate);
    if (parsed.endDate && value > parsed.endDate) break;
    const weeks = Math.floor(
      (candidate.valueOf() - anchorWeek.valueOf()) / 604_800_000,
    );
    const anchor = parseDate(availability.startDate);
    const frequency = parsed.frequency ?? "WEEKLY";
    const months =
      (candidate.getUTCFullYear() - anchor.getUTCFullYear()) * 12 +
      candidate.getUTCMonth() -
      anchor.getUTCMonth();
    const units =
      frequency === "DAILY"
        ? Math.floor((candidate.valueOf() - anchor.valueOf()) / 86400000)
        : frequency === "MONTHLY"
          ? months
          : frequency === "YEARLY"
            ? candidate.getUTCFullYear() - anchor.getUTCFullYear()
            : weeks;
    const sameDay = candidate.getUTCDate() === anchor.getUTCDate();
    const ordinalMatches =
      parsed.ordinal === -1
        ? addDays(candidate, 7).getUTCMonth() !== candidate.getUTCMonth()
        : Math.ceil(candidate.getUTCDate() / 7) === parsed.ordinal;
    if (
      units >= 0 &&
      units % parsed.intervalWeeks === 0 &&
      (frequency !== "MONTHLY" ||
        (parsed.ordinal !== undefined ? ordinalMatches : sameDay)) &&
      (frequency !== "YEARLY" ||
        (sameDay && candidate.getUTCMonth() === anchor.getUTCMonth())) &&
      (!parsed.weekdayIds.length ||
        parsed.weekdayIds.includes(WEEKDAYS[candidate.getUTCDay()])) &&
      (!parsed.monthIds.length ||
        parsed.monthIds.includes(candidate.getUTCMonth() + 1))
    )
      results.push(value);
  }
  return results;
}

function parseDate(value: string) {
  return new Date(`${value}T00:00:00Z`);
}

function addDays(value: Date, days: number) {
  const next = new Date(value);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function formatDate(value: Date) {
  return value.toISOString().slice(0, 10);
}

function startOfWeek(value: Date) {
  const day = value.getUTCDay();
  return addDays(value, -(day === 0 ? 6 : day - 1));
}
