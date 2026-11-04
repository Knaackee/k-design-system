import type { Exception, Zone } from "./deployment-overhaul-data";

export function isEinsatzDate(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T12:00:00Z`);
  return (
    Number.isFinite(date.getTime()) && date.toISOString().slice(0, 10) === value
  );
}

export function isEinsatzTime(value: string): boolean {
  return /^([01]\d|2[0-3]):[0-5]\d$/.test(value);
}

export function postalCodeError(value: string, selected: string[]): string {
  const postal = value.trim();
  if (!/^\d{5}$/.test(postal))
    return "Bitte gib eine fünfstellige Postleitzahl ein.";
  if (selected.includes(postal))
    return "Diese Postleitzahl ist bereits ausgewählt.";
  return "";
}

export function isEinsatzEntryValid(
  entry: Exception,
  transport: boolean,
): boolean {
  if (!isEinsatzDate(entry.date)) return false;
  if (transport) {
    return (
      isEinsatzTime(entry.from) &&
      !!entry.address.trim() &&
      Number.isFinite(entry.minutes) &&
      entry.minutes >= 0 &&
      entry.minutes <= 120
    );
  }
  if (
    !isEinsatzDate(entry.until) ||
    entry.date > entry.until ||
    !entry.title.trim()
  )
    return false;
  if (entry.kind === "private" && !entry.address.trim()) return false;
  if (!entry.allDay) {
    if (!isEinsatzTime(entry.from) || !isEinsatzTime(entry.to)) return false;
    if (entry.date === entry.until && entry.from >= entry.to) return false;
  }
  return true;
}

export function isEinsatzZoneValid(zone: Zone): boolean {
  return (
    !!zone.name.trim() &&
    zone.days.length > 0 &&
    isEinsatzTime(zone.from) &&
    isEinsatzTime(zone.to) &&
    zone.from < zone.to &&
    zone.fee.trim() !== "" &&
    Number.isFinite(Number(zone.fee)) &&
    Number(zone.fee) >= 0 &&
    (zone.type !== "postal" ||
      (zone.postal.length > 0 &&
        zone.postal.every((value) => /^\d{5}$/.test(value)) &&
        new Set(zone.postal).size === zone.postal.length))
  );
}
