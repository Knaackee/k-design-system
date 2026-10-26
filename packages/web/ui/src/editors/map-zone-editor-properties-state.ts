import { useState } from "react";
import type { KMapZone } from "../maps/map-zone-geometry.js";
import type {
  KMapZoneSettings,
  KMapZoneTravelCost,
} from "../maps/map-zone-geometry.js";
import { defaultMapZoneColor } from "../maps/map-zone-colors.js";
import type { KMapZonePropertyOptions } from "./map-zone-editor-types.js";
import {
  isIsoDate,
  isTimeZone,
  parseZoneWeeklyRRule,
} from "./map-zone-editor-recurrence.js";
export {
  createZoneWeeklyRRule,
  parseZoneWeeklyRRule,
} from "./map-zone-editor-recurrence.js";

export type ZoneSettingsValidationCode =
  | "working-hours"
  | "travel-cost"
  | "surcharge"
  | "weekdays"
  | "recurrence"
  | "start-weekday"
  | "date-range";

export function normalizeZoneSettings(
  settings: KMapZoneSettings | undefined,
  options: KMapZonePropertyOptions | undefined,
): { settings: KMapZoneSettings; error: ZoneSettingsValidationCode | null } {
  const next: KMapZoneSettings = {
    ...settings,
    ...(settings?.workingHours || options?.defaultWorkingHours
      ? {
          workingHours: (
            settings?.workingHours ?? options!.defaultWorkingHours!
          ).map((day) => ({
            ...day,
            intervals: day.intervals.map((interval) => ({ ...interval })),
          })),
        }
      : {}),
    travelCost: settings?.travelCost ?? options?.defaultTravelCost,
  };
  if (next.workingHours && !validZoneWorkingHours(next.workingHours))
    return { settings: next, error: "working-hours" };
  if (
    next.travelCost?.kind !== "free" &&
    next.travelCost &&
    (!Number.isFinite(next.travelCost.amount) ||
      next.travelCost.amount < 0 ||
      !next.travelCost.currency)
  )
    return { settings: next, error: "travel-cost" };
  if (
    next.surcharge &&
    (!Number.isFinite(next.surcharge.amount) ||
      next.surcharge.amount < 0 ||
      !next.surcharge.currency)
  )
    return { settings: next, error: "surcharge" };
  if (next.availability?.kind === "recurring") {
    if (/(?:^|;)BYDAY=(?:;|$)/.test(next.availability.rrule))
      return { settings: next, error: "weekdays" };
    const parsed = parseZoneWeeklyRRule(next.availability.rrule);
    if (!parsed) return { settings: next, error: "recurrence" };
    if (
      options &&
      parsed.weekdayIds.some(
        (id) =>
          !options.weekdayOptions.some(
            (option) => option.value === id && !option.disabled,
          ),
      )
    )
      return { settings: next, error: "weekdays" };
    if (
      !isIsoDate(next.availability.startDate) ||
      !isTimeZone(next.availability.timeZone) ||
      (parsed.endDate && parsed.endDate < next.availability.startDate) ||
      (parsed.monthIds.length &&
        !parsed.monthIds.includes(
          Number(next.availability.startDate.slice(5, 7)),
        ))
    )
      return { settings: next, error: "recurrence" };
    const weekday = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"][
      new Date(`${next.availability.startDate}T00:00:00Z`).getUTCDay()
    ];
    if (parsed.weekdayIds.length && !parsed.weekdayIds.includes(weekday))
      return { settings: next, error: "start-weekday" };
  }
  if (next.availability?.kind === "date-range") {
    const { from, to } = next.availability;
    if (!isIsoDate(from) || !isIsoDate(to) || from > to)
      return { settings: next, error: "date-range" };
  }
  return { settings: next, error: null };
}

export function validZoneWorkingHours(
  days: NonNullable<KMapZoneSettings["workingHours"]>,
): boolean {
  const time = /^(?:[01]\d|2[0-3]):[0-5]\d$/;
  return (
    days.length === 7 &&
    new Set(days.map((d) => d.day)).size === 7 &&
    days.every(
      (d) =>
        Number.isInteger(d.day) &&
        d.day >= 1 &&
        d.day <= 7 &&
        d.intervals.every(
          (slot, index) =>
            time.test(slot.start) &&
            time.test(slot.end) &&
            slot.start < slot.end &&
            (!index || d.intervals[index - 1].end <= slot.start),
        ),
    )
  );
}

export interface ZoneEditorPropertyValues {
  name: string;
  color?: string;
  settings?: KMapZoneSettings;
}

type PaidTravelCostKind = Exclude<KMapZoneTravelCost["kind"], "free">;

export interface ZoneEditorPropertyDraft {
  name: string;
  color: string;
  settings: KMapZoneSettings;
  surchargeEnabled: boolean;
  travelAmounts: Record<PaidTravelCostKind, number | "">;
}

export function copyZoneTravelCost(
  draft: ZoneEditorPropertyDraft,
  travelCost: KMapZoneTravelCost,
): ZoneEditorPropertyDraft {
  const copy =
    travelCost.kind === "free" ? { kind: "free" as const } : { ...travelCost };
  return {
    ...draft,
    settings: { ...draft.settings, travelCost: copy },
    travelAmounts:
      travelCost.kind === "free"
        ? { ...draft.travelAmounts }
        : { ...draft.travelAmounts, [travelCost.kind]: travelCost.amount },
  };
}

