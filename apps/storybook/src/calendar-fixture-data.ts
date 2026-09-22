import type { KCalendarView } from "@k-design-system/ui";

export type CalendarDemoEvent = {
  id: string;
  title: string;
  project: string;
  allDay?: boolean;
  start: Date | null;
  end: Date | null;
};
export const calendarAnchor = new Date("2026-09-21T12:00:00Z");
export const calendarDemoEvents: CalendarDemoEvent[] = [
  {
    id: "CAL-101",
    title: "Design review",
    project: "Orbit",
    start: new Date("2026-09-21T09:00:00+02:00"),
    end: new Date("2026-09-21T10:30:00+02:00"),
  },
  {
    id: "CAL-102",
    title: "Planning",
    project: "Workspace",
    start: new Date("2026-09-22T11:00:00+02:00"),
    end: new Date("2026-09-22T12:00:00+02:00"),
  },
  {
    id: "CAL-103",
    title: "Customer call",
    project: "Orbit",
    start: new Date("2026-09-24T14:00:00+02:00"),
    end: new Date("2026-09-24T15:30:00+02:00"),
  },
  {
    id: "CAL-104",
    title: "Unscheduled research",
    project: "Research",
    start: null,
    end: null,
  },
  {
    id: "CAL-105",
    title: "Release preparation",
    project: "Orbit",
    allDay: true,
    start: new Date("2026-09-21T00:00:00Z"),
    end: new Date("2026-09-24T00:00:00Z"),
  },
  {
    id: "CAL-106",
    title: "Team workshop",
    project: "Workspace",
    allDay: true,
    start: new Date("2026-09-22T00:00:00Z"),
    end: new Date("2026-09-23T00:00:00Z"),
  },
  {
    id: "CAL-107",
    title: "Research handoff",
    project: "Research",
    start: new Date("2026-09-21T09:30:00+02:00"),
    end: new Date("2026-09-21T11:00:00+02:00"),
  },
];
export function calendarNavigate(
  date: Date,
  view: KCalendarView,
  direction: number,
) {
  const next = new Date(date);
  if (view === "month") {
    const day = next.getUTCDate();
    next.setUTCDate(1);
    next.setUTCMonth(next.getUTCMonth() + direction);
    const last = new Date(
      Date.UTC(next.getUTCFullYear(), next.getUTCMonth() + 1, 0),
    ).getUTCDate();
    next.setUTCDate(Math.min(day, last));
  } else
    next.setUTCDate(
      next.getUTCDate() +
        direction * (view === "week" ? 7 : view === "three-day" ? 3 : 1),
    );
  return next;
}
export const calendarDemoLabels = {
  en: {
    calendar: "Calendar",
    today: "Today",
    previous: "Previous period",
    next: "Next period",
    view: "View",
    day: "Day",
    threeDay: "3 days",
    week: "Week",
    month: "Month",
    unplanned: "Unplanned",
    project: "Project",
    allProjects: "All projects",
    close: "Close",
    schedule: "Schedule",
    pickSlot: "Choose a time in the calendar",
    cancel: "Cancel",
    create: "Create issue",
    save: "Save",
    title: "Title",
    empty: "All issues are scheduled",
    select: "Click a free slot or drag to select a range.",
    filters: "Calendar filters",
    allDay: "All day",
  },
  de: {
    calendar: "Kalender",
    today: "Heute",
    previous: "Vorheriger Zeitraum",
    next: "Nächster Zeitraum",
    view: "Ansicht",
    day: "Tag",
    threeDay: "3 Tage",
    week: "Woche",
    month: "Monat",
    unplanned: "Ungeplant",
    project: "Projekt",
    allProjects: "Alle Projekte",
    close: "Schließen",
    schedule: "Einplanen",
    pickSlot: "Wähle einen Zeitraum im Kalender",
    cancel: "Abbrechen",
    create: "Issue erstellen",
    save: "Speichern",
    title: "Titel",
    empty: "Alle Issues sind eingeplant",
    select: "Freien Zeitpunkt anklicken oder einen Zeitraum aufziehen.",
    filters: "Kalenderfilter",
    allDay: "Ganztägig",
  },
};
