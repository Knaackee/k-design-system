import type { KDataTableDraftRow } from "./data-table-draft.js";
import type {
  KDataTableEntry,
  KDataTableWindow,
} from "./data-table-entries.js";
/** Project local insertion anchors without mutating server indices or windows. */
export function draftWindow<T>(
  window: KDataTableWindow<T> | undefined,
  drafts: readonly KDataTableDraftRow<T>[],
  revision: string | undefined,
  rowId: (row: T) => string,
) {
  const total = window?.totalCount ?? 0;
  const sorted = [...drafts].sort(
    (a, b) => (a.originIndex ?? 0) - (b.originIndex ?? 0),
  );
  if (drafts.length && !window)
    throw new Error(
      "External drafts require an accepted window for their origin revision",
    );
  const ids = new Set<string>();
  for (const d of sorted) {
    const id = rowId(d.row);
    if (
      !id.trim() ||
      ids.has(id) ||
      window?.entries.some((e) => e.kind === "item" && rowId(e.row) === id)
    )
      throw new Error("Draft IDs must be unique and separate from server rows");
    ids.add(id);
    if (
      d.originQueryRevision !== revision ||
      !Number.isSafeInteger(d.originIndex) ||
      d.originIndex! < 0 ||
      d.originIndex! > total
    )
      throw new Error(
        "External draft requires a valid originIndex and matching originQueryRevision",
      );
  }
  const positions = sorted.map((d, i) => d.originIndex! + i);
  const toServer = (index: number) =>
    index - positions.filter((p) => p < index).length;
  const fromServer = (index: number) =>
    index + sorted.filter((d) => d.originIndex! <= index).length;
  const entryAt = (index: number): KDataTableEntry<T> | undefined => {
    const local = positions.indexOf(index);
    if (local >= 0) {
      const d = sorted[local];
      return {
        kind: "item",
        id: `item:${rowId(d.row)}`,
        row: d.row,
        path: d.originPath,
        depth: d.originPath.length,
      };
    }
    return window?.entries[toServer(index) - (window?.startIndex ?? 0)];
  };
  const indexed = [
    ...(window?.entries ?? []).map((entry, i) => ({
      entry,
      index: fromServer((window?.startIndex ?? 0) + i),
    })),
    ...positions.map((index) => ({ entry: entryAt(index)!, index })),
  ];
  return { count: total + sorted.length, entryAt, toServer, indexed };
}
