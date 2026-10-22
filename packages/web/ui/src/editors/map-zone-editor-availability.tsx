import { useMemo, useState } from "react";

import { KBadge } from "../basic-components.js";

import { KButton } from "../primitives/button.js";

import { KInput } from "../forms/input.js";

import { KDatePicker } from "../pickers/picker.js";

import { KSelect } from "../forms/selection.js";

import { KIcon } from "../primitives/icon.js";

import { useKLocalization } from "../localization/provider.js";

import { KDisclosure } from "../primitives/disclosure.js";

import type { KMapZoneAvailability } from "../maps/map-zone-geometry.js";

import type { KMapZoneEditorLabels } from "./map-zone-editor-labels.js";

import {
  type ZoneWeeklyRecurrence,
  createZoneWeeklyRRule,
  defaultZoneRecurrence,
  isIsoDate,
  matchingDateInAnchorWeek,
  parseZoneWeeklyRRule,
} from "./map-zone-editor-recurrence.js";

import type { KMapZonePropertyOptions } from "./map-zone-editor-types.js";

type RecurringAvailability = Extract<
  KMapZoneAvailability,
  { kind: "recurring" }
>;

type DateRangeAvailability = Extract<
  KMapZoneAvailability,
  { kind: "date-range" }
>;

export function ZoneAvailabilityFields({
  workingHours,
  availability,

  labels,

  options,

  onChange,
}: {
  workingHours?: import("../maps/map-zone-types.js").KMapZoneWorkingDay[];
  availability?: KMapZoneAvailability;

  labels: KMapZoneEditorLabels;

  options: KMapZonePropertyOptions;

  onChange: (availability?: KMapZoneAvailability) => void;
}) {
  const localization = useKLocalization();

  const calendarLocale = options.locale ?? localization.calendarLocale;

  const initialDays = options.weekdayOptions

    .filter((option) => !option.disabled)

    .slice(0, 1)

    .map((option) => option.value);

  const [recurring, setRecurring] = useState<RecurringAvailability>(() =>
    availability?.kind === "recurring"
      ? availability
      : defaultZoneRecurrence(options.timeZone, initialDays),
  );

  const [range, setRange] = useState<DateRangeAvailability>(() =>
    availability?.kind === "date-range"
      ? availability
      : { kind: "date-range", from: "", to: "" },
  );

  const [anchorTouched, setAnchorTouched] = useState(false);

  const mode = availability?.kind ?? "always";

  const rule = parseZoneWeeklyRRule(recurring.rrule) ?? {
    weekdayIds: [],

    intervalWeeks: 1,

    monthIds: [],
  };

  const updateRule = (next: Partial<ZoneWeeklyRecurrence>) => {
    const weekdayIds = next.weekdayIds ?? rule.weekdayIds;

    let startDate = recurring.startDate;

    const monthIds = next.monthIds ?? rule.monthIds;

    if (
      (next.frequency ?? rule.frequency ?? "WEEKLY") === "WEEKLY" &&
      (next.weekdayIds || next.monthIds) &&
      !anchorTouched &&
      weekdayIds.length
    )
      startDate = matchingDateInAnchorWeek(
        recurring.startDate,

        weekdayIds,

        monthIds,
      );

    const value: RecurringAvailability = {
      ...recurring,

      startDate,

      rrule: createZoneWeeklyRRule({ ...rule, ...next, weekdayIds }),
    };

    setRecurring(value);

    onChange(value);
  };

  const updateStartDate = (startDate: string) => {
    setAnchorTouched(true);

    const anchor = new Date(`${startDate}T00:00:00Z`);

    const nextRule =
      rule.ordinal !== undefined && isIsoDate(startDate)
        ? {
            ...rule,

            ordinal:
              Math.ceil(anchor.getUTCDate() / 7) > 4
                ? -1
                : Math.ceil(anchor.getUTCDate() / 7),

            weekdayIds: [
              ["SU", "MO", "TU", "WE", "TH", "FR", "SA"][anchor.getUTCDay()],
            ],
          }
        : rule;

    const value = {
      ...recurring,

      startDate,

      rrule: createZoneWeeklyRRule(nextRule),
    };

    setRecurring(value);

    onChange(value);
  };

  const dateFormatter = useMemo(
    () =>
      new Intl.DateTimeFormat(calendarLocale, {
        dateStyle: "medium",

        timeZone: "UTC",
      }),

    [calendarLocale],
  );

  const monthLabels = useMemo(
    () =>
      Array.from({ length: 12 }, (_, index) => ({
        value: index + 1,

        label: new Intl.DateTimeFormat(calendarLocale, {
          month: "short",

          timeZone: "UTC",
        }).format(new Date(Date.UTC(2024, index, 1))),
      })),

    [calendarLocale],
  );

  const weekdaySummary = rule.weekdayIds

    .map(
      (id) =>
        options.weekdayOptions.find((option) => option.value === id)?.label ??
        id,
    )

    .join(", ");

  const frequency = rule.frequency ?? "WEEKLY";

  const units = labels.recurrenceUnits ?? {
    daily: "Tage",

    weekly: "Wochen",

    monthly: "Monate",

    yearly: "Jahre",
  };

  const unitOptions = [
    { value: "DAILY", label: units.daily },

    { value: "WEEKLY", label: units.weekly },

    { value: "MONTHLY", label: units.monthly },

    { value: "YEARLY", label: units.yearly },
  ];

  const intervalSummary =
    rule.intervalWeeks === 1
      ? frequency === "WEEKLY"
        ? labels.everyWeek
        : { DAILY: "Täglich", MONTHLY: "Monatlich", YEARLY: "Jährlich" }[
            frequency
          ]
      : `${labels.recurrenceEvery ?? "Alle"} ${rule.intervalWeeks} ${unitOptions.find((u) => u.value === frequency)?.label}`;

  const summaryDetails = [
    intervalSummary,

    weekdaySummary,

    ...(rule.intervalWeeks > 1 && isIsoDate(recurring.startDate)
      ? [
          formatTemplate(labels.recurrenceAnchorSummary, {
            date: dateFormatter.format(
              new Date(`${recurring.startDate}T00:00:00Z`),
            ),
          }),
        ]
      : []),

    ...(rule.monthIds.length
      ? [
          formatTemplate(labels.recurrenceMonthsSummary, {
            months: rule.monthIds

              .map(
                (id) =>
                  monthLabels.find((month) => month.value === id)?.label ??
                  String(id),
              )

              .join(", "),
          }),
        ]
      : []),

    ...(rule.endDate
      ? [
          formatTemplate(labels.recurrenceEndSummary, {
            date: dateFormatter.format(new Date(`${rule.endDate}T00:00:00Z`)),
          }),
        ]
      : []),
  ].filter(Boolean);

  const summary = formatTemplate(labels.recurrenceSummary, {
    details: summaryDetails.join(" · "),
  });

  return (
    <div className="k-map-zone-editor__properties-section">
      <span className="k-map-zone-editor__identity-label">
        {labels.availability}
      </span>

      <KSelect
        options={[
          {
            value: "always",

            label: labels.alwaysAvailability,

            leading: <KIcon name="infinity" strokeWidth={1.5} />,
          },

          {
            value: "recurring",

            label: labels.recurringAvailability,

            leading: <KIcon name="repeat" strokeWidth={1.5} />,
          },

          {
            value: "date-range",

            label: labels.dateRangeAvailability,

            leading: <KIcon name="calendar-range" strokeWidth={1.5} />,
          },
        ]}

        value={mode}

        onValueChange={(value) => {
          if (value === "always") onChange(undefined);
          else if (value === "recurring") onChange(recurring);
          else onChange(range);
        }}

        label={labels.availability}
      />

      {mode === "recurring" ? (
        <>
          <div className="k-map-zone-editor__recurrence-interval">
            <span>{labels.recurrenceEvery ?? "Alle"}</span>

            <KInput
              type="number"

              min="1"

              max="52"

              step="1"

              aria-label={labels.intervalWeeks}

              value={rule.intervalWeeks}

              onChange={(event) =>
                updateRule({ intervalWeeks: Number(event.target.value) })
              }
            />

            <KSelect
              label={labels.recurrenceUnit ?? "Einheit"}

              value={frequency}

              options={unitOptions}

              onValueChange={(value) =>
                updateRule({
                  frequency: value as ZoneWeeklyRecurrence["frequency"],

                  ordinal: undefined,

                  weekdayIds: value === "WEEKLY" ? initialDays : [],
                })
              }
            />
          </div>

          {frequency === "MONTHLY" ? (
            <KSelect
              label={labels.recurrenceMonthlyMode ?? "Monatliche Wiederholung"}

              value={rule.ordinal === undefined ? "date" : "weekday"}

              options={[
                {
                  value: "date",

                  label:
                    labels.recurrenceMonthDate ?? "Am gleichen Kalendertag",
                },

                {
                  value: "weekday",

                  label:
                    labels.recurrenceMonthWeekday ?? "Am gleichen Wochentag",
                },
              ]}

              onValueChange={(value) => {
                const anchor = new Date(`${recurring.startDate}T00:00:00Z`);

                updateRule({
                  ordinal:
                    value === "weekday"
                      ? Math.ceil(anchor.getUTCDate() / 7) > 4
                        ? -1
                        : Math.ceil(anchor.getUTCDate() / 7)
                      : undefined,

                  weekdayIds:
                    value === "weekday"
                      ? [
                          ["SU", "MO", "TU", "WE", "TH", "FR", "SA"][
                            anchor.getUTCDay()
                          ],
                        ]
                      : [],
                });
              }}
            />
          ) : null}

          {frequency === "MONTHLY" || frequency === "YEARLY" ? (
            <label className="k-map-zone-editor__field">
              <span>{labels.intervalAnchor}</span>

              <KDatePicker
                locale={options.locale}

                dateFormat={options.dateFormat}

                allowTextInput

                value={recurring.startDate || null}

                onValueChange={(value) => updateStartDate(value ?? "")}
              />
            </label>
          ) : null}

          {frequency === "WEEKLY" ? (
            <div
              className="k-map-zone-editor__weekday-grid"

              aria-label={labels.weekdays}
            >
              {options.weekdayOptions.map((option) => (
                <KButton
                  key={option.value}

                  variant="ghost"

                  className="k-map-zone-editor__day-toggle"

                  aria-label={option.label}

                  disabled={option.disabled}

                  aria-pressed={rule.weekdayIds.includes(option.value)}

                  onClick={() =>
                    updateRule({
                      weekdayIds: !rule.weekdayIds.includes(option.value)
                        ? [...rule.weekdayIds, option.value]
                        : rule.weekdayIds.filter((id) => id !== option.value),
                    })
                  }
                >
                  <KBadge
                    variant={
                      rule.weekdayIds.includes(option.value)
                        ? "primary"
                        : "outline"
                    }
                  >
                    {option.shortLabel ?? option.label}
                  </KBadge>
                </KButton>
              ))}
            </div>
          ) : null}

          <p className="k-map-zone-editor__recurrence-summary">{summary}</p>

          <KDisclosure
            scrollOnOpen

            className="k-map-zone-editor__recurrence-disclosure"

            title={labels.recurrenceDetails}
          >
            <div className="k-map-zone-editor__recurrence-details">
              <label className="k-map-zone-editor__field">
                <span>{labels.intervalAnchor}</span>

                <KDatePicker
                  locale={options.locale}

                  dateFormat={options.dateFormat}

                  allowTextInput

                  value={recurring.startDate || null}

                  onValueChange={(value) => updateStartDate(value ?? "")}
                />
              </label>

              <label className="k-map-zone-editor__field">
                <span>{labels.endDate}</span>

                <KDatePicker
                  locale={options.locale}

                  dateFormat={options.dateFormat}

                  allowTextInput

                  value={rule.endDate || null}

                  onValueChange={(value) =>
                    updateRule({ endDate: value || undefined })
                  }
                />
              </label>

              <fieldset className="k-map-zone-editor__month-fieldset">
                <legend>{labels.months}</legend>

                <div className="k-map-zone-editor__month-grid">
                  {monthLabels.map((month) => (
                    <KButton
                      key={month.value}

                      variant="ghost"

                      className="k-map-zone-editor__day-toggle"

                      aria-pressed={rule.monthIds.includes(month.value)}

                      onClick={() =>
                        updateRule({
                          monthIds: !rule.monthIds.includes(month.value)
                            ? [...rule.monthIds, month.value]
                            : rule.monthIds.filter((id) => id !== month.value),
                        })
                      }
                    >
                      <KBadge
                        variant={
                          rule.monthIds.includes(month.value)
                            ? "primary"
                            : "outline"
                        }
                      >
                        {month.label}
                      </KBadge>
                    </KButton>
                  ))}
                </div>
              </fieldset>
            </div>
          </KDisclosure>
        </>
      ) : mode === "date-range" ? (
        <div className="k-map-zone-editor__properties-inline">
          <label className="k-map-zone-editor__field">
            <span>{labels.startDate}</span>

            <KDatePicker
              locale={options.locale}

              dateFormat={options.dateFormat}

              allowTextInput

              value={range.from || null}

              onValueChange={(date) => {
                const value = { ...range, from: date ?? "" };

                setRange(value);

                onChange(value);
              }}
            />
          </label>

          <label className="k-map-zone-editor__field">
            <span>{labels.endDate}</span>

            <KDatePicker
              locale={options.locale}

              dateFormat={options.dateFormat}

              allowTextInput

              value={range.to || null}

              onValueChange={(date) => {
                const value = { ...range, to: date ?? "" };

                setRange(value);

                onChange(value);
              }}
            />
          </label>
        </div>
      ) : null}
    </div>
  );
}

function formatTemplate(template: string, values: Record<string, string>) {
  return Object.entries(values).reduce(
    (result, [key, value]) => result.replaceAll(`{${key}}`, value),

    template,
  );
}
