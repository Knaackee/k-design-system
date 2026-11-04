import { CalendarEvent, K_CALENDAR_EVENT_MIME } from "./calendar-event.js";
import {
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type PointerEvent as ReactPointerEvent,
} from "react";
import { useKLocalization } from "../localization/provider.js";
import {
  calendarDays,
  instantSlot,
  intersects,
  shiftSlot,
  slot,
  slotNumber,
  timeLanes,
  fromDateKey,
  addDays,
  calendarMoveDuration,
  type CalendarEntry,
} from "./calendar-model.js";
import { useCalendarInteraction } from "./calendar-interaction.js";
import type { KCalendarProps, KCalendarSelection } from "./calendar-types.js";
export type * from "./calendar-types.js";
export { kCalendarSlotToDate } from "./calendar-model.js";
export { K_CALENDAR_EVENT_MIME } from "./calendar-event.js";

/** Controlled calendar surface. Compose navigation, filters and panels outside it. */
export function KCalendar<T>(props: KCalendarProps<T>) {
  const localization = useKLocalization(props.locale);
  const zone = props.timeZone ?? localization.timeZone,
    locale = props.locale ?? localization.calendarLocale;
  const {
    date,
    view,
    events,
    getEventId,
    getEventStart,
    getEventEnd,
    renderEvent,
  } = props;
  const startHour = props.startHour ?? 0,
    endHour = props.endHour ?? 24,
    step = props.stepMinutes ?? 30;
  const hourHeight = props.hourHeight ?? 56,
    minDayWidth = props.minDayWidth ?? 160;
  const firstDay = props.firstDayOfWeek ?? localization.calendar.firstDay;
  if (!Number.isInteger(firstDay) || firstDay < 0 || firstDay > 6)
    throw new RangeError("firstDayOfWeek must be 0–6");
  if (
    !Number.isInteger(startHour) ||
    !Number.isInteger(endHour) ||
    startHour < 0 ||
    endHour > 24 ||
    startHour >= endHour
  )
    throw new RangeError("Invalid visible hours");
  if (!Number.isInteger(step) || step <= 0 || 60 % step !== 0)
    throw new RangeError("stepMinutes must divide one hour");
  if (
    hourHeight <= 0 ||
    minDayWidth <= 0 ||
    (props.defaultDurationMinutes ?? step) <= 0
  )
    throw new RangeError("Calendar dimensions and duration must be positive");
  const days = calendarDays(date, view, zone, firstDay);
  const labels = {
    allDay: locale.startsWith("de") ? "Ganztägig" : "All day",
    create: locale.startsWith("de") ? "Termin erstellen" : "Create event",
    resizeStart: locale.startsWith("de") ? "Beginn ändern" : "Change start",
    resizeEnd: locale.startsWith("de") ? "Ende ändern" : "Change end",
    ...props.labels,
  };
  const root = useRef<HTMLDivElement>(null);
  const interaction = useCalendarInteraction(root, props, zone);
  useEffect(() => {
    root.current?.scrollTo({ left: 0 });
  }, [date, view]);
  const compact = props.requireLongPress || interaction.portrait;
  const swipe = useRef<{
    id: number;
    x: number;
    y: number;
    atStart: boolean;
    atEnd: boolean;
    startedAt: number;
    onEvent: boolean;
  } | null>(null);
  const [keyboardMinute, setKeyboardMinute] = useState(startHour * 60);
  const entries: CalendarEntry<T>[] = events.flatMap((event) => {
    const start = getEventStart(event);
    if (!start) return [];
    const allDay = props.getEventAllDay?.(event) ?? false;
    const a = instantSlot(start, allDay, zone),
      end = getEventEnd(event);
    const b = end
      ? instantSlot(end, allDay, zone)
      : shiftSlot(a, allDay ? 1440 : (props.defaultDurationMinutes ?? step));
    return slotNumber(b) > slotNumber(a)
      ? [{ event, id: getEventId(event), start: a, end: b }]
      : [];
  });
  const formatDay = (key: string, weekdayOnly = false) =>
    new Intl.DateTimeFormat(locale, {
      timeZone: "UTC",
      weekday: "short",
      ...(!weekdayOnly
        ? { day: "numeric" as const, month: "short" as const }
        : {}),
    }).format(fromDateKey(key));
  const renderItem = (entry: CalendarEntry<T>, compact: boolean) => (
    <CalendarEvent
      props={props}
      entry={entry}
      compact={compact}
      labels={labels}
      interaction={interaction}
    />
  );
  function createAt(key: string, allDay: boolean) {
    const a = slot(key, allDay ? 0 : keyboardMinute, allDay, zone);
    interaction.create({
      start: a,
      end: shiftSlot(a, allDay ? 1440 : (props.defaultDurationMinutes ?? step)),
    });
  }
  function swipeStart(e: ReactPointerEvent<HTMLDivElement>) {
    const node = root.current;
    if (!node || !compact || !props.onNavigate || e.button !== 0) return;
    swipe.current = {
      id: e.pointerId,
      x: e.clientX,
      y: e.clientY,
      atStart: node.scrollLeft <= 1,
      atEnd: node.scrollLeft >= node.scrollWidth - node.clientWidth - 1,
      startedAt: performance.now(),
      onEvent: !!(e.target as HTMLElement).closest(".k-calendar-event"),
    };
  }
  function swipeEnd(e: ReactPointerEvent<HTMLDivElement>) {
    const start = swipe.current;
    swipe.current = null;
    if (!start || start.id !== e.pointerId || !props.onNavigate) return;
    if (
      interaction.previewEntryId ||
      (start.onEvent && performance.now() - start.startedAt >= 450)
    )
      return;
    const dx = e.clientX - start.x;
    const dy = e.clientY - start.y;
    if (Math.abs(dx) < 48 || Math.abs(dx) <= Math.abs(dy) * 1.2) return;
    const direction: -1 | 1 = dx < 0 ? 1 : -1;
    if (
      (direction === 1 && !start.atEnd) ||
      (direction === -1 && !start.atStart)
    )
      return;
    props.onNavigate(direction);
  }
  function cell(
    key: string,
    allDay: boolean,
    className: string,
    style?: CSSProperties,
  ) {
    return (
      <div
        key={key}
        className={className}
        style={style}
        data-calendar-slot={key}
        data-all-day={allDay}
        tabIndex={props.onCreate ? 0 : undefined}
        role="group"
        aria-label={`${labels.create}: ${formatDay(key)}${allDay ? ` · ${labels.allDay}` : ` · ${Math.floor(keyboardMinute / 60)}:${String(keyboardMinute % 60).padStart(2, "0")}`}`}
        onPointerDown={(e) => interaction.begin(e)}
        onKeyDown={(e) => {
          if (e.target !== e.currentTarget) return;
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            createAt(key, allDay);
          }
          if (!allDay && ["ArrowUp", "ArrowDown"].includes(e.key)) {
            e.preventDefault();
            setKeyboardMinute((v) =>
              Math.max(
                startHour * 60,
                Math.min(
                  endHour * 60 - step,
                  v + (e.key === "ArrowUp" ? -step : step),
                ),
              ),
            );
          }
        }}
        onDragOver={(e) => {
          if (props.onEventMove) e.preventDefault();
        }}
        onDrop={(e) => {
          e.preventDefault();
          const event = events.find(
            (item) =>
              getEventId(item) ===
              e.dataTransfer.getData(K_CALENDAR_EVENT_MIME),
          );
          if (!event) return;
          const minute = allDay
            ? 0
            : Math.max(
                startHour * 60,
                Math.min(
                  endHour * 60 - step,
                  Math.floor(
                    (startHour * 60 +
                      ((e.clientY -
                        e.currentTarget.getBoundingClientRect().top) /
                        hourHeight) *
                        60) /
                      step,
                  ) * step,
                ),
              );
          const start = getEventStart(event),
            end = getEventEnd(event);
          const sourceAllDay = props.getEventAllDay?.(event) ?? false;
          const value = {
            event,
            eventId: getEventId(event),
            target: slot(key, minute, allDay, zone),
            durationMinutes: calendarMoveDuration(
              start,
              end,
              sourceAllDay,
              allDay,
              undefined,
              props.defaultDurationMinutes ?? step,
              step,
            ),
          };
          if (props.canMove?.(value) !== false) props.onEventMove?.(value);
        }}
      >
        {view === "month" && (
          <span className="k-calendar-date">{Number(key.slice(-2))}</span>
        )}
      </div>
    );
  }
  function selectionForDay(selection: KCalendarSelection, key: string) {
    const base = slotNumber(slot(key, 0, selection.start.allDay, zone));
    return {
      start: Math.max(startHour * 60, slotNumber(selection.start) - base),
      end: Math.min(endHour * 60, slotNumber(selection.end) - base),
    };
  }
  function spans(week: string[], allDayOnly: boolean) {
    const preview = interaction.preview;
    const layoutEntries = entries;
    const items = layoutEntries.filter(
      (e) =>
        (!allDayOnly || e.start.allDay) && intersects(e, week[0], week.at(-1)!),
    );
    const lanes: number[] = [];
    const positioned = items
      .sort(
        (a, b) =>
          slotNumber(a.start) - slotNumber(b.start) ||
          slotNumber(b.end) - slotNumber(a.end),
      )
      .map((entry) => {
        const start = Math.max(
          0,
          Math.floor(
            (slotNumber(entry.start) -
              slotNumber(slot(week[0], 0, true, zone))) /
              1440,
          ),
        );
        const end = Math.min(
          week.length,
          Math.ceil(
            (slotNumber(entry.end) - slotNumber(slot(week[0], 0, true, zone))) /
              1440,
          ),
        );
        let lane = lanes.findIndex((v) => v <= start);
        if (lane < 0) lane = lanes.length;
        lanes[lane] = end;
        return { entry, start, end, lane };
      });
    let highlight = null;
    if (
      preview &&
      interaction.previewEntryId == null &&
      (preview.start.allDay || !allDayOnly)
    ) {
      const base = slotNumber(slot(week[0], 0, true, zone));
      const a = Math.max(
        0,
        Math.floor((slotNumber(preview.start) - base) / 1440),
      );
      const b = Math.min(
        week.length,
        Math.ceil((slotNumber(preview.end) - base) / 1440),
      );
      if (b > a)
        highlight = (
          <div
            className="k-calendar-selection"
            style={{
              left: `${(a / week.length) * 100}%`,
              width: `${((b - a) / week.length) * 100}%`,
              top: allDayOnly ? 0 : 24,
              bottom: 0,
            }}
          >
            <span className="k-calendar-selection-label">{labels.create}</span>
          </div>
        );
    }
    const selectMonthDay =
      !allDayOnly && view === "month" ? props.onMonthDayOpen : undefined;
    const compactMonth = view === "month" && compact;
    const monthIndicators =
      view === "month" &&
      (props.monthEventDisplay === "indicators" ||
        (props.monthEventDisplay !== "appointments" && compact));
    const sizedMonth = compactMonth || selectMonthDay;
    const rowHeight = sizedMonth
      ? ((props.height ?? 680) - 44) / 6
      : Math.max(
          allDayOnly ? 40 : 116,
          (allDayOnly ? 4 : 28) + lanes.length * 30,
        );
    const visibleMonthLanes = selectMonthDay
      ? Math.max(0, Math.floor((rowHeight - 28) / 30))
      : Infinity;
    const entriesOnDay = (day: number) =>
      positioned.filter(({ start, end }) => start <= day && end > day);
    return (
      <div
        className={`k-calendar-span-row ${allDayOnly ? "" : "k-calendar-month-week"}`}
        style={{
          minHeight: rowHeight,
          height: sizedMonth ? rowHeight : undefined,
          overflow: sizedMonth ? "hidden" : undefined,
        }}
      >
        <div
          className="k-calendar-span-cells"
          style={{
            gridTemplateColumns: `repeat(${week.length},minmax(0,1fr))`,
          }}
        >
          {week.map((key, day) => {
            if (!selectMonthDay) return cell(key, true, "k-calendar-span-cell");
            const dayEntries = entriesOnDay(day);
            const overflowCount = monthIndicators
              ? 0
              : dayEntries.filter(({ lane }) => lane >= visibleMonthLanes)
                  .length;
            return (
              <button
                key={key}
                type="button"
                className={`k-calendar-span-cell k-calendar-month-day${monthIndicators ? " k-calendar-month-day--indicators" : ""}`}
                data-month-day={key}
                aria-label={`${formatDay(key)} · ${dayEntries.length}`}
                aria-pressed={props.selectedMonthDay === key}
                onClick={() =>
                  selectMonthDay(
                    key,
                    dayEntries.map(({ entry }) => entry.event),
                  )
                }
              >
                <span className="k-calendar-date">{Number(key.slice(-2))}</span>
                {overflowCount > 0 && (
                  <span
                    className="k-calendar-month-day-more"
                    aria-hidden="true"
                  >
                    +{overflowCount}
                  </span>
                )}
              </button>
            );
          })}
        </div>
        {highlight}
        {monthIndicators && (
          <div
            className="k-calendar-month-indicators"
            style={{
              gridTemplateColumns: `repeat(${week.length},minmax(0,1fr))`,
            }}
          >
            {week.map((key, day) => {
              const dayEntries = entriesOnDay(day);
              const indicators = dayEntries
                .slice(0, 3)
                .map(({ entry }) => (
                  <span key={entry.id} className="k-calendar-month-indicator" />
                ));
              const overflow = dayEntries.length > 3 && (
                <span className="k-calendar-month-overflow">
                  +{dayEntries.length - 3}
                </span>
              );
              if (selectMonthDay) {
                return (
                  <span
                    className="k-calendar-month-indicator-cell k-calendar-month-indicator-cell--decorative"
                    aria-hidden="true"
                    key={key}
                  >
                    {indicators}
                  </span>
                );
              }
              return (
                <button
                  type="button"
                  className="k-calendar-month-indicator-cell"
                  key={key}
                  aria-label={`${formatDay(key)} · ${dayEntries.length}`}
                  disabled={dayEntries.length === 0}
                  onClick={() => {
                    const values = dayEntries.map(({ entry }) => entry.event);
                    if (props.onMonthDayOpen) props.onMonthDayOpen(key, values);
                    else if (values[0]) props.onEventOpen?.(values[0]);
                  }}
                >
                  {indicators}
                  {overflow}
                </button>
              );
            })}
          </div>
        )}
        {!monthIndicators &&
          positioned.map(({ entry, start, end, lane }) => {
            if (
              entry.id === interaction.previewEntryId ||
              lane >= visibleMonthLanes
            )
              return null;
            return (
              <div
                key={entry.id}
                className="k-calendar-span-event"
                inert={selectMonthDay ? true : undefined}
                style={{
                  pointerEvents: selectMonthDay ? "none" : undefined,
                  left: `calc(${(start / week.length) * 100}% + 4px)`,
                  width: `calc(${((end - start) / week.length) * 100}% - 8px)`,
                  top: (allDayOnly ? 4 : 28) + lane * 30,
                }}
              >
                {renderItem(entry, true)}
              </div>
            );
          })}
        {preview &&
          interaction.previewEntryId &&
          (interaction.previewEntry ??
            entries.find((entry) => entry.id === interaction.previewEntryId)) &&
          (!allDayOnly || preview.start.allDay) &&
          (() => {
            const entry =
              interaction.previewEntry ??
              entries.find((item) => item.id === interaction.previewEntryId)!;
            const base = slotNumber(slot(week[0], 0, true, zone));
            const start = Math.max(
              0,
              Math.floor((slotNumber(preview.start) - base) / 1440),
            );
            const end = Math.min(
              week.length,
              Math.ceil((slotNumber(preview.end) - base) / 1440),
            );
            return end > start ? (
              <div
                className="k-calendar-span-event k-calendar-event-dragging"
                style={{
                  left: `calc(${(start / week.length) * 100}% + 4px)`,
                  width: `calc(${((end - start) / week.length) * 100}% - 8px)`,
                  top: allDayOnly ? 4 : 28,
                }}
              >
                {renderItem(
                  { ...entry, start: preview.start, end: preview.end },
                  true,
                )}
              </div>
            ) : null;
          })()}
      </div>
    );
  }
  const count = days.length,
    minWidth = view === "month" ? 0 : 56 + count * minDayWidth;
  return (
    <div
      ref={root}
      className={[
        "k-calendar",
        compact && "k-calendar-compact-interaction",
        view === "month" && compact && "k-calendar-month-compact",
        props.className,
      ]
        .filter(Boolean)
        .join(" ")}
      style={{ height: props.height ?? 680 }}
      aria-label={props.ariaLabel ?? "Calendar"}
      onPointerDownCapture={swipeStart}
      onPointerUpCapture={swipeEnd}
      onPointerCancelCapture={() => (swipe.current = null)}
    >
      <div style={{ minWidth }}>
        {view === "month" ? (
          <>
            <div
              className="k-calendar-month-heading"
              style={{ gridTemplateColumns: "repeat(7,1fr)" }}
            >
              {days.slice(0, 7).map((key) => (
                <strong key={key}>{formatDay(key, true)}</strong>
              ))}
            </div>
            {Array.from({ length: 6 }, (_, i) => (
              <div key={i}>{spans(days.slice(i * 7, i * 7 + 7), false)}</div>
            ))}
          </>
        ) : (
          <>
            <div className="k-calendar-sticky">
              <div
                className="k-calendar-time-header"
                style={{
                  gridTemplateColumns: `56px repeat(${count},minmax(0,1fr))`,
                }}
              >
                <span />
                {days.map((key) => (
                  <strong key={key}>{formatDay(key)}</strong>
                ))}
              </div>
              <div className="k-calendar-all-day">
                <span>{labels.allDay}</span>
                {spans(days, true)}
              </div>
            </div>
            <div
              className="k-calendar-time-body"
              style={{ height: (endHour - startHour) * hourHeight }}
            >
              <div className="k-calendar-hours">
                {Array.from({ length: endHour - startHour }, (_, i) => (
                  <span key={i} style={{ height: hourHeight }}>
                    {String(startHour + i).padStart(2, "0")}:00
                  </span>
                ))}
              </div>
              <div
                className="k-calendar-days"
                style={{
                  gridTemplateColumns: `repeat(${count},minmax(0,1fr))`,
                }}
              >
                {days.map((key) => {
                  const preview =
                    interaction.preview &&
                    interaction.previewEntryId == null &&
                    !interaction.preview.start.allDay
                      ? selectionForDay(interaction.preview, key)
                      : null;
                  const dayEntries = entries.filter(
                    (e) => !e.start.allDay && intersects(e, key, key),
                  );
                  const lanes = timeLanes(dayEntries);
                  const positioned = lanes;
                  const activeEntry = interaction.previewEntryId
                    ? (interaction.previewEntry ??
                      entries.find(
                        (entry) => entry.id === interaction.previewEntryId,
                      ))
                    : undefined;
                  const activeRange =
                    activeEntry && interaction.preview
                      ? selectionForDay(interaction.preview, key)
                      : null;
                  return (
                    <div className="k-calendar-time-column" key={key}>
                      {cell(key, false, "k-calendar-time-day", {
                        height: "100%",
                        backgroundSize: `100% ${hourHeight}px`,
                      })}
                      {positioned.map(({ entry, lane, lanes }) => {
                        if (entry.id === interaction.previewEntryId)
                          return null;
                        const range = selectionForDay(entry, key);
                        if (range.end <= range.start) return null;
                        return (
                          <div
                            className="k-calendar-positioned-event"
                            key={entry.id}
                            style={{
                              top:
                                ((range.start - startHour * 60) / 60) *
                                hourHeight,
                              height: Math.max(
                                24,
                                ((range.end - range.start) / 60) * hourHeight,
                              ),
                              left: `calc(${(lane / lanes) * 100}% + 4px)`,
                              width: `calc(${100 / lanes}% - 8px)`,
                            }}
                          >
                            <CalendarEvent
                              props={props}
                              entry={entry}
                              compact={false}
                              labels={labels}
                              interaction={interaction}
                              dragging={false}
                            />
                          </div>
                        );
                      })}
                      {activeEntry &&
                        activeRange &&
                        activeRange.end > activeRange.start && (
                          <div
                            className="k-calendar-positioned-event k-calendar-event-dragging"
                            style={{
                              top:
                                ((activeRange.start - startHour * 60) / 60) *
                                hourHeight,
                              height: Math.max(
                                24,
                                ((activeRange.end - activeRange.start) / 60) *
                                  hourHeight,
                              ),
                              left: "4px",
                              width: "calc(100% - 8px)",
                            }}
                          >
                            <CalendarEvent
                              props={props}
                              entry={{
                                ...activeEntry,
                                start: interaction.preview!.start,
                                end: interaction.preview!.end,
                              }}
                              compact={false}
                              labels={labels}
                              interaction={interaction}
                              dragging
                            />
                          </div>
                        )}
                      {preview && preview.end > preview.start && (
                        <div
                          className="k-calendar-selection"
                          style={{
                            top:
                              ((preview.start - startHour * 60) / 60) *
                              hourHeight,
                            height:
                              ((preview.end - preview.start) / 60) * hourHeight,
                            left: 0,
                            right: 0,
                          }}
                        >
                          <span className="k-calendar-selection-label">
                            {labels.create}
                          </span>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
