import { storeReactivityBindings } from "@tanstack/table-core/store-reactivity-bindings";
import {
  constructTable,
  tableFeatures,
  rowSortingFeature,
  createSortedRowModel,
} from "@tanstack/react-table";
const features = tableFeatures({
  coreReactivityFeature: storeReactivityBindings(),
  rowSortingFeature,
  sortedRowModel: createSortedRowModel(),
});

export type KDataTableSortDirection = "ascending" | "descending";
export interface KDataTableSort {
  columnId: string;
  direction: KDataTableSortDirection;
}
export interface KDataTableGroup<T> {
  id: string;
  value: (row: T) => string;
  label?: (value: string) => string;
}
export interface KDataTableOrdering<T> {
  id: string;
  compare?: (a: T, b: T) => number;
}
export type DataTableNode<T> =
  | { kind: "rows"; rows: readonly T[] }
  | {
      kind: "group";
      key: string;
      groupId: string;
      value: string;
      label: string;
      count: number;
      children: DataTableNode<T>[];
    };

/** Filtering precedes grouping; sorting affects leaves, not group order. */
export function dataTableModel<T>({
  rows,
  columns,
  rowId,
  filter,
  groups = [],
  sort,
}: {
  rows: readonly T[];
  columns: readonly KDataTableOrdering<T>[];
  rowId: (row: T) => string;
  filter?: (row: T) => boolean;
  groups?: readonly KDataTableGroup<T>[];
  sort?: KDataTableSort | null;
}): { count: number; nodes: DataTableNode<T>[] } {
  const unique = (ids: readonly string[], name: string) => {
    if (ids.some((id) => !id.trim()) || new Set(ids).size !== ids.length)
      throw new Error(`KDataTable ${name} IDs must be nonempty and unique`);
  };
  unique(rows.map(rowId), "row");
  unique(
    columns.map((c) => c.id),
    "column",
  );
  unique(
    groups.map((g) => g.id),
    "group",
  );
  if (!columns.length) throw new Error("KDataTable requires columns");
  const ordering = sort
    ? columns.find((c) => c.id === sort.columnId)?.compare
    : undefined;
  if (
    sort &&
    (!ordering || !["ascending", "descending"].includes(sort.direction))
  )
    throw new Error(
      "KDataTable sort requires a sortable column and valid direction",
    );
  const filtered = filter ? rows.filter(filter) : [...rows];
  // TanStack owns stable sorting and row identity. Group order remains based on
  // filtered input, before sorting, to preserve the KDataTable contract.
  const table = constructTable<typeof features, { value: T }>({
    features,
    data: filtered.map((value) => ({ value })),
    getRowId: (row) => rowId(row.value),
    columns: columns.map((column) => ({
      id: column.id,
      accessorFn: (row: { value: T }) => row.value,
      sortFn: (a, b) => {
        const result =
          column.compare?.(a.original.value, b.original.value) ?? 0;
        if (!Number.isFinite(result))
          throw new Error("KDataTable comparator must return a finite number");
        return result;
      },
    })),
    initialState: {
      sorting: sort
        ? [{ id: sort.columnId, desc: sort.direction === "descending" }]
        : [],
    },
  });
  const ranks = new Map(
    table.getRowModel().rows.map((row, index) => [row.id, index]),
  );
  const build = (
    items: readonly T[],
    depth: number,
    path: string[][],
  ): DataTableNode<T>[] => {
    if (depth === groups.length) {
      const sorted = [...items];
      if (ordering)
        sorted.sort((a, b) => ranks.get(rowId(a))! - ranks.get(rowId(b))!);
      return [{ kind: "rows", rows: sorted }];
    }
    const group = groups[depth],
      buckets = new Map<string, T[]>();
    for (const row of items) {
      const value = group.value(row);
      const bucket = buckets.get(value);
      if (bucket) bucket.push(row);
      else buckets.set(value, [row]);
    }
    return [...buckets].map(([value, children]) => {
      const next = [...path, [group.id, value]];
      return {
        kind: "group",
        key: JSON.stringify(next),
        groupId: group.id,
        value,
        label: group.label?.(value) ?? value,
        count: children.length,
        children: build(children, depth + 1, next),
      };
    });
  };
  return {
    count: filtered.length,
    nodes: filtered.length ? build(filtered, 0, []) : [],
  };
}
