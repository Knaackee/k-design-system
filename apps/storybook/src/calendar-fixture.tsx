import { useEffect, useRef, useState } from "react";
import {
  KBottomSheet,
  KButton,
  KCalendar,
  KDialog,
  KField,
  KFilterBar,
  KIcon,
  KIconButton,
  KInput,
  KSelect,
  KToolbar,
  useKLocalization,
  kCalendarSlotToDate,
  type KCalendarMove,
  type KCalendarResize,
  type KCalendarSlot,
  type KCalendarView,
} from "@k-design-system/ui";
import {
  calendarAnchor,
  calendarDemoEvents,
  calendarDemoLabels,
  calendarNavigate,
  type CalendarDemoEvent,
} from "./calendar-fixture-data.js";
import "./calendar-fixture.css";

type Selection = { start: KCalendarSlot; end: KCalendarSlot };
const timeZone = "Europe/Berlin";

function selectionDescription(
  selection: Selection,
  locale: string,
  allDayLabel: string,
) {
  const start = kCalendarSlotToDate(selection.start);
  const end = kCalendarSlotToDate(selection.end);
  if (!start || !end) return "";
  const allDay = selection.start.allDay;
  const formatter = new Intl.DateTimeFormat(locale, {
    dateStyle: "medium",
    ...(allDay ? {} : { timeStyle: "short" as const }),
    timeZone: allDay ? "UTC" : selection.start.timeZone,
  });
  const last = allDay ? new Date(end.getTime() - 86400000) : end;
  const range = formatter.formatRange(start, last);
  return allDay ? `${range} · ${allDayLabel}` : range;
}

