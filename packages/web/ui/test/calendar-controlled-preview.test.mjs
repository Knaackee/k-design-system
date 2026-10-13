import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KCalendar } from "../dist/patterns/calendar.js";

const slot = (date, minutes, allDay = false) => ({
  date,
  minutes,
  allDay,
  timeZone: "UTC",
});
const baseProps = {
  date: new Date("2026-09-21T12:00:00Z"),
  view: "week",
  events: [],
  getEventId: (event) => event.id,
  getEventStart: (event) => event.start,
  getEventEnd: (event) => event.end,
  renderEvent: () => null,
  onCreate() {},
  onPendingCreateSelectionChange() {},
  locale: "en",
  timeZone: "UTC",
  startHour: 0,
  endHour: 8,
};

const previewCount = (html) =>
  (html.match(/class="k-calendar-selection-label"/g) ?? []).length;

test("controlled timed create preview is painted in only its selected day", () => {
  const html = renderToStaticMarkup(
    h(KCalendar, {
      ...baseProps,
      pendingCreateSelection: {
        start: slot("2026-09-23", 120),
        end: slot("2026-09-23", 150),
      },
    }),
  );
  assert.equal(previewCount(html), 1);
});

test("controlled all-day preview is scoped to its selected civil range", () => {
  const html = renderToStaticMarkup(
    h(KCalendar, {
      ...baseProps,
      pendingCreateSelection: {
        start: slot("2026-09-24", 0, true),
        end: slot("2026-09-25", 0, true),
      },
    }),
  );
  assert.equal(previewCount(html), 1);
});

test("controlled cancellation removes the create preview", () => {
  const html = renderToStaticMarkup(
    h(KCalendar, { ...baseProps, pendingCreateSelection: null }),
  );
  assert.equal(previewCount(html), 0);
});
