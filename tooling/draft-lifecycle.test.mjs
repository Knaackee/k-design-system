import test from "node:test";
import assert from "node:assert/strict";
import { KDataTableDraftController } from "../packages/web/ui/src/data/data-table-draft.ts";
import { insertDataTableDrafts } from "../packages/web/ui/src/data/data-table-draft-placement.ts";
import { draftWindow } from "../packages/web/ui/src/data/data-table-draft-window.ts";
const row = { id: "new", title: "", status: "active" };
function setup(extra = {}) {
  const events = [];
  const c = new KDataTableDraftController({
    rowId: (r) => r.id,
    cloneRow: (r) => ({ ...r }),
    isEqual: (a, b) => JSON.stringify(a) === JSON.stringify(b),
    onCommit: (r) => r,
    onEvent: (e) => events.push(e),
    ...extra,
  });
  c.begin(row, { initialColumnId: "title" });
  return { c, events };
}
test("dirty property survives row exit, returning all defaults removes only draft", () => {
  const { c } = setup();
  c.update("new", { ...row, status: "done" });
  c.leave("new");
  assert.equal(c.get("new").status, "dirty");
  c.update("new", row);
  c.leave("new");
  assert.equal(c.get("new"), undefined);
  assert.equal(c.cancel("saved", "escape"), false);
});
test("Escape explicitly cancels changed new draft; snapshot isolation", () => {
  const { c, events } = setup();
  c.get("new").current.title = "outside";
  assert.equal(c.get("new").current.title, "");
  c.update("new", { ...row, title: "changed" });
  assert.equal(c.cancel("new", "escape"), true);
  assert.equal(events.at(-1).reason, "escape");
});
test("save coalesces and blocks update/cancel; exactly one completion", async () => {
  let resolve;
  const { c, events } = setup({
    onCommit: () => new Promise((r) => (resolve = r)),
  });
  const a = c.commit("new", "enter"),
    b = c.commit("new", "action");
  assert.equal(a, b);
  assert.equal(c.update("new", { ...row, title: "later" }), false);
  assert.equal(c.cancel("new"), false);
  await Promise.resolve();
  resolve(row);
  assert.equal(await a, true);
  assert.equal(c.get("new"), undefined);
  assert.equal(events.filter((e) => e.type === "committed").length, 1);
});
test("error retains values and permits retry, dispose ignores late result", async () => {
  let fail = true;
  const { c } = setup({
    onCommit: (r) => {
      if (fail) throw new Error("offline");
      return r;
    },
  });
  c.update("new", { ...row, title: "kept" });
  assert.equal(await c.commit("new"), false);
  assert.equal(c.get("new").current.title, "kept");
  assert.equal(c.get("new").status, "error");
  fail = false;
  assert.equal(await c.commit("new"), true);
  let resolve;
  const x = setup({ onCommit: () => new Promise((r) => (resolve = r)) });
  const pending = x.c.commit("new");
  await Promise.resolve();
  x.c.dispose();
  resolve(row);
  assert.equal(await pending, false);
  assert.equal(x.events.filter((e) => e.type === "committed").length, 0);
});
test("owned overlay retains pristine draft and release does not replay stale exit", () => {
  const { c } = setup();
  const release = c.retainInteraction("new");
  c.leave("new");
  release();
  release();
  assert.ok(c.get("new"));
  c.leave("new");
  assert.equal(c.get("new"), undefined);
});
test("optional rowExit save policy saves changed values", async () => {
  const { c } = setup({ savePolicy: "rowExit" });
  c.update("new", { ...row, title: "saved" });
  c.leave("new");
  await c.commit("new");
  assert.equal(c.get("new"), undefined);
});
test("draft is appended at captured origin even when values group differently", () => {
  const path = [{ id: "status", value: "active", label: "Active" }];
  const result = insertDataTableDrafts(
    [],
    [{ row: { ...row, status: "done" }, originPath: path }],
  );
  assert.equal(result[0].value, "active");
  assert.equal(result[0].children[0].rows[0].status, "done");
});
test("external local anchors preserve server range and reject stale revision", () => {
  const entries = [0, 1, 2].map((i) => ({
    kind: "item",
    id: `item:${i}`,
    row: { id: String(i) },
    path: [],
    depth: 0,
  }));
  const window = { queryRevision: "q", totalCount: 3, startIndex: 0, entries };
  const drafts = [0, 0, 3].map((index, i) => ({
    row: { id: `new${i}` },
    originPath: [],
    originIndex: index,
    originQueryRevision: "q",
  }));
  const p = draftWindow(window, drafts, "q", (r) => r.id);
  assert.equal(p.count, 6);
  assert.deepEqual(
    Array.from({ length: 6 }, (_, i) => p.entryAt(i).row.id),
    ["new0", "new1", "0", "1", "2", "new2"],
  );
  assert.equal(p.toServer(2), 0);
  assert.equal(p.toServer(6), 3);
  assert.throws(() => draftWindow(window, drafts, "other", (r) => r.id));
  assert.throws(() =>
    draftWindow(window, [{ ...drafts[0], originIndex: 4 }], "q", (r) => r.id),
  );
});
