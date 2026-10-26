import type { KIconName } from "@k-design-system/ui/primitives/icon";

export type DayEntry = {
  id: string;
  start: number;
  end: number;
  title: string;
  detail: string;
  routeDescription?: string;
  icon: KIconName;
  kind: "stop" | "travel";
  center: [number, number];
};

// Synthetic, deliberately fixed times: this gallery does not calculate routes.
export const dayEntries: DayEntry[] = [
  {
    id: "start",
    start: 540,
    end: 545,
    title: "Start · Zuhause",
    detail: "Invalidenstraße 44, Berlin",
    icon: "house",
    kind: "stop",
    center: [13.377, 52.529],
  },
  {
    id: "walk-car",
    start: 545,
    end: 550,
    title: "Zu deinem Auto",
    detail: "5 Min. zu Fuß · 350 m · Parkplatz am Museum",
    icon: "footprints",
    kind: "travel",
    center: [13.377, 52.529],
  },
  {
    id: "drive-1",
    start: 550,
    end: 570,
    title: "Mit dem Auto",
    routeDescription:
      "Von: Parkplatz am Museum\nInvalidenstraße 44, 10115 Berlin\n\nNach: Parkplatz am Ziel\nKollwitzplatz, 10405 Berlin",
    detail: "20 Min. · 6,4 km · zum Parkplatz am Ziel",
    icon: "car",
    kind: "travel",
    center: [13.399, 52.535],
  },
  {
    id: "park-1",
    start: 570,
    end: 575,
    title: "Parken & ankommen",
    detail: "5 Min. Parkpuffer · Parkplatz Kollwitzplatz",
    icon: "map-pin",
    kind: "travel",
    center: [13.418, 52.536],
  },
  {
    id: "walk-1",
    start: 575,
    end: 580,
    title: "Zum Hauseingang",
    detail: "5 Min. zu Fuß · 280 m",
    icon: "footprints",
    kind: "travel",
    center: [13.418, 52.536],
  },
  {
    id: "anna",
    start: 580,
    end: 625,
    title: "Anna Becker",
    detail: "Kollwitzstraße 30 · Haarschnitt & Pflege · 45 Min.",
    icon: "map-pin",
    kind: "stop",
    center: [13.418, 52.536],
  },
  {
    id: "return-car",
    start: 625,
    end: 630,
    title: "Zurück zum Auto",
    detail: "5 Min. zu Fuß · zum abgestellten Fahrzeug",
    icon: "footprints",
    kind: "travel",
    center: [13.418, 52.536],
  },
  {
    id: "drive-2",
    start: 630,
    end: 655,
    title: "Fahrt & Zugang",
    detail: "15 Min. Auto · 5 Min. Parken · 5 Min. Fußweg",
    icon: "car",
    kind: "travel",
    center: [13.405, 52.52],
  },
  {
    id: "leo",
    start: 655,
    end: 685,
    title: "Leo Wagner",
    detail: "Rochstraße 8 · Haarschnitt · 30 Min.",
    icon: "map-pin",
    kind: "stop",
    center: [13.405, 52.52],
  },
  {
    id: "walk-private",
    start: 685,
    end: 695,
    title: "Zu Fuß zum privaten Termin",
    detail: "10 Min. · 650 m · Auto bleibt am Parkplatz",
    icon: "footprints",
    kind: "travel",
    center: [13.397, 52.519],
  },
  {
    id: "private",
    start: 695,
    end: 725,
    title: "Privater Termin",
    detail: "Friedrichstraße 96 · fester Zeitblock · 30 Min.",
    icon: "calendar-days",
    kind: "stop",
    center: [13.389, 52.52],
  },
  {
    id: "home-leg",
    start: 725,
    end: 755,
    title: "Zurück nach Hause",
    detail: "10 Min. zum Auto · 15 Min. Fahrt · 5 Min. Zugang",
    icon: "car",
    kind: "travel",
    center: [13.377, 52.529],
  },
  {
    id: "end",
    start: 755,
    end: 755,
    title: "Tagesende · Zuhause",
    detail: "Invalidenstraße 44, Berlin",
    icon: "house",
    kind: "stop",
    center: [13.377, 52.529],
  },
];

export function dayTime(minutes: number) {
  return `${Math.floor(minutes / 60)
    .toString()
    .padStart(2, "0")}:${(minutes % 60).toString().padStart(2, "0")}`;
}
