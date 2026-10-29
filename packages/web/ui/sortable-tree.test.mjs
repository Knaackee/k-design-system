import assert from "node:assert/strict";
import test from "node:test";
import {
  flattenKSortableTree,
  moveKSortableTree,
} from "./dist/patterns/sortable-tree-model.js";

const tree = [
  {
    id: "group",
    label: "Group",
    children: [
      { id: "a", label: "A", data: { value: 1 } },
      { id: "nested", label: "Nested", children: [{ id: "b", label: "B" }] },
      { id: "c", label: "C" },
    ],
  },
  { id: "empty", label: "Empty", children: [] },
  { id: "leaf", label: "Leaf" },
];

test("flatten preserves sibling indices, depth and ancestors; collapsed groups hide descendants", () => {
  assert.deepEqual(
    flattenKSortableTree(tree).map(({ node, parentId, index, depth }) => [
      node.id,
      parentId,
      index,
      depth,
    ]),
    [
      ["group", null, 0, 0],
      ["a", "group", 0, 1],
      ["nested", "group", 1, 1],
      ["b", "nested", 0, 2],
      ["c", "group", 2, 1],
      ["empty", null, 1, 0],
      ["leaf", null, 2, 0],
    ],
  );
  assert.deepEqual(
    flattenKSortableTree(tree, []).map(({ node }) => node.id),
    ["group", "empty", "leaf"],
  );
});

test("moves a subtree into an empty container without losing data or modifying input", () => {
  const before = structuredClone(tree);
  const result = moveKSortableTree(tree, {
    id: "nested",
    parentId: "empty",
    index: 0,
  });
  assert.deepEqual(tree, before);
  assert.equal(result[1].children[0], tree[0].children[1]);
  assert.deepEqual(
    result[0].children.map(({ id }) => id),
    ["a", "c"],
  );
});

test("same-parent move uses the index after removal in both directions", () => {
  const result = moveKSortableTree(tree, {
    id: "a",
    parentId: "group",
    index: 2,
  });
  assert.deepEqual(
    result[0].children.map(({ id }) => id),
    ["nested", "c", "a"],
  );
  assert.deepEqual(
    moveKSortableTree(result, { id: "a", parentId: "group", index: 0 }),
    tree,
  );
});

test("rejects cycles, leaf destinations, missing nodes, invalid indices and unchanged moves", () => {
  for (const move of [
    { id: "group", parentId: "nested", index: 0 },
    { id: "group", parentId: "group", index: 0 },
    { id: "a", parentId: "leaf", index: 0 },
    { id: "missing", parentId: null, index: 0 },
    { id: "a", parentId: "missing", index: 0 },
    { id: "a", parentId: null, index: -1 },
    { id: "a", parentId: null, index: 99 },
    { id: "a", parentId: null, index: 0.5 },
    { id: "a", parentId: "group", index: 0 },
  ])
    assert.equal(moveKSortableTree(tree, move), tree);
});

test("maximum depth checks the entire moved subtree, and unrestricted mode allows deep nesting", () => {
  const move = { id: "group", parentId: "empty", index: 0 };
  assert.equal(moveKSortableTree(tree, move, { maxDepth: 2 }), tree);
  assert.notEqual(moveKSortableTree(tree, move, { maxDepth: 3 }), tree);
  assert.notEqual(moveKSortableTree(tree, move), tree);
  assert.notEqual(
    moveKSortableTree(
      tree,
      { id: "b", parentId: null, index: 3 },
      { maxDepth: 0 },
    ),
    tree,
  );
});

test("duplicate IDs fail even inside collapsed branches", () => {
  assert.throws(
    () => flattenKSortableTree([...tree, { id: "a", label: "Duplicate" }], []),
    /Duplicate sortable tree ID/,
  );
});

test("minimum row height is exposed without changing measured content height", async () => {
  const { createElement } = await import("react");
  const { renderToStaticMarkup } = await import("react-dom/server");
  const { KSortableTree } = await import("./dist/patterns/sortable-tree.js");
  const html = renderToStaticMarkup(
    createElement(KSortableTree, {
      nodes: [{ id: "a", label: "A" }],
      onMove: () => {},
      minRowHeight: 140,
    }),
  );
  assert.match(html, /--k-tree-min-row-height:140px/);
  assert.match(html, /--k-tree-row-content-height:0px/);
});
