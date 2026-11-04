import type { Draft } from "./catalog-editor-state.js";
export type OfferKind = "service" | "product";
export type OfferFilter = "all" | "service" | "product" | "archive";
export interface OfferCategory {
  id: string;
  name: string;
  description: string;
  color: string;
}
export interface OfferItem {
  editorDraft?: Partial<Draft>;
  id: string;
  kind: OfferKind;
  category: string;
  name: string;
  price: number;
  duration?: number;
  stock?: number;
  image?: [string, string];
  options?: boolean;
  featured?: boolean;
  hidden?: boolean;
  archived?: boolean;
  draft?: boolean;
  priceKind?: "from" | "request";
}
export const colors = [
  "#db2777",
  "#e11d48",
  "#ea580c",
  "#ca8a04",
  "#16a34a",
  "#0d9488",
  "#0891b2",
  "#0c679f",
  "#7c3aed",
  "#52525b",
];
export const categories: OfferCategory[] = [
  {
    id: "c1",
    name: "Haarschnitt & Styling",
    description: "Wähle deinen Schnitt oder ein Styling-Set für zu Hause.",
    color: colors[0]!,
  },
  {
    id: "c2",
    name: "Pflege & Extras",
    description: "Pflege, Entspannung und passende Produkte für deinen Termin.",
    color: colors[5]!,
  },
  {
    id: "c3",
    name: "Farbe & Farbschutz",
    description: "Farbfrische im Termin oder Pflege für zu Hause.",
    color: colors[8]!,
  },
  { id: "c4", name: "Hochzeit & Events", description: "", color: colors[3]! },
];
export const items: OfferItem[] = [
  {
    id: "l1",
    kind: "service",
    category: "c1",
    name: "Kurzhaarschnitt",
    price: 32,
    duration: 30,
    image: ["#be123c", "#fda4af"],
    options: true,
  },
  {
    id: "l2",
    kind: "service",
    category: "c1",
    name: "Langhaarschnitt mit Pflegekur und Föhnfrisur",
    price: 58,
    duration: 60,
    featured: true,
  },
  {
    id: "p1",
    kind: "product",
    category: "c1",
    name: "Styling-Set",
    price: 24.9,
    stock: 12,
    image: ["#44403c", "#a8a29e"],
    options: true,
  },
  {
    id: "l3",
    kind: "service",
    category: "c2",
    name: "Haare waschen",
    price: 8,
    duration: 10,
  },
  {
    id: "l4",
    kind: "service",
    category: "c2",
    name: "Kopfhautmassage",
    price: 12,
    duration: 10,
    image: ["#0f766e", "#99f6e4"],
  },
  {
    id: "p2",
    kind: "product",
    category: "c2",
    name: "Feuchtigkeitsshampoo",
    price: 14.9,
    stock: 2,
  },
  {
    id: "p3",
    kind: "product",
    category: "c2",
    name: "Pflegeconditioner",
    price: 16.9,
    stock: 12,
    image: ["#0369a1", "#7dd3fc"],
  },
  {
    id: "l5",
    kind: "service",
    category: "c3",
    name: "Ansatzfarbe",
    price: 65,
    duration: 75,
    priceKind: "from",
  },
  {
    id: "l6",
    kind: "service",
    category: "c3",
    name: "Glanz-Glossing",
    price: 39,
    duration: 40,
    hidden: true,
  },
  {
    id: "p4",
    kind: "product",
    category: "c3",
    name: "Farbschutzmaske",
    price: 22.9,
    stock: 0,
  },
  {
    id: "l7",
    kind: "service",
    category: "c3",
    name: "Balayage",
    price: 0,
    duration: 180,
    priceKind: "request",
    archived: true,
  },
  {
    id: "p5",
    kind: "product",
    category: "c3",
    name: "Glanzspray",
    price: 11.9,
    stock: 5,
    archived: true,
  },
];
export const euro = (value: number) =>
  new Intl.NumberFormat("de-DE", { style: "currency", currency: "EUR" }).format(
    value,
  );
export type OfferPanel =
  | { type: "new"; category?: string }
  | { type: "category"; category?: OfferCategory }
  | { type: "delete"; category: OfferCategory }
  | { type: "move"; item: OfferItem }
  | { type: "edit"; item?: OfferItem; kind: OfferKind; category?: string }
  | { type: "handover" }
  | { type: "history" }
  | null;
