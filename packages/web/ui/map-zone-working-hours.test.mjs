import test from "node:test";
import assert from "node:assert/strict";
import {
  validZoneWorkingHours,
  normalizeZoneSettings,
} from "./dist/editors/map-zone-editor-properties-state.js";
import { nextZoneWorkingWindows } from "./dist/editors/map-zone-editor-working-hours.js";
const week = () =>
  Array.from({ length: 7 }, (_, index) => ({
    day: index + 1,
    intervals:
      index === 0
        ? [
            { start: "09:00", end: "12:00" },
            { start: "13:00", end: "17:00" },
          ]
        : [],
  }));
const now = new Date("2026-10-19T07:00:00Z");
test("seven unique days and ordered nonoverlapping same-day intervals", () => {
  assert.equal(validZoneWorkingHours(week()), true);
  assert.equal(validZoneWorkingHours([]), false);
  const invalid = week();
  invalid[1].day = 1;
  assert.equal(validZoneWorkingHours(invalid), false);
  const overlap = week();
  overlap[0].intervals[1].start = "11:00";
  assert.equal(validZoneWorkingHours(overlap), false);
  const overnight = week();
  overnight[0].intervals[0] = { start: "22:00", end: "02:00" };
  assert.equal(validZoneWorkingHours(overnight), false);
});
test("legacy default snapshot preserves empty explicit weeks and does not alias source", () => {
  const defaults = week();
  const copy = normalizeZoneSettings(undefined, {
    defaultWorkingHours: defaults,
  }).settings.workingHours;
  copy[0].intervals[0].start = "10:00";
  assert.equal(defaults[0].intervals[0].start, "09:00");
  const closed = week().map((day) => ({ ...day, intervals: [] }));
  assert.deepEqual(
    normalizeZoneSettings(
      { workingHours: closed },
      { defaultWorkingHours: defaults },
    ).settings.workingHours,
    closed,
  );
  assert.deepEqual(
    nextZoneWorkingWindows(undefined, undefined, "Europe/Berlin", now),
    [],
  );
});
test("preview intersects weekly hours with date range and recurrence", () => {
  assert.deepEqual(
    nextZoneWorkingWindows(week(), undefined, "Europe/Berlin", now).map(
      (slot) => slot.date,
    ),
    ["2026-10-19", "2026-10-26", "2026-11-02"],
  );
  assert.deepEqual(
    nextZoneWorkingWindows(
      week(),
      { kind: "date-range", from: "2026-10-20", to: "2026-10-30" },
      "Europe/Berlin",
      now,
    ).map((slot) => slot.date),
    ["2026-10-26"],
  );
  assert.deepEqual(
    nextZoneWorkingWindows(
      week(),
      {
        kind: "recurring",
        rrule: "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO",
        startDate: "2026-10-19",
        timeZone: "Europe/Berlin",
      },
      "Europe/Berlin",
      now,
    ).map((slot) => slot.date),
    ["2026-10-19", "2026-11-02", "2026-11-16"],
  );
});

test("preview excludes elapsed local intervals and retains ongoing ones", () => {
  const midday = nextZoneWorkingWindows(
    week(),
    undefined,
    "Europe/Berlin",
    new Date("2026-10-19T10:00:00Z"),
  );
  assert.equal(midday[0].date, "2026-10-19");
  assert.deepEqual(midday[0].intervals, [{ start: "13:00", end: "17:00" }]);
  const ongoing = nextZoneWorkingWindows(
    week(),
    undefined,
    "Europe/Berlin",
    new Date("2026-10-19T12:30:00Z"),
  );
  assert.equal(ongoing[0].date, "2026-10-19");
  assert.deepEqual(ongoing[0].intervals, [{ start: "13:00", end: "17:00" }]);
  const ended = nextZoneWorkingWindows(
    week(),
    undefined,
    "Europe/Berlin",
    new Date("2026-10-19T15:00:00Z"),
  );
  assert.equal(ended[0].date, "2026-10-26");
});
