import { formatDate } from "../pickers/date-values.js";
import { useKLocalization } from "../localization/provider.js";
import { nextZoneOccurrences } from "./map-zone-editor-recurrence.js";
import type { KMapZoneAvailability } from "../maps/map-zone-types.js";
import type { KMapZoneWorkingDay } from "../maps/map-zone-types.js";
import { KDisclosure } from "../primitives/disclosure.js";
import { KButton } from "../primitives/button.js";
import { KStack, KInline } from "../primitives/layout.js";
import { KInput } from "../forms/input.js";
import { KSelect } from "../forms/selection.js";
import type { KMapZonePropertyOptions } from "./map-zone-editor-types.js";

export const defaultZoneWorkingHoursLabels = {
  preview: "N\u00e4chste Einsatzzeiten laut Regel",
  previewHint:
    "Ausnahmen und bestehende Buchungen k\u00f6nnen diese Zeiten einschr\u00e4nken. Keine Zusage freier Termine.",
  noUpcoming: "Keine Einsatzzeiten im Vorschauzeitraum.",
  title: "Einsatzzeiten",
  timeZone: "Zeitzone",
  constraint:
    "Wiederholung und Zeitraum schr\u00e4nken diese Zeiten zus\u00e4tzlich ein.",
  missing:
    "Keine Einsatzzeiten festgelegt. Tage ohne Zeitfenster sind nicht verf\u00fcgbar.",
  copy: "Einsatzzeiten \u00fcbernehmen",
  chooseSource: "Von anderer Zone kopieren",
  closed: "Geschlossen",
  start: "Beginn",
  end: "Ende",
  remove: "Zeitfenster entfernen",
  add: "Zeitfenster hinzuf\u00fcgen",
  hint: "Diese Einsatzzeiten sind eine Regel, keine Zusage freier Termine.",
  invalid:
    "Bitte sieben Wochentage mit g\u00fcltigen, \u00fcberschneidungsfreien Zeitfenstern angeben.",
};
export function ZoneWorkingHoursFields({
  availability,
  hours,
  options,
  zoneId,
  onChange,
}: {
  availability?: KMapZoneAvailability;
  hours?: KMapZoneWorkingDay[];
  options: KMapZonePropertyOptions;
  zoneId?: string;
  onChange: (hours: KMapZoneWorkingDay[]) => void;
}) {
  const localization = useKLocalization();
  const formatter = new Intl.DateTimeFormat(
    options.locale ?? localization.calendarLocale,
    { dateStyle: "medium", timeZone: "UTC" },
  );
  const l = { ...defaultZoneWorkingHoursLabels, ...options.workingHoursLabels };
  const week =
    hours ??
    Array.from({ length: 7 }, (_, index) => ({
      day: index + 1,
      intervals: [],
    }));
  const weekdays = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"];
  const label = (day: number) =>
    options.weekdayOptions.find((option) => option.value === weekdays[day - 1])
      ?.label ?? weekdays[day - 1];
  const update = (day: number, intervals: KMapZoneWorkingDay["intervals"]) =>
    onChange(
      week.map((row) => ({
        ...row,
        intervals: (row.day === day ? intervals : row.intervals).map(
          (slot) => ({ ...slot }),
        ),
      })),
    );
  const upcoming = nextZoneWorkingWindows(
    hours,
    availability,
    options.timeZone,
  );
  const sources =
    options.workingHoursSources?.filter((source) => source.id !== zoneId) ?? [];
  return (
    <KStack
      align="stretch"
      gap="action"
      className="k-map-zone-editor__properties-section"
    >
      <strong>{l.title}</strong>
      <small>
        {l.timeZone}: {options.timeZone}. {l.constraint}
      </small>
      {!hours ? <small>{l.missing}</small> : null}
      {sources.length ? (
        <KSelect
          label={l.copy}
          value=""
          placeholder={l.chooseSource}
          options={sources.map((source) => ({
            value: source.id,
            label: source.label,
          }))}
          onValueChange={(id) => {
            const source = sources.find((candidate) => candidate.id === id);
            if (source)
              onChange(
                source.workingHours.map((day) => ({
                  ...day,
                  intervals: day.intervals.map((slot) => ({ ...slot })),
                })),
              );
          }}
        />
      ) : null}
      {week.map((day) => (
        <KDisclosure
          key={day.day}
          scrollOnOpen
          title={`${label(day.day)} · ${day.intervals.length ? day.intervals.map((slot) => `${slot.start}–${slot.end}`).join(", ") : l.closed}`}
        >
          <KStack align="stretch">
            {day.intervals.map((slot, index) => (
              <KInline key={index} wrap>
                <KInput
                  type="time"
                  aria-label={`${label(day.day)} ${l.start} ${index + 1}`}
                  value={slot.start}
                  onChange={(event) =>
                    update(
                      day.day,
                      day.intervals.map((item, i) =>
                        i === index
                          ? { ...item, start: event.target.value }
                          : item,
                      ),
                    )
                  }
                />
                <KInput
                  type="time"
                  aria-label={`${label(day.day)} ${l.end} ${index + 1}`}
                  value={slot.end}
                  onChange={(event) =>
                    update(
                      day.day,
                      day.intervals.map((item, i) =>
                        i === index
                          ? { ...item, end: event.target.value }
                          : item,
                      ),
                    )
                  }
                />
                <KButton
                  variant="ghost"
                  aria-label={`${label(day.day)} Zeitfenster ${index + 1} entfernen`}
                  onClick={() =>
                    update(
                      day.day,
                      day.intervals.filter((_, i) => i !== index),
                    )
                  }
                >
                  {l.remove}
                </KButton>
              </KInline>
            ))}
            <KButton
              variant="ghost"
              onClick={() =>
                update(day.day, [
                  ...day.intervals,
                  { start: "09:00", end: "17:00" },
                ])
              }
            >
              {l.add}
            </KButton>
          </KStack>
        </KDisclosure>
      ))}
      <KDisclosure scrollOnOpen title={l.preview}>
        <KStack align="stretch">
          <small>{l.previewHint}</small>
          {upcoming.map((window) => (
            <span key={window.date}>
              {options.formatDate?.(window.date) ??
                (options.dateFormat
                  ? formatDate(window.date, options.dateFormat)
                  : formatter.format(
                      new Date(`${window.date}T00:00:00Z`),
                    ))}{" "}
              ·{" "}
              {window.intervals
                .map((slot) => `${slot.start}–${slot.end}`)
                .join(", ")}
            </span>
          ))}
          {!upcoming.length ? <small>{l.noUpcoming}</small> : null}
        </KStack>
      </KDisclosure>
    </KStack>
  );
}

export function nextZoneWorkingWindows(
  hours: readonly KMapZoneWorkingDay[] | undefined,
  availability: KMapZoneAvailability | undefined,
  timeZone: string,
  now = new Date(),
) {
  if (!hours) return [];
  const today = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  const currentTime = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).format(now);
  const recurring =
    availability?.kind === "recurring"
      ? new Set(nextZoneOccurrences(availability, now, 366))
      : null;
  const windows: {
    date: string;
    intervals: KMapZoneWorkingDay["intervals"];
  }[] = [];
  const cursor = new Date(`${today}T00:00:00Z`);
  for (let offset = 0; offset < 3660 && windows.length < 3; offset++) {
    const date = cursor.toISOString().slice(0, 10);
    const intervals = (
      hours.find((day) => day.day === (cursor.getUTCDay() || 7))?.intervals ??
      []
    ).filter((slot) => date !== today || slot.end > currentTime);
    if (
      intervals.length &&
      (!recurring || recurring.has(date)) &&
      (availability?.kind !== "date-range" ||
        (date >= availability.from && date <= availability.to))
    )
      windows.push({ date, intervals });
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return windows;
}
