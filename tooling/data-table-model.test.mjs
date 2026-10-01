import test from "node:test";
import assert from "node:assert/strict";
import {
  dataTableModel,
  nextDataTableSort,
} from "../packages/web/ui/src/data/data-table-model.ts";
const rows = [
  { id: "a", value: 4, status: "active", platform: "web" },
  { id: "b", value: 2, status: "planned", platform: "mobile" },
  { id: "c", value: 4, status: "active", platform: "web" },
  { id: "d", value: 1, status: "active", platform: "mobile" },
];
const base = {
  rows,
  rowId: (r) => r.id,
  columns: [{ id: "value", compare: (a, b) => a.value - b.value }],
};
test("header sorting cycles ascending, descending, original and resets for a new column", () => {
  let sort = null;
  for (const expected of [
    ["d", "b", "a", "c"],
    ["a", "c", "b", "d"],
    ["a", "b", "c", "d"],
  ]) {
    sort = nextDataTableSort(sort, "value");
    assert.deepEqual(
      dataTableModel({ ...base, sort }).nodes[0].rows.map((row) => row.id),
      expected,
    );
  }
  assert.equal(sort, null);
  assert.deepEqual(
    nextDataTableSort({ columnId: "other", direction: "descending" }, "value"),
    { columnId: "value", direction: "ascending" },
  );
});
test("controlled sorting is stable and never mutates source rows", () => {
  const ascending = dataTableModel({
    ...base,
    sort: { columnId: "value", direction: "ascending" },
  });
  assert.deepEqual(
    ascending.nodes[0].rows.map((r) => r.id),
    ["d", "b", "a", "c"],
  );
  const descending = dataTableModel({
    ...base,
    sort: { columnId: "value", direction: "descending" },
  });
  assert.deepEqual(
    descending.nodes[0].rows.map((r) => r.id),
    ["a", "c", "b", "d"],
  );
  assert.deepEqual(
    rows.map((r) => r.id),
    ["a", "b", "c", "d"],
  );
});
test("filtering precedes nested grouping, counts filtered rows, and sorts only leaves", () => {
  const groups = [
    { id: "status", value: (r) => r.status },
    { id: "platform", value: (r) => r.platform },
  ];
  const result = dataTableModel({
    ...base,
    filter: (r) => r.id !== "b",
    groups,
    sort: { columnId: "value", direction: "descending" },
  });
  assert.equal(result.count, 3);
  assert.equal(result.nodes[0].count, 3);
  assert.equal(result.nodes[0].key, '[["status","active"]]');
  assert.equal(
    result.nodes[0].children[0].key,
    '[["status","active"],["platform","web"]]',
  );
  assert.deepEqual(
    result.nodes[0].children.map((n) => n.label),
    ["web", "mobile"],
  );
  assert.deepEqual(
    result.nodes[0].children[0].children[0].rows.map((r) => r.id),
    ["a", "c"],
  );
  assert.deepEqual(dataTableModel({ ...base, filter: () => false }), {
    count: 0,
    nodes: [],
  });
});
test("group keys safely encode delimiters and repeated child values", () => {
  const source = [
    { id: "1", value: "a/b", child: "same" },
    { id: "2", value: "a", child: "same" },
  ];
  const result = dataTableModel({
    ...base,
    rows: source,
    groups: [
      { id: "g", value: (r) => r.value },
      { id: "child", value: (r) => r.child },
    ],
  });
  assert.notEqual(
    result.nodes[0].children[0].key,
    result.nodes[1].children[0].key,
  );
});
test("invalid identity and sort contracts fail even when rows are filtered out", () => {
  assert.throws(
    () =>
      dataTableModel({
        ...base,
        rows: [rows[0], rows[0]],
        filter: () => false,
      }),
    /row IDs/,
  );
  assert.throws(
    () => dataTableModel({ ...base, columns: [] }),
    /requires columns/,
  );
  assert.throws(
    () =>
      dataTableModel({
        ...base,
        groups: [
          { id: "g", value: (r) => r.status },
          { id: "g", value: (r) => r.status },
        ],
      }),
    /group IDs/,
  );
  assert.throws(
    () =>
      dataTableModel({
        ...base,
        sort: { columnId: "missing", direction: "ascending" },
      }),
    /sortable column/,
  );
  assert.throws(
    () =>
      dataTableModel({
        ...base,
        columns: [{ id: "value", compare: () => NaN }],
        sort: { columnId: "value", direction: "ascending" },
      }),
    /finite number/,
  );
});
