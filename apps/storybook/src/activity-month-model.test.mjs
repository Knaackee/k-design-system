import assert from "node:assert/strict";
import { activityMonth } from "../../../packages/web/ui/src/data-display/activity-month-model.ts";

const october = activityMonth(0);
assert.equal(october.key, "2026-10");
assert.equal(october.weeks, 5);
assert.deepEqual(october.cells.slice(0, 4), [null, null, null, "2026-10-01"]);
assert.equal(october.cells.filter(Boolean).length, 31);
assert.equal(activityMonth(-2).weeks, 6); // August spans six week columns.
assert.equal(activityMonth(4).cells.filter(Boolean).length, 28);
assert.equal(activityMonth(16).cells.filter(Boolean).length, 29); // February 2028.
assert.equal(activityMonth(3).key, "2027-01");
assert.equal(activityMonth(0, "2032-02-15").cells.filter(Boolean).length, 29);
for (let offset = -12; offset <= 12; offset++) {
  const month = activityMonth(offset);
  assert.equal(month.cells.length, month.weeks * 7);
  assert.ok(month.weeks >= 4 && month.weeks <= 6);
  assert.equal(
    new Set(month.cells.filter(Boolean)).size,
    month.cells.filter(Boolean).length,
  );
  assert.ok(
    month.cells.filter(Boolean).every((date) => date.startsWith(month.key)),
  );
}
console.log(
  "Activity month geometry passed (25 months, leap year, year boundary).",
);
