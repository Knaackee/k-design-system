import test from "node:test";
import assert from "node:assert/strict";
import {
  validDate,
  validTime,
  validInstant,
  formatDate,
  parseDate,
  formatTime,
  parseTime,
  resolveLocal,
  zoneParts,
  inRange,
  addMonths,
  validateConfiguration,
  validateMinuteStep,
} from "../packages/web/ui/src/pickers/date-values.ts";
test("date formats reject normalization and retain leap days", () => {
  assert.equal(validDate("2024-02-29"), true);
  for (const value of ["2026-02-29", "2026-04-31", "2026-13-01", "0000-01-01"])
    assert.equal(validDate(value), false);
  for (const [format, text] of [
    ["iso", "2026-09-16"],
    ["dayMonthYear", "16.09.2026"],
    ["monthDayYear", "09/16/2026"],
  ]) {
    assert.equal(formatDate("2026-09-16", format), text);
    assert.equal(parseDate(text, format), "2026-09-16");
  }
  assert.equal(parseDate("31.02.2026", "dayMonthYear"), null);
  assert.equal(addMonths("2024-01-31", 1), "2024-02-29");
  assert.equal(addMonths("2024-02-29", 12), "2025-02-28");
});
test("time formats distinguish midnight noon and invalid hours", () => {
  assert.equal(parseTime("12:00 AM", "h12"), "00:00");
  assert.equal(parseTime("12:00 PM", "h12"), "12:00");
  assert.equal(parseTime("2:30 pm", "h12"), "14:30");
  assert.equal(formatTime("00:05", "h12"), "12:05 AM");
  assert.equal(formatTime("14:30", "h12"), "02:30 PM");
  assert.equal(validTime("24:00"), false);
  assert.equal(parseTime("13:00 PM", "h12"), null);
  assert.equal(parseTime("14:60", "h24"), null);
});
test("IANA timezone formatting and UTC callbacks agree", () => {
  assert.deepEqual(
    zoneParts(new Date("2026-09-16T12:30:00Z"), "Europe/Berlin"),
    { date: "2026-09-16", time: "14:30" },
  );
  assert.deepEqual(
    zoneParts(new Date("2026-09-16T12:30:00Z"), "America/New_York"),
    { date: "2026-09-16", time: "08:30" },
  );
  assert.deepEqual(
    resolveLocal("2026-09-16", "14:30", "Europe/Berlin", "reject"),
    { value: "2026-09-16T12:30:00.000Z" },
  );
  assert.deepEqual(
    resolveLocal("2026-09-16", "00:15", "Asia/Kathmandu", "reject"),
    { value: "2026-09-15T18:30:00.000Z" },
  );
});
test("DST gaps reject and overlaps require an explicit policy", () => {
  assert.deepEqual(
    resolveLocal("2026-03-29", "02:30", "Europe/Berlin", "earlier"),
    { error: "nonexistent" },
  );
  assert.deepEqual(
    resolveLocal("2026-10-25", "02:30", "Europe/Berlin", "reject"),
    { error: "ambiguous" },
  );
  assert.deepEqual(
    resolveLocal("2026-10-25", "02:30", "Europe/Berlin", "earlier"),
    { value: "2026-10-25T00:30:00.000Z" },
  );
  assert.deepEqual(
    resolveLocal("2026-10-25", "02:30", "Europe/Berlin", "later"),
    { value: "2026-10-25T01:30:00.000Z" },
  );
});
test("bounds and configuration reject invalid values", () => {
  assert.equal(inRange("2026-09-16", "date", "2026-09-16", "2026-09-16"), true);
  assert.equal(inRange("09:00", "time", "10:00"), false);
  assert.equal(
    inRange("2026-09-16T12:30:00.000Z", "datetime", "2026-09-16T12:30:00Z"),
    true,
  );
  assert.equal(validInstant("2026-02-30T00:00:00Z"), false);
  assert.equal(validInstant("2026-09-16T12:30:01Z"), false);
  assert.throws(() =>
    validateConfiguration("date", null, "2026-10-01", "2026-09-01", "UTC"),
  );
  assert.throws(() =>
    validateConfiguration("time", null, undefined, undefined, "Invalid/Zone"),
  );
});

test("minute steps form an even positive subdivision of one hour", () => {
  for (const step of [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30])
    assert.doesNotThrow(() => validateMinuteStep(step));
  for (const step of [0, -1, 7, 60, 1.5, NaN, Infinity])
    assert.throws(() => validateMinuteStep(step), RangeError);
});
