import test from "node:test";
import assert from "node:assert/strict";
import {
  flattenDataTable,
  validateWindow,
} from "../packages/web/ui/src/data/data-table-entries.ts";
import { dataTableModel } from "../packages/web/ui/src/data/data-table-model.ts";
const rows = Array.from({ length: 240 }, (_, i) => ({
  id: `row-${i}`,
  team: i % 2 ? "B" : "A",
  value: i,
}));
const model = dataTableModel({
  rows,
  rowId: (r) => r.id,
  columns: [{ id: "value", compare: (a, b) => a.value - b.value }],
  groups: [{ id: "team", value: (r) => r.team }],
  sort: { columnId: "value", direction: "descending" },
});
test("flattened groups/items/footers retain paths, sorted leaf rows and stable identity", () => {
  const entries = flattenDataTable(model.nodes, (r) => r.id, new Set(), true);
  assert.equal(entries.length, 244);
  assert.deepEqual(
    entries.slice(0, 3).map((e) => e.id),
    ['group:[["team","A"]]', "item:row-238", "item:row-236"],
  );
  const footer = entries[121];
  assert.equal(footer.kind, "footer");
  assert.equal(footer.rows.length, 120);
  assert.deepEqual(footer.path, [{ id: "team", value: "A", label: "A" }]);
  assert.equal(new Set(entries.map((e) => e.id)).size, entries.length);
  const collapsed = flattenDataTable(
    model.nodes,
    (r) => r.id,
    new Set(['[["team","A"]]']),
    true,
  );
  assert.equal(collapsed.length, 123);
  assert.equal(collapsed[1].label, "B");
  assert.equal(collapsed.at(-1).id, 'footer:[["team","B"]]');
});
test("empty local models expose only an optional creation footer", () => {
  assert.deepEqual(
    flattenDataTable([], (r) => r.id, new Set(), false),
    [],
  );
  assert.deepEqual(
    flattenDataTable([], (r) => r.id, new Set(), true),
    [{ kind: "footer", id: "footer:[]", depth: 0, path: [], rows: [] }],
  );
});
test("external window rejects bad bounds, duplicate identities and invalid group counts", () => {
  const entry = { kind: "item", id: "row-1", row: rows[1], depth: 0, path: [] };
  const window = {
    queryRevision: "query-1",
    totalCount: 240,
    startIndex: 20,
    entries: [entry],
  };
  assert.doesNotThrow(() => validateWindow(window));
  assert.throws(
    () => validateWindow({ ...window, startIndex: 240 }),
    /bounded indices/,
  );
  assert.throws(
    () => validateWindow({ ...window, entries: [entry, entry] }),
    /unique/,
  );
  assert.throws(
    () => validateWindow({ ...window, entries: [{ ...entry, depth: -1 }] }),
    /depth/,
  );
  assert.throws(
    () =>
      validateWindow({
        ...window,
        entries: [
          {
            kind: "group",
            id: "g",
            depth: 0,
            path: [],
            label: "Group",
            groupKey: "g",
            count: -1,
          },
        ],
      }),
    /count/,
  );
});
