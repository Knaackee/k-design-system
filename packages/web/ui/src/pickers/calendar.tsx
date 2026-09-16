import { useKLocalization } from "../localization/provider.js";
import { useEffect, useRef, useState, type KeyboardEvent } from "react";
import { CalendarNavigation } from "./calendar-navigation.js";
import {
  addDays,
  addMonths,
  dateKey,
  fromDateKey,
  validDate,
  type KPickerLocale,
  type KDateFormat,
  formatDate,
} from "./date-values.js";
import type { KPickerLabels } from "./labels.js";
export function PickerCalendar({
  value,
  onChange,
  onNavigate,
  locale,
  dateFormat,
  labels,
  min,
  max,
}: {
  value: string;
  onChange: (value: string) => void;
  onNavigate: () => void;
  locale: KPickerLocale;
  dateFormat: KDateFormat;
  labels: KPickerLabels;
  min?: string;
  max?: string;
}) {
  const { calendar } = useKLocalization(locale);
  const bounded = min && value < min ? min : max && value > max ? max : value;
  const [active, setActive] = useState(bounded);
  const [month, setMonth] = useState(bounded.slice(0, 7));
  const grid = useRef<HTMLDivElement>(null);
  const focusNext = useRef(false);
  const allowed = (day: string) =>
    validDate(day) && (!min || day >= min) && (!max || day <= max);
  useEffect(() => {
    setActive(bounded);
    setMonth(bounded.slice(0, 7));
  }, [bounded]);
  useEffect(() => {
    if (focusNext.current) {
      grid.current
        ?.querySelector<HTMLButtonElement>(`[data-date="${active}"]`)
        ?.focus();
      focusNext.current = false;
    }
  }, [active, month]);
  const first = fromDateKey(`${month}-01`),
    weekStart = calendar.firstDay;
  const start = addDays(
    dateKey(first),
    -((first.getUTCDay() - weekStart + 7) % 7),
  );
  const weekdays = Array.from(
    { length: 7 },
    (_, i) => calendar.weekdays[(i + weekStart) % 7],
  );
  const move = (next: string, focus: boolean) => {
    if (min && next < min) next = min;
    if (max && next > max) next = max;
    if (!validDate(next)) return;
    focusNext.current = focus;
    setActive(next);
    setMonth(next.slice(0, 7));
  };
  function keyDown(event: KeyboardEvent<HTMLButtonElement>, day: string) {
    let next: string | undefined;
    if (event.key === "ArrowLeft") next = addDays(day, -1);
    if (event.key === "ArrowRight") next = addDays(day, 1);
    if (event.key === "ArrowUp") next = addDays(day, -7);
    if (event.key === "ArrowDown") next = addDays(day, 7);
    const weekday = (fromDateKey(day).getUTCDay() - weekStart + 7) % 7;
    if (event.key === "Home") next = addDays(day, -weekday);
    if (event.key === "End") next = addDays(day, 6 - weekday);
    if (event.key === "PageUp")
      next = addMonths(day, event.shiftKey ? -12 : -1);
    if (event.key === "PageDown")
      next = addMonths(day, event.shiftKey ? 12 : 1);
    if (next) {
      event.preventDefault();
      move(next, true);
    }
  }
  return (
    <div className="k-picker-calendar">
      <CalendarNavigation
        month={month}
        onNavigate={onNavigate}
        locale={locale}
        labels={labels}
        min={min}
        max={max}
        onMonthChange={(next) =>
          move(
            addMonths(
              active,
              (Number(next.slice(0, 4)) - Number(month.slice(0, 4))) * 12 +
                Number(next.slice(5)) -
                Number(month.slice(5)),
            ),
            true,
          )
        }
      >
        <div
          role="grid"
          aria-label={labels.date}
          className="k-picker-grid"
          ref={grid}
        >
          <div role="row" className="k-picker-week">
            {weekdays.map((day, i) => (
              <span role="columnheader" key={i} aria-label={day}>
                {day.slice(0, 2)}
              </span>
            ))}
          </div>
          {Array.from({ length: 6 }, (_, week) => (
            <div role="row" className="k-picker-week" key={week}>
              {Array.from({ length: 7 }, (_, column) => {
                const day = addDays(start, week * 7 + column);
                return (
                  <div role="gridcell" aria-selected={day === value} key={day}>
                    <button
                      type="button"
                      className="k-picker-day"
                      data-date={day}
                      data-selected={day === value || undefined}
                      data-outside={day.slice(0, 7) !== month || undefined}
                      disabled={!allowed(day)}
                      tabIndex={day === active ? 0 : -1}
                      aria-label={formatDate(day, dateFormat)}
                      onKeyDown={(e) => keyDown(e, day)}
                      onFocus={() => setActive(day)}
                      onClick={() => {
                        setActive(day);
                        onChange(day);
                      }}
                    >
                      {fromDateKey(day).getUTCDate()}
                    </button>
                  </div>
                );
              })}
            </div>
          ))}
        </div>
      </CalendarNavigation>
    </div>
  );
}