export function CalendarFixture({
  initialView = "week",
}: {
  initialView?: KCalendarView;
}) {
  const { locale, calendarLocale, calendar } = useKLocalization();
  const labels = calendarDemoLabels[locale.startsWith("de") ? "de" : "en"];
  const [date, setDate] = useState(calendarAnchor);
  const [view, setView] = useState(initialView);
  const [events, setEvents] = useState(calendarDemoEvents);
  const [project, setProject] = useState<string | null>(null);
  const [unplannedOpen, setUnplannedOpen] = useState(false);
  const [scheduling, setScheduling] = useState<string | null>(null);
  const [selection, setSelection] = useState<Selection | null>(null);
  const [editing, setEditing] = useState<CalendarDemoEvent | null>(null);
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [compact, setCompact] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const nextId = useRef(200);
  useEffect(() => {
    const element = root.current;
    if (!element) return;
    const update = () => {
      const width = element.getBoundingClientRect().width;
      setCompact(width < 900 || width < window.innerHeight);
    };
    const observer = new ResizeObserver(update);
    observer.observe(element);
    window.addEventListener("resize", update);
    update();
    return () => {
      observer.disconnect();
      window.removeEventListener("resize", update);
    };
  }, []);
  const visibleEvents = events.filter(
    (event) => !project || event.project === project,
  );
  const unplanned = visibleEvents.filter((event) => !event.start);
  const period = new Intl.DateTimeFormat(calendarLocale, {
    month: "long",
    year: "numeric",
    timeZone,
  }).format(date);

  function move(change: KCalendarMove<CalendarDemoEvent>) {
    const start = kCalendarSlotToDate(change.target);
    if (!start) return;
    setEvents((current) =>
      current.map((event) =>
        event.id === change.eventId
          ? {
              ...event,
              start,
              allDay: change.target.allDay,
              end: new Date(
                start.getTime() +
                  Math.max(
                    change.target.allDay ? 1440 : 30,
                    change.durationMinutes,
                  ) *
                    60000,
              ),
            }
          : event,
      ),
    );
    setMessage(`${change.eventId} · ${change.target.date}`);
  }
  function resize(change: KCalendarResize<CalendarDemoEvent>) {
    const start = kCalendarSlotToDate(change.start);
    const end = kCalendarSlotToDate(change.end);
    if (!start || !end) return;
    setEvents((current) =>
      current.map((event) =>
        event.id === change.eventId ? { ...event, start, end } : event,
      ),
    );
    setMessage(`${change.eventId} · ${labels.save}`);
  }
  function create(range: Selection) {
    if (scheduling) {
      const start = kCalendarSlotToDate(range.start);
      const end = kCalendarSlotToDate(range.end);
      if (!start || !end) return;
      setEvents((current) =>
        current.map((event) =>
          event.id === scheduling
            ? { ...event, start, end, allDay: range.start.allDay }
            : event,
        ),
      );
      setScheduling(null);
      return;
    }
    setTitle("");
    setEditing(null);
    setSelection(range);
    const start = kCalendarSlotToDate(range.start);
    const end = kCalendarSlotToDate(range.end);
    if (start && end)
      setEvents((current) => [
        ...current.filter((event) => event.id !== "CAL-DRAFT"),
        {
          id: "CAL-DRAFT",
          title: labels.create,
          project: project ?? "Orbit",
          start,
          end,
          allDay: range.start.allDay,
        },
      ]);
  }
  function save() {
    if (!title.trim()) return;
    if (editing)
      setEvents((current) =>
        current.map((event) =>
          event.id === editing.id ? { ...event, title: title.trim() } : event,
        ),
      );
    else if (selection) {
      const start = kCalendarSlotToDate(selection.start);
      const end = kCalendarSlotToDate(selection.end);
      if (!start || !end) return;
      setEvents((current) => [
        ...current.filter((event) => event.id !== "CAL-DRAFT"),
        {
          id: `CAL-${nextId.current++}`,
          title: title.trim(),
          project: project ?? "Orbit",
          start,
          end,
          allDay: selection.start.allDay,
        },
      ]);
    }
    setSelection(null);
    setEditing(null);
  }
  const unplannedContent = (
    <div className="calendar-demo-unplanned">
      {unplanned.length === 0 && <p>{labels.empty}</p>}
      {unplanned.map((event) => (
        <div key={event.id} className="calendar-demo-unplanned-item">
          <strong>{event.title}</strong>
          <small>{event.project}</small>
          <KButton
            variant="secondary"
            onClick={() => {
              setScheduling(event.id);
              setUnplannedOpen(false);
            }}
          >
            {labels.schedule}
          </KButton>
        </div>
      ))}
    </div>
  );
  const Editor = compact ? KBottomSheet : KDialog;
  return (
    <div className="calendar-demo" ref={root}>
      <div className="calendar-demo-header">
        <KToolbar label={labels.calendar}>
          <KButton variant="secondary" onClick={() => setDate(new Date())}>
            {labels.today}
          </KButton>
          <KIconButton
            icon="chevron-left"
            label={labels.previous}
            onClick={() => setDate(calendarNavigate(date, view, -1))}
          />
          <KIconButton
            icon="chevron-right"
            label={labels.next}
            onClick={() => setDate(calendarNavigate(date, view, 1))}
          />
        </KToolbar>
        <span className="calendar-demo-period">{period}</span>
        <KFilterBar
          label={labels.filters}
          onReset={project ? () => setProject(null) : undefined}
        >
          <div className="calendar-demo-select">
            <KSelect
              label={labels.project}
              value={project ?? "all"}
              onValueChange={(value) =>
                setProject(value === "all" ? null : value)
              }
              options={[
                { value: "all", label: labels.allProjects },
                ...["Orbit", "Workspace", "Research"].map((value) => ({
                  value,
                  label: value,
                })),
              ]}
            />
          </div>
          <div className="calendar-demo-select">
            <KSelect
              label={labels.view}
              value={view}
              onValueChange={(value) => setView(value as KCalendarView)}
              options={[
                { value: "day", label: labels.day },
                { value: "three-day", label: labels.threeDay },
                { value: "week", label: labels.week },
                { value: "month", label: labels.month },
              ]}
            />
          </div>
          <KButton
            variant="secondary"
            aria-expanded={unplannedOpen}
            onClick={() => setUnplannedOpen(!unplannedOpen)}
          >
            <KIcon name="calendar" size={16} /> {labels.unplanned} (
            {unplanned.length})
          </KButton>
        </KFilterBar>
      </div>
      <div className="calendar-demo-status" role="status">
        {scheduling ? (
          <>
            {labels.pickSlot}
            <KButton variant="ghost" onClick={() => setScheduling(null)}>
              {labels.cancel}
            </KButton>
          </>
        ) : (
          message || labels.select
        )}
      </div>
      <div className="calendar-demo-layout">
        <div className="calendar-demo-grid">
          <KCalendar
            date={date}
            view={view}
            events={visibleEvents}
            getEventId={(event) => event.id}
            getEventStart={(event) => event.start}
            getEventEnd={(event) => event.end}
            getEventAllDay={(event) => !!event.allDay}
            onEventOpen={(event) => {
              setEditing(event);
              setSelection(null);
              setTitle(event.title);
            }}
            onEventMove={move}
            onEventResize={resize}
            onCreate={create}
            requireLongPress={compact}
            startHour={7}
            endHour={24}
            timeZone={timeZone}
            locale={calendarLocale}
            firstDayOfWeek={calendar.firstDay}
            renderEvent={({ event, compact: compactEvent }) => (
              <span className="calendar-demo-event">
                <strong className="calendar-demo-event-title">
                  {event.title}
                </strong>
                {!compactEvent && (
                  <small className="calendar-demo-event-project">
                    <KIcon name="folder" size={12} />
                    {event.project}
                  </small>
                )}
              </span>
            )}
          />
        </div>
        {unplannedOpen && !compact && (
          <aside
            className="calendar-demo-sidebar"
            aria-label={labels.unplanned}
          >
            <div className="calendar-demo-sidebar-header">
              <strong>{labels.unplanned}</strong>
              <KIconButton
                icon="x"
                label={labels.close}
                onClick={() => setUnplannedOpen(false)}
              />
            </div>
            {unplannedContent}
          </aside>
        )}
      </div>
      <KBottomSheet
        open={unplannedOpen && compact}
        onOpenChange={setUnplannedOpen}
        title={labels.unplanned}
        closeLabel={labels.close}
      >
        {unplannedContent}
      </KBottomSheet>
      <Editor
        open={!!selection || !!editing}
        onOpenChange={(open) => {
          if (!open) {
            setEvents((current) =>
              current.filter((event) => event.id !== "CAL-DRAFT"),
            );
            setSelection(null);
            setEditing(null);
          }
        }}
        title={editing ? editing.id : labels.create}
        closeLabel={labels.close}
        actions={
          <>
            <KButton
              variant="ghost"
              onClick={() => {
                setSelection(null);
                setEditing(null);
              }}
            >
              {labels.cancel}
            </KButton>
            <KButton disabled={!title.trim()} onClick={save}>
              {labels.save}
            </KButton>
          </>
        }
      >
        <div className="calendar-demo-editor">
          <KField label={labels.title}>
            <KInput
              autoFocus
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") save();
              }}
            />
          </KField>
          {selection && (
            <span>
              {selectionDescription(selection, calendarLocale, labels.allDay)}
            </span>
          )}
          {!selection && editing?.start && editing.end && (
            <span>
              {new Intl.DateTimeFormat(calendarLocale, {
                dateStyle: "medium",
                ...(editing.allDay ? {} : { timeStyle: "short" as const }),
                timeZone: editing.allDay ? "UTC" : timeZone,
              }).formatRange(
                editing.start,
                editing.allDay
                  ? new Date(editing.end.getTime() - 86400000)
                  : editing.end,
              )}
              {editing.allDay ? ` · ${labels.allDay}` : ""}
            </span>
          )}
        </div>
      </Editor>
    </div>
  );
}

