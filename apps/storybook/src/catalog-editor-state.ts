import { useState } from "react";
type Option = { name: string; price: string; active: boolean };
export type Group = {
  name: string;
  rule: string;
  min: string;
  max: string;
  options: Option[];
};
export type Draft = {
  name: string;
  category: string;
  description: string;
  price: string;
  priceKind: string;
  duration: string;
  active: boolean;
  featured: boolean;
  track: boolean;
  hide: boolean;
  warn: string;
  groups: Group[];
  recommendations: string[];
  image?: string;
};
export const catalog = [
  { id: "p1", name: "Styling-Set", price: "24,90 €", kind: "product" },
  { id: "p2", name: "Pflege-Shampoo", price: "18,00 €", kind: "product" },
  { id: "l3", name: "Kopfmassage", price: "12,00 €", kind: "service" },
];
const initial = (product: boolean): Draft => ({
  name: product ? "Styling-Set" : "Kurzhaarschnitt",
  category: product ? "Pflege & Styling" : "Haarschnitte",
  description: product
    ? "Dein Styling für zu Hause – mit Wachs und Finish-Spray."
    : "Persönliche Beratung, Waschen, Schneiden und Styling.",
  price: product ? "24,90" : "32,00",
  priceKind: "fixed",
  duration: "30",
  active: true,
  featured: false,
  track: true,
  hide: true,
  warn: "3",
  groups: [
    {
      name: product ? "Verpackung" : "Haarlänge",
      rule: "optional",
      min: "0",
      max: "1",
      options: product
        ? [
            { name: "Geschenkbox", price: "2,50", active: true },
            { name: "Stoffbeutel", price: "4,00", active: true },
          ]
        : [
            { name: "Schulterlang", price: "8,00", active: true },
            { name: "Sehr lang", price: "15,00", active: true },
          ],
    },
  ],
  recommendations: product ? ["l3"] : ["p2", "l3"],
});
export const number = (value: string) => Number(value.replace(",", "."));

export function validGroup(group: Group): boolean {
  const activeCount = group.options.filter((option) => option.active).length;
  const min =
    group.rule === "required"
      ? 1
      : group.rule === "custom"
        ? Number(group.min)
        : 0;
  const max =
    group.rule === "custom" && group.max !== "" ? Number(group.max) : null;
  return (
    !!group.name.trim() &&
    group.options.length > 0 &&
    group.options.every(
      (option) =>
        !!option.name.trim() &&
        option.price.trim() !== "" &&
        Number.isFinite(number(option.price)) &&
        number(option.price) >= 0,
    ) &&
    Number.isInteger(min) &&
    min >= 0 &&
    min <= activeCount &&
    (max === null || (Number.isInteger(max) && max >= min))
  );
}

export function useCatalogEditor(
  kind: "service" | "product",
  initialPanel: string | null,
  initialDraft?: Partial<Draft>,
  initialCategories?: string[],
  initialStock = 12,
  initialReserved = 2,
) {
  const product = kind === "product";
  const [draft, setDraft] = useState(() => ({
    ...initial(product),
    ...initialDraft,
  }));
  const [saved, setSaved] = useState(() => ({
    ...initial(product),
    ...initialDraft,
  }));
  const [panel, setPanel] = useState<string | null>(initialPanel);
  const [open, setOpen] = useState(true);
  const [errors, setErrors] = useState(false);
  const [status, setStatus] = useState("");
  const [stock, setStock] = useState(initialStock);
  const reserved = initialReserved;
  const [movement, setMovement] = useState("in");
  const [amount, setAmount] = useState("1");
  const [reason, setReason] = useState("Lieferung");
  const [history, setHistory] = useState(["+ 12 · Erstbestand"]);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("all");
  const [newCategory, setNewCategory] = useState("");
  const [categories, setCategories] = useState(
    initialCategories ?? ["Haarschnitte", "Pflege & Styling", "Extras"],
  );
  const change = <K extends keyof Draft>(key: K, value: Draft[K]) => {
    setDraft((d) => ({ ...d, [key]: value }));
    setStatus("");
  };
  const dirty = JSON.stringify(draft) !== JSON.stringify(saved);
  const groupChange = (index: number, fn: (g: Group) => Group) =>
    change(
      "groups",
      draft.groups.map((g, i) => (i === index ? fn(g) : g)),
    );
  const toggleRec = (id: string) =>
    change(
      "recommendations",
      draft.recommendations.includes(id)
        ? draft.recommendations.filter((r) => r !== id)
        : [...draft.recommendations, id],
    );
  const close = () => (dirty ? setPanel("discard") : setOpen(false));
  const warningValid =
    !product ||
    !draft.track ||
    (draft.warn.trim() !== "" &&
      Number.isInteger(Number(draft.warn)) &&
      Number(draft.warn) >= 0);
  const groupsValid = draft.groups.every(validGroup);
  const valid =
    warningValid &&
    groupsValid &&
    !!draft.name.trim() &&
    (draft.priceKind === "request" ||
      (Number.isFinite(number(draft.price)) &&
        number(draft.price) >= 0 &&
        draft.price.trim() !== "")) &&
    (product ||
      (Number.isInteger(Number(draft.duration)) && Number(draft.duration) > 0));
  const after =
    movement === "set"
      ? Number(amount)
      : stock + (movement === "in" ? 1 : -1) * Number(amount);
  const canBook =
    amount.trim() !== "" &&
    Number.isInteger(Number(amount)) &&
    Number(amount) >= (movement === "set" ? 0 : 1) &&
    after >= reserved;
  const price =
    draft.priceKind === "request"
      ? "Preis auf Anfrage"
      : `${draft.priceKind === "from" ? "ab " : ""}${draft.price} €`;

  return {
    product,
    draft,
    setDraft,
    saved,
    setSaved,
    panel,
    setPanel,
    open,
    setOpen,
    errors,
    setErrors,
    status,
    setStatus,
    stock,
    setStock,
    reserved,
    movement,
    setMovement,
    amount,
    setAmount,
    reason,
    setReason,
    history,
    setHistory,
    search,
    setSearch,
    filter,
    setFilter,
    newCategory,
    setNewCategory,
    categories,
    setCategories,
    change,
    dirty,
    groupChange,
    toggleRec,
    close,
    valid,
    warningValid,
    groupsValid,
    after,
    canBook,
    price,
  };
}
export type EditorState = ReturnType<typeof useCatalogEditor>;
