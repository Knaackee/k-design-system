import { useKLocalization } from "../localization/provider.js";
import { useState, useEffect, useRef, type ReactNode } from "react";
import { KButton } from "../primitives/button.js";
import { KIconButton } from "../actions/icon-button.js";
import { addMonths, validDate, type KPickerLocale } from "./date-values.js";
import type { KPickerLabels } from "./labels.js";
export function CalendarNavigation({
  month,
  onMonthChange,
  onNavigate,
  locale,
  labels,
  min,
  max,
  children,
}: {
  month: string;
  onMonthChange: (month: string) => void;
  onNavigate: () => void;
  locale: KPickerLocale;
  labels: KPickerLabels;
  min?: string;
  max?: string;
  children: ReactNode;
}) {
  const header = useRef<HTMLDivElement>(null),
    mounted = useRef(false);
  const [view, setView] = useState<"days" | "months" | "years">("days");
  useEffect(() => {
    if (!mounted.current) {
      mounted.current = true;
      return;
    }
    const calendar = header.current?.closest(".k-picker-calendar");
    const target =
      view === "days"
        ? calendar?.querySelector<HTMLElement>('[data-date][tabindex="0"]')
        : (calendar?.querySelector<HTMLElement>(
            ".k-picker-period-grid [data-selected]:not(:disabled)",
          ) ??
          calendar?.querySelector<HTMLElement>(
            ".k-picker-period-grid button:not(:disabled)",
          ));
    target?.focus();
  }, [view]);

  const [shownYear, setShownYear] = useState(Number(month.slice(0, 4))),
    [page, setPage] = useState(1);
  const year = Number(month.slice(0, 4)),
    monthIndex = Number(month.slice(5)) - 1;
  const names = useKLocalization(locale).calendar.months;
  const lowYear = min ? Number(min.slice(0, 4)) : 1,
    highYear = max ? Number(max.slice(0, 4)) : 9999;
  const allowedMonth = (m: string) =>
    validDate(`${m}-01`) &&
    m >= "0001-01" &&
    m <= "9999-12" &&
    (!min || m >= min.slice(0, 7)) &&
    (!max || m <= max.slice(0, 7));
  const change = (direction: number) => {
    onNavigate();
    if (view === "days")
      onMonthChange(addMonths(`${month}-01`, direction).slice(0, 7));
    else if (view === "months") setShownYear(shownYear + direction);
    else setPage(page + direction * 12);
  };
  const canChange = (direction: number) =>
    view === "days"
      ? allowedMonth(addMonths(`${month}-01`, direction).slice(0, 7))
      : view === "months"
        ? shownYear + direction >= lowYear && shownYear + direction <= highYear
        : direction < 0
          ? page > lowYear
          : page + 12 <= highYear;
  const chooseMonth = (index: number) => {
    onMonthChange(
      `${String(shownYear).padStart(4, "0")}-${String(index + 1).padStart(2, "0")}`,
    );
    setView("days");
  };
  const chooseYear = (next: number) => {
    let m = `${String(next).padStart(4, "0")}-${month.slice(5)}`;
    if (min && m < min.slice(0, 7)) m = min.slice(0, 7);
    if (max && m > max.slice(0, 7)) m = max.slice(0, 7);
    onMonthChange(m);
    setView("days");
  };
  return (
    <>
      <div className="k-picker-month" ref={header}>
        <KIconButton
          icon="chevron-left"
          label={
            view === "days"
              ? labels.previousMonth
              : view === "months"
                ? labels.previousYear
                : labels.previousYears
          }
          disabled={!canChange(-1)}
          onClick={() => change(-1)}
        />
        {view === "days" ? (
          <>
            <div className="k-picker-month-name">
              <KButton
                variant="ghost"
                aria-label={`${labels.month}: ${names[monthIndex]}`}
                onClick={() => {
                  onNavigate();
                  setShownYear(year);
                  setView("months");
                }}
              >
                {names[monthIndex]}
              </KButton>
            </div>
            <KButton
              variant="ghost"
              aria-label={`${labels.year}: ${year}`}
              onClick={() => {
                onNavigate();
                setPage(Math.floor((year - 1) / 12) * 12 + 1);
                setView("years");
              }}
            >
              {year}
            </KButton>
          </>
        ) : (
          <span className="k-picker-month-range" aria-live="polite">
            {view === "months"
              ? shownYear
              : `${page}–${Math.min(page + 11, 9999)}`}
          </span>
        )}
        <KIconButton
          icon="chevron-right"
          label={
            view === "days"
              ? labels.nextMonth
              : view === "months"
                ? labels.nextYear
                : labels.nextYears
          }
          disabled={!canChange(1)}
          onClick={() => change(1)}
        />
      </div>
      {view === "days" ? (
        children
      ) : (
        <div
          className="k-picker-period-grid"
          role="group"
          aria-label={view === "months" ? labels.month : labels.year}
        >
          {Array.from({ length: 12 }, (_, i) => {
            const n = page + i;
            return (
              <button
                type="button"
                className="k-picker-day"
                key={i}
                aria-label={view === "months" ? names[i] : String(n)}
                disabled={
                  view === "months"
                    ? !allowedMonth(
                        `${String(shownYear).padStart(4, "0")}-${String(i + 1).padStart(2, "0")}`,
                      )
                    : n < lowYear || n > highYear
                }
                data-selected={
                  (view === "months"
                    ? shownYear === year && i === monthIndex
                    : n === year) || undefined
                }
                onClick={() =>
                  view === "months" ? chooseMonth(i) : chooseYear(n)
                }
              >
                {view === "months" ? names[i].slice(0, 3) : n}
              </button>
            );
          })}
        </div>
      )}
    </>
  );
}
