import type { DataTableNode } from "./data-table-model.js";

export interface KDataTableGroupValue {
  readonly id: string;
  readonly value: string;
  readonly label: string;
}
export interface KDataTableSection<T> {
  readonly path: readonly KDataTableGroupValue[];
  readonly rows: readonly T[];
}
export interface KDataTableViewport {
  height: number;
  rowHeight?: number;
  groupHeight?: number;
  footerHeight?: number;
  overscan?: number;
  maxGroupDepth?: number;
}
export interface KDataTableCellIdentity {
  rowId: string;
  columnId: string;
}
interface EntryBase {
  id: string;
  depth: number;
  path: readonly KDataTableGroupValue[];
}
export type KDataTableEntry<T> = EntryBase &
  (
    | { kind: "item"; row: T }
    | { kind: "group"; groupKey: string; label: string; count: number }
    | { kind: "footer"; rows: readonly T[] }
  );
export interface KDataTableWindow<T> {
  queryRevision: string;
  totalCount: number;
  startIndex: number;
  entries: readonly KDataTableEntry<T>[];
}
export interface KDataTableRange {
  queryRevision: string;
  startIndex: number;
  endIndex: number;
}

/** Stable logical entries, independent of mounted viewport indices. */
export function flattenDataTable<T>(
  nodes: readonly DataTableNode<T>[],
  rowId: (row: T) => string,
  collapsed: ReadonlySet<string>,
  footer: boolean,
): KDataTableEntry<T>[] {
  const entries: KDataTableEntry<T>[] = [];
  const visit = (
    children: readonly DataTableNode<T>[],
    path: readonly KDataTableGroupValue[],
  ) => {
    for (const node of children) {
      if (node.kind === "rows") {
        entries.push(
          ...node.rows.map((row) => ({
            kind: "item" as const,
            id: `item:${rowId(row)}`,
            depth: path.length,
            path,
            row,
          })),
        );
        if (footer)
          entries.push({
            kind: "footer",
            id: `footer:${JSON.stringify(path.map((g) => [g.id, g.value]))}`,
            depth: path.length,
            path,
            rows: node.rows,
          });
      } else {
        const next = [
          ...path,
          { id: node.groupId, value: node.value, label: node.label },
        ];
        entries.push({
          kind: "group",
          id: `group:${node.key}`,
          groupKey: node.key,
          label: node.label,
          count: node.count,
          depth: path.length,
          path: next,
        });
        if (!collapsed.has(node.key)) visit(node.children, next);
      }
    }
  };
  visit(nodes, []);
  if (!nodes.length && footer)
    entries.push({
      kind: "footer",
      id: "footer:[]",
      depth: 0,
      path: [],
      rows: [],
    });
  return entries;
}

export function validateWindow<T>(window: KDataTableWindow<T>) {
  if (
    !window.queryRevision ||
    !Number.isSafeInteger(window.totalCount) ||
    window.totalCount < 0 ||
    !Number.isSafeInteger(window.startIndex) ||
    window.startIndex < 0 ||
    window.startIndex + window.entries.length > window.totalCount
  )
    throw new RangeError(
      "KDataTable external window must have a revision and valid bounded indices",
    );
  const ids = new Set<string>();
  for (const entry of window.entries) {
    if (
      !entry.id.trim() ||
      ids.has(entry.id) ||
      !Number.isSafeInteger(entry.depth) ||
      entry.depth < 0
    )
      throw new Error(
        "KDataTable entry IDs must be unique and depth nonnegative",
      );
    ids.add(entry.id);
    if (
      entry.kind === "group" &&
      (!Number.isSafeInteger(entry.count) || entry.count < 0 || !entry.groupKey)
    )
      throw new Error(
        "KDataTable group entries require a key and nonnegative count",
      );
  }
}
