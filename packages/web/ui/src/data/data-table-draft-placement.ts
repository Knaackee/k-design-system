import type { DataTableNode } from "./data-table-model.js";
import type { KDataTableDraftRow } from "./data-table-draft.js";
/** Pin drafts to their captured creation path, independently of current values. */
export function insertDataTableDrafts<T>(
  source: readonly DataTableNode<T>[],
  drafts: readonly KDataTableDraftRow<T>[],
): DataTableNode<T>[] {
  const clone = (nodes: readonly DataTableNode<T>[]): DataTableNode<T>[] =>
    nodes.map((n) =>
      n.kind === "rows"
        ? { ...n, rows: [...n.rows] }
        : { ...n, children: clone(n.children) },
    );
  const result = clone(source);
  for (const draft of drafts) {
    let nodes = result;
    const path: string[][] = [];
    for (const group of draft.originPath) {
      path.push([group.id, group.value]);
      const key = JSON.stringify(path);
      let node = nodes.find((n) => n.kind === "group" && n.key === key);
      if (!node) {
        node = {
          kind: "group",
          key,
          groupId: group.id,
          value: group.value,
          label: group.label,
          count: 0,
          children: [],
        };
        nodes.push(node);
      }
      if (node.kind !== "group") throw new Error("Invalid draft group");
      node.count++;
      nodes = node.children;
    }
    const leaf = nodes.find((n) => n.kind === "rows");
    if (leaf?.kind === "rows") leaf.rows = [...leaf.rows, draft.row];
    else nodes.push({ kind: "rows", rows: [draft.row] });
  }
  return result;
}
