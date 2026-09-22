import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { registerHooks } from "node:module";
import test from "node:test";

const sourceRoot = new URL("../packages/web/ui/src/", import.meta.url);
const hook = registerHooks({
  resolve(specifier, context, nextResolve) {
    if (
      specifier.startsWith(".") &&
      specifier.endsWith(".js") &&
      context.parentURL?.startsWith(sourceRoot.href)
    ) {
      const source = new URL(
        specifier.replace(/\.js$/, ".ts"),
        context.parentURL,
      );
      if (existsSync(source)) return nextResolve(source.href, context);
    }
    return nextResolve(specifier, context);
  },
});
const {
  calendarDays,
  instantSlot,
  intersects,
  kCalendarSlotToDate,
  orderedSelection,
  shiftSlot,
  slot,
  timeLanes,
} = await import("../packages/web/ui/src/patterns/calendar-model.ts");
hook.deregister();
const zone = "Europe/Berlin";
const at = (date, minutes, allDay = false) => slot(date, minutes, allDay, zone);
const entry = (id, start, end) => ({ id, event: id, start, end });

test("calendar converts civil wall time independently of host timezone", () => {
  const start = at("2026-09-21", 9 * 60);
  assert.equal(
    kCalendarSlotToDate(start).toISOString(),
    "2026-09-21T07:00:00.000Z",
  );
  assert.deepEqual(
    instantSlot(new Date("2026-09-21T07:00:00Z"), false, zone),
    start,
  );
  const allDay = at("2026-09-21", 0, true);
  assert.equal(
    kCalendarSlotToDate(allDay).toISOString(),
    "2026-09-21T00:00:00.000Z",
  );
  assert.deepEqual(
    instantSlot(new Date("2026-09-21T00:00:00Z"), true, "America/Los_Angeles")
      .date,
    "2026-09-21",
  );
});

test("calendar rejects nonexistent and ambiguous DST slots by default", () => {
  assert.equal(kCalendarSlotToDate(at("2026-03-29", 150)), null);
  assert.equal(kCalendarSlotToDate(at("2026-10-25", 150)), null);
  assert.equal(
    kCalendarSlotToDate(at("2026-10-25", 150), "earlier").toISOString(),
    "2026-10-25T00:30:00.000Z",
  );
  assert.equal(
    kCalendarSlotToDate(at("2026-10-25", 150), "later").toISOString(),
    "2026-10-25T01:30:00.000Z",
  );
  assert.equal(kCalendarSlotToDate(at("2026-03-29", 150), "later"), null);
});

test("calendar normalizes slot shifts across midnight and year boundaries", () => {
  assert.deepEqual(
    shiftSlot(at("2026-12-31", 23 * 60 + 30), 90),
    at("2027-01-01", 60),
  );
  assert.deepEqual(
    shiftSlot(at("2026-01-01", 0), -30),
    at("2025-12-31", 23 * 60 + 30),
  );
});

test("all-day intersection respects exclusive end, including ranges crossing weeks", () => {
  const item = entry(
    "release",
    at("2026-09-21", 0, true),
    at("2026-09-29", 0, true),
  );
  assert.equal(intersects(item, "2026-09-14", "2026-09-20"), false);
  assert.equal(intersects(item, "2026-09-21", "2026-09-27"), true);
  assert.equal(intersects(item, "2026-09-28", "2026-10-04"), true);
  assert.equal(intersects(item, "2026-09-29", "2026-09-29"), false);
  const overnight = entry(
    "night",
    at("2026-09-21", 23 * 60),
    at("2026-09-22", 30),
  );
  assert.equal(intersects(overnight, "2026-09-22", "2026-09-22"), true);
});

test("overlap lanes reuse freed lanes and reset after connected clusters", () => {
  const a = entry("a", at("2026-09-21", 540), at("2026-09-21", 630));
  const b = entry("b", at("2026-09-21", 570), at("2026-09-21", 600));
  const c = entry("c", at("2026-09-21", 600), at("2026-09-21", 660));
  const d = entry("d", at("2026-09-21", 660), at("2026-09-21", 690));
  const input = [d, c, a, b];
  const lanes = timeLanes(input);
  assert.deepEqual(
    lanes.map(({ entry: item, lane, lanes }) => [item.id, lane, lanes]),
    [
      ["a", 0, 2],
      ["b", 1, 2],
      ["c", 1, 2],
      ["d", 0, 1],
    ],
  );
  assert.deepEqual(
    input.map((item) => item.id),
    ["d", "c", "a", "b"],
  );
});

test("equal-start events use stable lane order and maximum concurrent lanes", () => {
  const lanes = timeLanes([
    entry("short", at("2026-09-21", 540), at("2026-09-21", 570)),
    entry("long", at("2026-09-21", 540), at("2026-09-21", 660)),
    entry("middle", at("2026-09-21", 550), at("2026-09-21", 620)),
  ]);
  assert.deepEqual(
    lanes.map(({ entry: item, lane, lanes }) => [item.id, lane, lanes]),
    [
      ["long", 0, 3],
      ["short", 1, 3],
      ["middle", 2, 3],
    ],
  );
});

test("calendar periods honor timezone and configured week start", () => {
  const anchor = new Date("2026-09-21T12:00:00Z");
  const week = calendarDays(anchor, "week", zone, 1);
  assert.equal(week.length, 7);
  assert.equal(week[0], "2026-09-21");
  assert.equal(week.at(-1), "2026-09-27");
  assert.equal(calendarDays(anchor, "week", zone, 0)[0], "2026-09-20");
  const month = calendarDays(anchor, "month", zone, 1);
  assert.equal(month.length, 42);
  assert.equal(month[0], "2026-08-31");
  assert.equal(month.at(-1), "2026-10-11");
  assert.deepEqual(
    calendarDays(new Date("2026-09-21T23:30:00Z"), "day", zone, 1),
    ["2026-09-22"],
  );
  assert.deepEqual(calendarDays(anchor, "three-day", zone, 1), [
    "2026-09-21",
    "2026-09-22",
    "2026-09-23",
  ]);
});

test("selection orders reversed drags and includes the final selected cell", () => {
  assert.deepEqual(
    orderedSelection(at("2026-09-21", 660), at("2026-09-21", 540), 30),
    { start: at("2026-09-21", 540), end: at("2026-09-21", 690) },
  );
  assert.deepEqual(
    orderedSelection(at("2026-09-23", 0, true), at("2026-09-21", 0, true), 30),
    { start: at("2026-09-21", 0, true), end: at("2026-09-24", 0, true) },
  );
  assert.deepEqual(
    orderedSelection(at("2026-09-21", 1410), at("2026-09-21", 1410), 30),
    { start: at("2026-09-21", 1410), end: at("2026-09-22", 0) },
  );
});
