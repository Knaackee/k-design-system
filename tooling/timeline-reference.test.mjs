import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  addDays,
  applyProposal,
  isDateKey,
} from "../packages/web/ui/src/data-display/timeline/timeline-model.ts";
const fixture = JSON.parse(
  readFileSync(
    new URL("../fixtures/timeline-reference.json", import.meta.url),
    "utf8",
  ),
);
const groups = fixture.groups.map((group) => group.id);
test("timeline date-only arithmetic crosses month and leap boundaries", () => {
  assert.equal(addDays("2026-09-30", 1), "2026-10-01");
  assert.equal(addDays("2024-03-01", -1), "2024-02-29");
  assert.equal(addDays("2026-03-29", 1), "2026-03-30");
  assert.equal(isDateKey("2026-02-30"), false);
  assert.equal(isDateKey("invalid"), false);
});
test("controlled proposals preserve identity and do not mutate caller records", () => {
  const original = structuredClone(fixture.items);
  const next = {
    ...fixture.items[0],
    start: "2026-09-23",
    end: "2026-09-27",
    group: "launch",
    label: "untrusted replacement",
  };
  const result = applyProposal(fixture.items, next, groups);
  assert.equal(result[0].label, fixture.items[0].label);
  assert.equal(result[0].start, "2026-09-23");
  assert.equal(result[0].group, "launch");
  assert.equal(result[1], fixture.items[1]);
  assert.deepEqual(fixture.items, original);
  assert.equal(
    applyProposal(fixture.items, next, groups, false),
    fixture.items,
  );
});
test("readonly, invalid and incompatible range proposals are rejected", () => {
  const locked = fixture.items.find((item) => item.readOnly);
  assert.equal(
    applyProposal(fixture.items, { ...locked, start: "2026-09-01" }, groups),
    fixture.items,
  );
  for (const patch of [
    { end: fixture.items[0].start },
    { start: "2026-02-30" },
    { group: "missing" },
    { end: undefined },
    { id: "unknown" },
  ]) {
    assert.equal(
      applyProposal(fixture.items, { ...fixture.items[0], ...patch }, groups),
      fixture.items,
    );
  }
  const point = fixture.items.find((item) => !item.end);
  assert.equal(
    applyProposal(fixture.items, { ...point, end: "2026-10-11" }, groups),
    fixture.items,
  );
});
test("reference fixture has stable IDs, valid groups and overlapping ranges", () => {
  assert.equal(fixture.items.length, 12);
  assert.equal(new Set(fixture.items.map((item) => item.id)).size, 12);
  for (const item of fixture.items) {
    assert.ok(groups.includes(item.group));
    assert.ok(isDateKey(item.start));
    if (item.end) assert.ok(isDateKey(item.end) && item.end > item.start);
  }
  assert.ok(fixture.items[1].start < fixture.items[0].end);
});
