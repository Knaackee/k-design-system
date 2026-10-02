import assert from "node:assert/strict";
import { activityDayStatus } from "../../../packages/web/ui/src/data-display/activity-status-model.ts";

const cases = [
  [[], false, [0, "empty", 0, 0]],
  [[{ completed: false }], false, [1, "open", 1, 0]],
  [[{ completed: true }, { completed: false }], false, [2, "open", 1, 1]],
  [
    Array.from({ length: 3 }, () => ({ completed: true })),
    false,
    [2, "done", 0, 3],
  ],
  [
    Array.from({ length: 4 }, () => ({ completed: true })),
    false,
    [3, "done", 0, 4],
  ],
  [
    Array.from({ length: 8 }, () => ({ completed: true })),
    false,
    [4, "done", 0, 8],
  ],
  [[{}], true, [1, "done", 0, 1]],
];

for (const [items, legacyCompleted, expected] of cases) {
  const result = activityDayStatus(items, legacyCompleted);
  assert.deepEqual(
    [result.level, result.tone, result.open, result.completed],
    expected,
  );
}

console.log("Activity status colors and fixed quantity levels passed.");
