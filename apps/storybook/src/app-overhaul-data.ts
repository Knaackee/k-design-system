/** Deterministic gallery fixtures; never persisted or sent to customers. */
export type AppScreen =
  | "home"
  | "day"
  | "calendar"
  | "bookings"
  | "inbox"
  | "customers"
  | "assistant";
export type Customer = {
  id: string;
  name: string;
  area: string;
  address: string;
  note: string;
  color: string;
  email?: string;
};
export type Booking = {
  id: string;
  customer: string;
  date: string;
  start: string;
  end: string;
  service: string;
  price: number;
  travel: number;
  status: "confirmed" | "request" | "quote" | "cancelled" | "expired";
  drive: number;
  km: string;
};
export const customers: Customer[] = [
  {
    id: "c1",
    name: "Lena Hoffmann",
    area: "Südvorstadt",
    address: "Karl-Liebknecht-Straße 88, 04275 Leipzig",
    note: "Kurze Seiten, oben länger.",
    color: "#db2777",
  },
  {
    id: "c2",
    name: "Jonas Becker",
    area: "Connewitz",
    address: "Bornaische Straße 18, 04277 Leipzig",
    note: "3. OG, kein Aufzug. Parken an der Straße.",
    color: "#2563eb",
  },
  {
    id: "c3",
    name: "Renate Weber",
    area: "Gohlis",
    address: "Georg-Schumann-Straße 108, 04155 Leipzig",
    note: "Erdgeschoss links. Parken im Hof.",
    color: "#059669",
  },
  {
    id: "c4",
    name: "Familie Öztürk",
    area: "Lößnig",
    address: "Arno-Nitzsche-Straße 4, 04277 Leipzig",
    note: "2. OG rechts. Parkplatz hinter dem Haus.",
    color: "#ea580c",
  },
  {
    id: "c5",
    name: "Sophie Lange",
    area: "Plagwitz",
    address: "Karl-Heine-Straße 52, 04229 Leipzig",
    note: "Hinterhaus, 4. OG.",
    color: "#7c3aed",
  },
  {
    id: "c6",
    name: "Thomas Richter",
    area: "Reudnitz",
    address: "Dresdner Straße 61, 04317 Leipzig",
    note: "Hochparterre.",
    color: "#0891b2",
  },
  {
    id: "c7",
    name: "Ingrid Kühn",
    area: "Zentrum-Süd",
    address: "Härtelstraße 9, 04107 Leipzig",
    note: "1. OG. Bitte vorher anrufen.",
    color: "#ca8a04",
  },
];
export const bookings: Booking[] = [
  {
    id: "b1",
    customer: "c7",
    date: "2026-11-03",
    start: "08:30",
    end: "09:30",
    service: "Waschen & Schneiden",
    price: 47,
    travel: 4.2,
    status: "confirmed",
    drive: 12,
    km: "4,8",
  },
  {
    id: "b2",
    customer: "c2",
    date: "2026-11-03",
    start: "10:40",
    end: "11:10",
    service: "Herrenschnitt",
    price: 29,
    travel: 4.54,
    status: "confirmed",
    drive: 14,
    km: "6,1",
  },
  {
    id: "b3",
    customer: "c3",
    date: "2026-11-03",
    start: "11:45",
    end: "13:15",
    service: "Farbe · Schneiden",
    price: 85,
    travel: 6.1,
    status: "confirmed",
    drive: 22,
    km: "9,4",
  },
  {
    id: "b4",
    customer: "c4",
    date: "2026-11-03",
    start: "14:30",
    end: "15:30",
    service: "3 × Kinderschnitt",
    price: 66,
    travel: 5.3,
    status: "confirmed",
    drive: 26,
    km: "11,2",
  },
  {
    id: "b5",
    customer: "c6",
    date: "2026-11-04",
    start: "09:00",
    end: "09:30",
    service: "Herrenschnitt",
    price: 29,
    travel: 6.4,
    status: "request",
    drive: 18,
    km: "7,3",
  },
  {
    id: "b6",
    customer: "c5",
    date: "2026-11-05",
    start: "15:10",
    end: "18:10",
    service: "Balayage",
    price: 0,
    travel: 5.9,
    status: "quote",
    drive: 16,
    km: "6,2",
  },
  {
    id: "b7",
    customer: "c1",
    date: "2026-11-06",
    start: "10:00",
    end: "10:45",
    service: "Schneiden",
    price: 38,
    travel: 3.9,
    status: "confirmed",
    drive: 9,
    km: "3,4",
  },
  {
    id: "b8",
    customer: "c5",
    date: "2026-10-30",
    start: "12:30",
    end: "13:35",
    service: "Langhaarschnitt · Pflege",
    price: 74.9,
    travel: 4.38,
    status: "cancelled",
    drive: 16,
    km: "6,2",
  },
];
export const money = (value: number) =>
  new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(
    value,
  );
export const customerOf = (booking: Booking) =>
  customers.find((c) => c.id === booking.customer)!;
export const dateLabel = (date: string) =>
  date === "2026-11-03"
    ? "Heute · Di, 3. Nov"
    : date === "2026-11-04"
      ? "Morgen · Mi, 4. Nov"
      : new Intl.DateTimeFormat("de-DE", {
          weekday: "short",
          day: "numeric",
          month: "short",
        }).format(new Date(`${date}T12:00:00`));
export const statusLabels = {
  confirmed: "Bestätigt",
  request: "Anfrage",
  quote: "Preis auf Anfrage",
  cancelled: "Abgesagt",
  expired: "Abgelaufen",
};
