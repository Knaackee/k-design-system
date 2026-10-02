import {
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { activityMonth } from "./activity-month-model.js";
import { activityDayStatus } from "./activity-status-model.js";
import { KBottomSheet } from "../overlays/overlay.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";

export interface KActivityItem {
  id: string;
  title: string;
  date: string | null;
  metadata?: string;
  leading?: ReactNode;
  completed?: boolean;
}
export interface KActivityHeatmapProps {
  items: readonly KActivityItem[];
  mode: "completed" | "upcoming";
  today: string;
  onOpenItem: (id: string) => void;
  onAddDate?: (date: string) => void;
  addLabel?: string;
  phone?: boolean;
}
const dateLabel = (value: string) =>
  new Intl.DateTimeFormat("de-DE", {
    day: "numeric",
    month: "long",
    timeZone: "UTC",
  }).format(new Date(`${value}T12:00:00Z`));

/** Consumer owns filtering, activity dates and detail navigation. */
export function KActivityHeatmap({
  items,
  mode,
  today,
  onOpenItem,
  onAddDate,
  addLabel = "Issue hinzufügen",
  phone = false,
}: KActivityHeatmapProps) {
  const [selectedDay, setDay] = useState<string | null>(null);
  useEffect(() => setDay(null), [mode]);
  const first = new Date(`${today}T12:00:00Z`);
  first.setUTCDate(first.getUTCDate() - ((first.getUTCDay() + 6) % 7) - 91);
  const days = Array.from({ length: 182 }, (_, index) => {
    const date = new Date(first);
    date.setUTCDate(first.getUTCDate() + index);
    return date.toISOString().slice(0, 10);
  });
  const dated = items.filter((item) => item.date);
  const byDay = new Map<string, KActivityItem[]>();
  for (const item of dated) {
    const dayItems = byDay.get(item.date!) ?? [];
    dayItems.push(item);
    byDay.set(item.date!, dayItems);
  }
  const rows = dated.filter((item) => item.date === selectedDay);
  const status = (date: string) => {
    const dayItems = byDay.get(date) ?? [];
    return activityDayStatus(dayItems, mode === "completed");
  };
  const [narrow, setNarrow] = useState(
    () =>
      typeof window !== "undefined" &&
      window.matchMedia("(max-width: 600px)").matches,
  );
  useEffect(() => {
    const media = window.matchMedia("(max-width: 600px)");
    const update = () => setNarrow(media.matches);
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);
  const mobile = phone || narrow;
  const [monthRange, setMonthRange] = useState([0, 2]);
  const monthsRoot = useRef<HTMLDivElement>(null);
  const anchor = useRef<{ key: string; top: number } | null>(null);
  useLayoutEffect(() => {
    if (!anchor.current) return;
    const node = monthsRoot.current?.querySelector<HTMLElement>(
      `[data-month="${anchor.current.key}"]`,
    );
    if (node)
      window.scrollBy(0, node.getBoundingClientRect().top - anchor.current.top);
    anchor.current = null;
  }, [monthRange]);
  const loadMonths = (earlier: boolean) => {
    const node = monthsRoot.current?.querySelector<HTMLElement>("[data-month]");
    if (earlier && node)
      anchor.current = {
        key: node.dataset.month!,
        top: node.getBoundingClientRect().top,
      };
    setMonthRange(([start, end]) =>
      earlier ? [start - 3, end] : [start, end + 3],
    );
  };
  const calendar = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const root = calendar.current;
    const current = root?.querySelector<HTMLElement>("[data-today]");
    if (root && current && mode === "upcoming") {
      root.scrollLeft +=
        current.getBoundingClientRect().left -
        root.getBoundingClientRect().left -
        16;
    } else if (root) root.scrollLeft = 0;
  }, [mode]);
  const renderIssue = (issue: KActivityItem) => (
    <button
      type="button"
      className="k-activity-issue"
      key={issue.id}
      onClick={() => {
        if (mobile) setDay(null);
        onOpenItem(issue.id);
      }}
    >
      <span className="k-activity-project">{issue.leading}</span>
      <span className="k-activity-issue-copy">
        <strong>{issue.title}</strong>
        <small>{issue.metadata ?? issue.id}</small>
        <small className="k-activity-mobile-date">
          {issue.date ? dateLabel(issue.date) : "Ohne Termin"}
        </small>
      </span>
      <span className="k-activity-date">
        {issue.date ? dateLabel(issue.date) : "Ohne Termin"}
      </span>
      <KIcon name="chevron-right" size={16} />
    </button>
  );
  const renderDay = (date: string, includeYear = false) => {
    const day = status(date);
    const outside = mode === "completed" ? date > today : date < today;
    return (
      <button
        type="button"
        key={date}
        disabled={outside && day.count === 0}
        className="k-activity-day"
        data-level={day.level}
        data-status={day.tone}
        data-today={date === today || undefined}
        data-selected={date === selectedDay || undefined}
        aria-pressed={date === selectedDay}
        aria-label={`${dateLabel(date)}${includeYear ? ` ${date.slice(0, 4)}` : ""}: ${day.summary}`}
        title={`${dateLabel(date)} · ${day.summary}`}
        onClick={() => {
          setDay(date === selectedDay ? null : date);
        }}
      >
        {day.count > 0 && (
          <span className="k-activity-status-marker" aria-hidden="true" />
        )}
      </button>
    );
  };
  return (
    <section className={`k-activity${phone ? " k-activity--phone" : ""}`}>
      <div className="k-activity-summary">
        <strong>{items.length} Issues</strong>
        <span className="k-activity-desktop-only">
          {dateLabel(days[0])} – {dateLabel(days[days.length - 1])}
        </span>
      </div>
      <div
        className="k-activity-calendar k-activity-desktop-only"
        ref={calendar}
        role="region"
        aria-label="Aktivität nach Tagen, horizontal scrollbar"
        tabIndex={0}
      >
        <div className="k-activity-months">
          {days.map(
            (date, index) =>
              date.endsWith("-01") && (
                <span
                  key={date}
                  style={{ gridColumn: Math.floor(index / 7) + 1 }}
                >
                  {new Intl.DateTimeFormat("de-DE", {
                    month: "short",
                    timeZone: "UTC",
                  }).format(new Date(`${date}T12:00:00Z`))}
                </span>
              ),
          )}
        </div>
        <div className="k-activity-grid">
          {days.map((date) => renderDay(date))}
        </div>
      </div>
      <div className="k-activity-month-stack" ref={monthsRoot}>
        <KButton variant="ghost" fullWidth onClick={() => loadMonths(true)}>
          Frühere Monate laden
        </KButton>
        {Array.from(
          { length: monthRange[1] - monthRange[0] + 1 },
          (_, index) => {
            const month = activityMonth(monthRange[0] + index, today);
            return (
              <section key={month.key} data-month={month.key}>
                <div className="k-activity-list-header">
                  <h2>
                    {new Intl.DateTimeFormat("de-DE", {
                      month: "long",
                      year: "numeric",
                      timeZone: "UTC",
                    }).format(month.start)}
                  </h2>
                  {month.key === today.slice(0, 7) && (
                    <small>Aktueller Monat</small>
                  )}
                </div>
                <div className="k-activity-month-body">
                  <div className="k-activity-weekdays" aria-hidden="true">
                    {["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"].map((label) => (
                      <span key={label}>{label}</span>
                    ))}
                  </div>
                  <div
                    className="k-activity-month-scroll"
                    tabIndex={0}
                    aria-label="Wochenspalten"
                  >
                    <div
                      className="k-activity-month-grid"
                      style={{
                        gridTemplateColumns: `repeat(${month.weeks}, 44px)`,
                      }}
                    >
                      {month.cells.map((date, i) =>
                        date ? (
                          renderDay(date, true)
                        ) : (
                          <span key={`blank-${i}`} />
                        ),
                      )}
                    </div>
                  </div>
                </div>
              </section>
            );
          },
        )}
        <KButton variant="ghost" fullWidth onClick={() => loadMonths(false)}>
          Weitere Monate laden
        </KButton>
      </div>
      <div className="k-activity-legend">
        <span>
          {mode === "completed" ? "Abschlüsse pro Tag" : "Issues pro Tag"} ·
          Heute: {dateLabel(today)}
        </span>
        <span>Amber: offen · Grün: erledigt · Intensität: 1, 2–3, 4–7, 8+</span>
      </div>
      {selectedDay && (
        <div className="k-activity-desktop-only">
          <div className="k-activity-list-header">
            <h2>{dateLabel(selectedDay)}</h2>
            <div className="k-activity-day-actions">
              {onAddDate && (
                <KButton onClick={() => onAddDate(selectedDay)}>
                  {addLabel}
                </KButton>
              )}
              <KButton
                variant="ghost"
                onClick={() => {
                  setDay(null);
                }}
              >
                Schließen
              </KButton>
            </div>
          </div>
          <p className="k-activity-day-summary">
            {status(selectedDay).summary}
          </p>
          <div aria-live="polite">
            {rows.length ? (
              rows.map(renderIssue)
            ) : (
              <p className="k-activity-empty">Keine Issues an diesem Tag.</p>
            )}
          </div>
        </div>
      )}
      {mobile && (
        <KBottomSheet
          open={selectedDay !== null}
          onOpenChange={(open) => {
            if (!open) {
              setDay(null);
            }
          }}
          title={selectedDay ? dateLabel(selectedDay) : "Issue"}
          description={
            mode === "completed" ? "Abgeschlossene Issues" : "Issues"
          }
          closeLabel="Schließen"
          className="k-activity-sheet"
        >
          {selectedDay && (
            <>
              <p className="k-activity-day-summary">
                {status(selectedDay).summary}
              </p>
              {onAddDate && (
                <KButton fullWidth onClick={() => onAddDate(selectedDay)}>
                  {addLabel}
                </KButton>
              )}
              {rows.length ? (
                rows.map(renderIssue)
              ) : (
                <p className="k-activity-empty">Keine Issues an diesem Tag.</p>
              )}
            </>
          )}
        </KBottomSheet>
      )}
    </section>
  );
}