function propertyDraftFromZone(
  zone: KMapZone,
  options?: KMapZonePropertyOptions,
): ZoneEditorPropertyDraft {
  const settings = normalizeZoneSettings(zone.settings, options).settings;
  const travelCost = settings.travelCost;
  return {
    name: zone.name,
    color: zone.color ?? defaultMapZoneColor,
    settings,
    surchargeEnabled: !!settings.surcharge,
    travelAmounts: {
      "per-kilometer":
        travelCost?.kind === "per-kilometer" ? travelCost.amount : "",
      "flat-rate": travelCost?.kind === "flat-rate" ? travelCost.amount : "",
    },
  };
}

export function useZoneEditorProperties({
  zones,
  draft,
  onUpdateDraft,
  onUpdateZones,
  propertyOptions,
}: {
  zones: readonly KMapZone[];
  draft: KMapZone | null;
  onUpdateDraft: (zone: KMapZone) => void;
  onUpdateZones: (zones: readonly KMapZone[]) => void;
  propertyOptions?: KMapZonePropertyOptions;
}) {
  const [open, setOpen] = useState(false);
  const [targetId, setTargetId] = useState<string | null>(null);
  const [values, setValues] = useState<ZoneEditorPropertyDraft | null>(null);
  const zone = targetId
    ? draft?.id === targetId
      ? draft
      : (zones.find((item) => item.id === targetId) ?? null)
    : null;
  const options = propertyOptions;
  const effectiveSettings: KMapZoneSettings = {
    ...values?.settings,
    surcharge: values?.surchargeEnabled ? values.settings.surcharge : undefined,
  };
  const normalized = normalizeZoneSettings(effectiveSettings, options);
  const travelCost = values?.settings.travelCost ??
    options?.defaultTravelCost ?? { kind: "free" as const };
  const nextZone =
    zone && values
      ? {
          ...zone,
          name: values.name.trim(),
          color:
            values.color === (zone.color ?? defaultMapZoneColor)
              ? zone.color
              : values.color,
          settings: normalized.settings,
        }
      : null;
  const baseline = zone
    ? {
        name: zone.name,
        color: zone.color,
        settings: normalizeZoneSettings(zone.settings, options).settings,
      }
    : null;
  const nextProperties = nextZone
    ? {
        name: nextZone.name,
        color: nextZone.color,
        settings: nextZone.settings,
      }
    : null;
  const dirty =
    !!baseline &&
    !!nextProperties &&
    JSON.stringify(baseline) !== JSON.stringify(nextProperties);
  const apply = () => {
    if (!zone || !nextZone || !values?.name.trim() || normalized.error)
      return false;
    if (dirty) {
      if (draft?.id === zone.id) onUpdateDraft(nextZone);
      else
        onUpdateZones(
          zones.map((item) => (item.id === zone.id ? nextZone : item)),
        );
    }
    setValues(propertyDraftFromZone(nextZone, options));
    return true;
  };
  const updateSettings = (next: Partial<KMapZoneSettings>) =>
    setValues((current) =>
      current
        ? { ...current, settings: { ...current.settings, ...next } }
        : current,
    );
  const result = {
    open,
    zone,
    values,
    dirty,
    normalized,
    travelCost,
    canApply: !!values?.name.trim() && !normalized.error,
    nextZone,
    setOpen,
    openFor: (target: KMapZone) => {
      if (target.id !== targetId || !values)
        setValues(propertyDraftFromZone(target, options));
      setTargetId(target.id);
      setOpen(true);
    },
    setName: (name: string) =>
      setValues((current) => (current ? { ...current, name } : current)),
    setColor: (color: string) =>
      setValues((current) => (current ? { ...current, color } : current)),
    setSurchargeEnabled: (surchargeEnabled: boolean) => {
      setValues((current) =>
        current ? { ...current, surchargeEnabled } : current,
      );
      if (surchargeEnabled && !values?.settings.surcharge && options)
        updateSettings({
          surcharge: { amount: 0, currency: options.currency },
        });
    },
    setTravelAmount: (kind: PaidTravelCostKind, amount: number | "") => {
      setValues((current) =>
        current
          ? {
              ...current,
              travelAmounts: { ...current.travelAmounts, [kind]: amount },
            }
          : current,
      );
      updateSettings({
        travelCost: {
          kind,
          amount: Number(amount),
          currency: options?.currency ?? "",
        },
      });
    },
    setTravelKind: (kind: KMapZoneTravelCost["kind"]) => {
      if (kind === "free") return updateSettings({ travelCost: { kind } });
      updateSettings({
        travelCost: {
          kind,
          amount: Number(values?.travelAmounts[kind]),
          currency: options?.currency ?? "",
        },
      });
    },
    copyTravelCost: (travelCost: KMapZoneTravelCost) =>
      setValues((current) =>
        current ? copyZoneTravelCost(current, travelCost) : current,
      ),
    updateSettings,
    apply,
    discard: () => {
      if (zone) setValues(propertyDraftFromZone(zone, options));
    },
  };
  return result;
}

export type ZoneEditorPropertyController = ReturnType<
  typeof useZoneEditorProperties
>;
