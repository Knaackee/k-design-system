import type { KIconName } from "@k-design-system/ui";

export type EinsatzPage = "times" | "zones" | "history";
export type SheetKind =
  | "start"
  | "end"
  | "mode"
  | "add"
  | "absence"
  | "private"
  | "transport"
  | "holidays"
  | "newZone"
  | "zone"
  | "history"
  | "historyPreview"
  | "undo";
export type Exception = {
  id: string;
  kind: "absence" | "private" | "transport" | "holiday";
  title: string;
  date: string;
  until: string;
  from: string;
  to: string;
  allDay: boolean;
  address: string;
  mode: string;
  minutes: number;
};
export type Zone = {
  id: string;
  name: string;
  type: "radius" | "postal" | "polygon";
  radius: number;
  postal: string[];
  days: string[];
  from: string;
  to: string;
  fee: string;
  lead: string;
  active: boolean;
  color: string;
};
export const pages: {
  id: EinsatzPage;
  title: string;
  description: string;
  icon: KIconName;
  color: string;
}[] = [
  {
    id: "times",
    title: "Standorte & Zeiten",
    description: "Wo dein Tag beginnt und wann du nicht buchbar bist.",
    icon: "map-pin",
    color: "#16a34a",
  },
  {
    id: "zones",
    title: "Zonen & Buchungsregeln",
    description: "Wo und wann man dich buchen kann.",
    icon: "hexagon",
    color: "#ca8a04",
  },
  {
    id: "history",
    title: "Änderungsverlauf",
    description: "Wer was wann geändert hat – nur echte Änderungen.",
    icon: "rotate-ccw",
    color: "#52525b",
  },
];
export const modes = [
  { value: "car", label: "Auto", icon: "car" },
  { value: "bicycle", label: "Fahrrad", icon: "bike" },
  { value: "walking", label: "Zu Fuß", icon: "footprints" },
] as const;
export const exceptions: Exception[] = [
  {
    id: "private-1",
    kind: "private",
    title: "Zahnarzt",
    date: "2026-11-09",
    until: "2026-11-09",
    from: "12:00",
    to: "13:00",
    allDay: false,
    address: "Dr.-Martin-Luther-Str. 3, 93047 Regensburg",
    mode: "car",
    minutes: 15,
  },
  {
    id: "transport-1",
    kind: "transport",
    title: "Zu Fuß weiter",
    date: "2026-11-09",
    until: "2026-11-09",
    from: "13:15",
    to: "13:30",
    allDay: false,
    address: "Parkhaus Dachauplatz, Regensburg",
    mode: "walking",
    minutes: 15,
  },
  {
    id: "absence-1",
    kind: "absence",
    title: "Fortbildung Balayage",
    date: "2026-11-16",
    until: "2026-11-17",
    from: "09:00",
    to: "18:00",
    allDay: true,
    address: "",
    mode: "car",
    minutes: 15,
  },
  {
    id: "absence-2",
    kind: "absence",
    title: "Elternabend",
    date: "2026-11-19",
    until: "2026-11-19",
    from: "17:00",
    to: "19:30",
    allDay: false,
    address: "",
    mode: "car",
    minutes: 15,
  },
  {
    id: "absence-3",
    kind: "absence",
    title: "Weihnachtsurlaub",
    date: "2026-12-23",
    until: "2027-01-03",
    from: "09:00",
    to: "18:00",
    allDay: true,
    address: "",
    mode: "car",
    minutes: 15,
  },
  {
    id: "absence-past",
    kind: "absence",
    title: "Krank",
    date: "2026-10-20",
    until: "2026-10-21",
    from: "09:00",
    to: "18:00",
    allDay: true,
    address: "",
    mode: "car",
    minutes: 15,
  },
];
export const zones: Zone[] = [
  {
    id: "zone-1",
    name: "Steinberg & Umgebung",
    type: "radius",
    radius: 15,
    postal: [],
    days: ["Mo", "Di", "Mi", "Do", "Fr"],
    from: "09:00",
    to: "18:00",
    lead: "12 Stunden",
    fee: "0",
    active: true,
    color: "#0ea5e9",
  },
  {
    id: "zone-2",
    name: "Regensburg Innenstadt",
    type: "postal",
    radius: 10,
    postal: ["93047", "93049", "93053", "93055"],
    days: ["Di", "Do"],
    from: "10:00",
    to: "19:00",
    lead: "1 Tag",
    fee: "8",
    active: true,
    color: "#8b5cf6",
  },
  {
    id: "zone-3",
    name: "Schwandorf Nord",
    type: "polygon",
    radius: 10,
    postal: [],
    days: ["Sa"],
    from: "09:00",
    to: "14:00",
    lead: "1 Tag",
    fee: "5",
    active: false,
    color: "#f59e0b",
  },
];
export const history = [
  {
    id: "log-1",
    area: "Angebot",
    icon: "package" as KIconName,
    color: "#7c3aed",
    title: "Angebot gespeichert",
    day: "Heute",
    time: "17:26",
    published: false,
    changes: [
      ["Styling-Set · Preis", "24,90 €", "26,90 €"],
      ["Styling-Set · Zusatzoption", "", "Glanzspray · +4,00 €"],
      ["Kurzhaarschnitt · Dauer", "30 Min", "40 Min"],
    ],
  },
  {
    id: "log-2",
    area: "Zeiten",
    icon: "clock" as KIconName,
    color: "#16a34a",
    title: "Privater Termin hinzugefügt",
    day: "Heute",
    time: "16:02",
    published: false,
    changes: [
      ["Zahnarzt · Zeit", "", "Mo, 9. Nov · 12:00–13:00"],
      ["Zahnarzt · Ort", "", "Dr.-Martin-Luther-Str. 3, Regensburg"],
    ],
  },
  {
    id: "log-3",
    area: "Zonen",
    icon: "hexagon" as KIconName,
    color: "#ca8a04",
    title: "Zone geändert",
    day: "Heute",
    time: "11:40",
    published: false,
    changes: [
      ["Steinberg & Umgebung · Umkreis", "12 km", "15 km"],
      ["Vorlaufzeit", "1 Tag", "12 Stunden"],
    ],
  },
  {
    id: "log-4",
    area: "Buchungsseite",
    icon: "qr-code" as KIconName,
    color: "#0891b2",
    title: "Buchungsseite veröffentlicht",
    day: "Gestern",
    time: "20:15",
    published: true,
    changes: [
      [
        "Begrüßung",
        "Hi! Ich komme zu dir.",
        "Hallo! Ich komme mit allem, was ich brauche, zu dir nach Hause.",
      ],
      ["Titelbild", "salon-01.jpg", "balayage-02.jpg"],
    ],
  },
];
export const holidays = [
  { date: "2026-12-25", title: "1. Weihnachtstag", scope: "bundesweit" },
  { date: "2026-12-26", title: "2. Weihnachtstag", scope: "bundesweit" },
  { date: "2027-01-01", title: "Neujahr", scope: "bundesweit" },
  { date: "2027-01-06", title: "Heilige Drei Könige", scope: "Bayern" },
  { date: "2027-03-26", title: "Karfreitag", scope: "bundesweit" },
  { date: "2027-03-29", title: "Ostermontag", scope: "bundesweit" },
];
