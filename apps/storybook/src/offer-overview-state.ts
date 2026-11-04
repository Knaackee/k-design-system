import { useState } from "react";
import type { KMenuAction } from "@k-design-system/ui";
import {
  categories as initialCategories,
  items as initialItems,
  type OfferCategory,
  type OfferItem,
  type OfferFilter,
  type OfferPanel,
} from "./offer-overview-data.js";
export function useOfferOverview(initialFilter: OfferFilter, empty: boolean) {
  const [categories, setCategories] = useState(initialCategories);
  const [items, setItems] = useState(empty ? [] : initialItems);
  const [filter, setFilter] = useState(initialFilter);
  const [query, setQuery] = useState("");
  const [closed, setClosed] = useState<string[]>([]);
  const [hint, setHint] = useState(true);
  const [changes, setChanges] = useState(2);
  const [handover, setHandover] = useState(5);
  const [panel, setPanel] = useState<OfferPanel>(null);
  const [message, setMessage] = useState("");
  const notify = (text: string) => setMessage(text);
  const changed = (text: string) => {
    setChanges((n) => n + 1);
    setPanel(null);
    notify(text);
  };
  const count = (kind?: "service" | "product", archived = false) =>
    items.filter((i) => (!kind || i.kind === kind) && !!i.archived === archived)
      .length;
  const visible = items.filter(
    (i) =>
      !!i.archived === (filter === "archive") &&
      (filter === "all" || filter === "archive" || i.kind === filter) &&
      i.name.toLocaleLowerCase().includes(query.trim().toLocaleLowerCase()),
  );
  const groups = categories.filter(
    (c) =>
      visible.some((i) => i.category === c.id) || (!query && filter === "all"),
  );
  const updateItem = (item: OfferItem) => {
    setItems((list) =>
      list.some((i) => i.id === item.id)
        ? list.map((i) => (i.id === item.id ? item : i))
        : [...list, item],
    );
    changed("Im lokalen Entwurf gespeichert");
  };
  const moveItem = (id: string, target: string) => {
    setItems((list) =>
      list.map((i) => (i.id === id ? { ...i, category: target } : i)),
    );
    changed("Eintrag verschoben");
  };
  const shiftItem = (item: OfferItem, direction: number) => {
    setItems((list) => {
      const same = list.filter(
        (i) => i.category === item.category && !i.archived,
      );
      const neighbor =
        same[same.findIndex((i) => i.id === item.id) + direction];
      if (!neighbor) return list;
      const next = [...list],
        a = next.findIndex((i) => i.id === item.id),
        b = next.findIndex((i) => i.id === neighbor.id);
      [next[a], next[b]] = [next[b]!, next[a]!];
      return next;
    });
    changed("Reihenfolge geändert");
  };
  const shiftCategory = (category: OfferCategory, direction: number) => {
    setCategories((list) => {
      const next = [...list],
        a = next.findIndex((c) => c.id === category.id),
        b = a + direction;
      if (b < 0 || b >= next.length) return list;
      [next[a], next[b]] = [next[b]!, next[a]!];
      return next;
    });
    changed("Kategorien neu sortiert");
  };
  const itemActions = (item: OfferItem): KMenuAction[] => [
    {
      id: "edit",
      label: "Bearbeiten",
      icon: "pencil",
      onSelect: () => setPanel({ type: "edit", kind: item.kind, item }),
    },
    {
      id: "duplicate",
      label: "Duplizieren",
      icon: "copy",
      onSelect: () =>
        updateItem({
          ...item,
          id: `copy-${Date.now()}`,
          name: `${item.name} (Kopie)`,
          draft: true,
        }),
    },
    {
      id: "move",
      label: "Verschieben nach …",
      icon: "move",
      onSelect: () => setPanel({ type: "move", item }),
    },
    {
      id: "up",
      label: "Nach oben",
      icon: "arrow-up",
      disabled:
        items.filter((i) => i.category === item.category && !i.archived)[0]
          ?.id === item.id,
      onSelect: () => shiftItem(item, -1),
    },
    {
      id: "down",
      label: "Nach unten",
      icon: "arrow-down",
      disabled:
        items.filter((i) => i.category === item.category && !i.archived).at(-1)
          ?.id === item.id,
      onSelect: () => shiftItem(item, 1),
    },
    {
      id: "preview",
      label: "Auf Buchungsseite ansehen",
      icon: "eye",
      onSelect: () =>
        notify("Buchungsseiten-Vorschau ist in dieser Story nicht angebunden."),
    },
    {
      id: "archive",
      label: "Archivieren",
      icon: "archive",
      destructive: true,
      separatorBefore: true,
      onSelect: () => updateItem({ ...item, archived: true }),
    },
  ];
  const categoryActions = (category: OfferCategory): KMenuAction[] => [
    {
      id: "edit",
      label: "Bearbeiten",
      icon: "pencil",
      onSelect: () => setPanel({ type: "category", category }),
    },
    {
      id: "service",
      label: "Leistung hinzufügen",
      icon: "clock",
      onSelect: () =>
        setPanel({ type: "edit", kind: "service", category: category.id }),
    },
    {
      id: "product",
      label: "Produkt hinzufügen",
      icon: "package",
      onSelect: () =>
        setPanel({ type: "edit", kind: "product", category: category.id }),
    },
    {
      id: "up",
      label: "Nach oben",
      icon: "arrow-up",
      disabled: categories[0]?.id === category.id,
      onSelect: () => shiftCategory(category, -1),
    },
    {
      id: "down",
      label: "Nach unten",
      icon: "arrow-down",
      disabled: categories.at(-1)?.id === category.id,
      onSelect: () => shiftCategory(category, 1),
    },
    {
      id: "delete",
      label: "Kategorie löschen",
      icon: "trash",
      destructive: true,
      disabled: categories.length === 1,
      onSelect: () => setPanel({ type: "delete", category }),
    },
  ];
  const add = (category?: string) =>
    setPanel(
      category && (filter === "product" || filter === "service")
        ? { type: "edit", kind: filter, category }
        : { type: "new", category },
    );
  return {
    categories,
    setCategories,
    items,
    setItems,
    filter,
    setFilter,
    query,
    setQuery,
    closed,
    setClosed,
    hint,
    setHint,
    changes,
    setChanges,
    handover,
    setHandover,
    panel,
    setPanel,
    message,
    setMessage,
    notify,
    changed,
    count,
    visible,
    groups,
    updateItem,
    moveItem,
    itemActions,
    categoryActions,
    add,
  };
}
