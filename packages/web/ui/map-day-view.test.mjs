import assert from "node:assert/strict";
import test from "node:test";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import {
  KMapDaySheetController,
  KMapDayView,
} from "./dist/patterns/map-day-view.js";

const item = {
  id: "visit",
  start: 600,
  end: 630,
  expectedStart: 605,
  title: "Visit",
  detail: "Address",
  icon: "map-pin",
  kind: "stop",
};
const render = (props = {}) =>
  renderToStaticMarkup(
    React.createElement(KMapDayView, {
      items: [item],
      currentTime: 610,
      title: "Day",
      dayLabel: "Tuesday",
      renderMap: () => null,
      ...props,
    }),
  );

test("keeps planned time and forecast separate, forwards controlled selection to map", () => {
  let selection;
  const html = render({
    selectedItemId: "visit",
    renderMap: (context) => {
      selection = context.selectedItemId;
      return null;
    },
  });
  assert.equal(selection, "visit");
  assert.match(html, /<time>10:00<\/time>/);
  assert.match(html, /10:05/);
  assert.match(html, /aria-pressed="true"/);
  assert.match(html, /aria-current="step"/);
});

test("optional time and forecast presentation can be disabled; empty days render", () => {
  const html = render({ showCurrentTime: false, showForecasts: false });
  assert.doesNotMatch(html, /k-day-time-line|k-day-now-summary|k-day-delay/);
  assert.doesNotThrow(() => render({ items: [], selectedItemId: "removed" }));
});

test("all built-in status and forecast text can be localized", () => {
  const html = render({
    labels: {
      now: "Current",
      expected: "Forecast",
      minutes: "minutes",
      later: "late",
      earlier: "early",
    },
  });
  assert.match(html, /Current/);
  assert.match(html, /Forecast 10:05 · 5 minutes late/);
  assert.doesNotMatch(html, /Jetzt laut Plan|Erwartet|Min\. später/);
});

test("controlled panel state wins and invalid height order is rejected", () => {
  assert.match(
    render({ defaultPanelState: 0, panelState: 2 }),
    /data-snap="2"/,
  );
  assert.throws(() => render({ panelHeights: [60, 30, 90] }), RangeError);
});

test("sheet controller exposes attachment state and forwards position commands", async () => {
  const controller = new KMapDaySheetController();
  assert.equal(controller.isAttached, false);
  assert.equal(controller.isSheet, false);
  assert.equal(controller.fraction, 0);
  assert.equal(controller.state, null);
  await controller.animateTo(0.45);

  const calls = [];
  let fraction = 0.45;
  const detach = controller._attach({
    getIsSheet: () => true,
    getFraction: () => fraction,
    getState: () => null,
    animateTo: async (value) => {
      calls.push(["animate", value]);
      fraction = value;
    },
    snapTo: async (state) => calls.push(["snap", state]),
  });
  assert.equal(controller.isAttached, true);
  assert.equal(controller.isSheet, true);
  assert.equal(controller.fraction, 0.45);
  await controller.animateTo(0.6);
  await controller.snapTo(2);
  assert.deepEqual(calls, [
    ["animate", 0.6],
    ["snap", 2],
  ]);
  assert.throws(() => controller._attach({}), /already attached/);
  await assert.rejects(controller.animateTo(Number.NaN), RangeError);
  await assert.rejects(controller.animateTo(1.1), RangeError);
  await assert.rejects(controller.snapTo(3), RangeError);
  detach();
  assert.equal(controller.isAttached, false);
});
