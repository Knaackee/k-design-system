import test from "node:test";
import assert from "node:assert/strict";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KPlanPicker } from "./dist/patterns/plan-picker.js";

const plans = [
  {
    id: "basic",
    name: "Basic",
    features: ["Booking"],
    prices: {
      monthly: {
        amount: "19 €",
        period: "/ month",
        billingNote: "19 € billed monthly",
      },
    },
  },
  {
    id: "plus",
    name: "Plus",
    features: ["Booking", "Routes"],
    prices: { monthly: { amount: "29 €" } },
  },
];
const props = {
  plans,
  value: "basic",
  onValueChange() {},
  intervals: [{ id: "monthly", label: "Monthly" }],
  interval: "monthly",
  onIntervalChange() {},
  label: "Plans",
  intervalLabel: "Billing",
  unavailableLabel: "Unavailable",
  actionLabel: "Continue",
  onContinue() {},
};
const render = (extra) =>
  renderToStaticMarkup(
    React.createElement(KPlanPicker, { ...props, ...extra }),
  );

test("no choice, unknown price or unknown interval cannot continue", () => {
  for (const extra of [
    { value: null },
    { interval: "yearly" },
    { intervals: [] },
    { plans: [{ ...plans[0], disabled: true }] },
  ]) {
    assert.match(render(extra), /<button[^>]*disabled=""/);
  }
});
test("single monthly offer has neither interval buttons nor selection radio", () => {
  const html = render({ plans: [plans[0]] });
  assert.doesNotMatch(html, /type="radio"/);
  assert.doesNotMatch(html, /k-plan-picker__intervals/);
  assert.match(html, /19 € billed monthly/);
  assert.doesNotMatch(html, /<button[^>]*disabled=""/);
});
test("unavailable plans remain visible but cannot be selected", () => {
  const html = render({ plans: [plans[0], { ...plans[1], prices: {} }] });
  const option = html.match(/<input[^>]*value="plus"[^>]*>/)?.[0];
  assert.ok(option);
  assert.match(option, /disabled=""/);
  assert.match(html, /Unavailable/);
});
test("comparison preserves supplied values and semantic table headings", () => {
  const html = render({
    layout: "comparison",
    comparison: {
      label: "Compare features",
      rows: [
        { id: "seats", label: "Seats", values: { basic: "1", plus: "5" } },
      ],
    },
  });
  assert.match(html, /<caption>Compare features<\/caption>/);
  assert.match(html, /<th scope="row">Seats<\/th>/);
  assert.match(html, />5<\/td>/);
});
test("loading locks selection and action", () => {
  const html = render({ loading: true });
  assert.match(html, /<fieldset[^>]*disabled=""/);
  assert.match(html, /<button[^>]*disabled=""[^>]*aria-busy="true"/);
});

test("pending payment disables action without locking billing selection", () => {
  const html = render({
    actionDisabled: true,
    intervals: [
      { id: "monthly", label: "Monthly" },
      { id: "yearly", label: "Yearly" },
    ],
  });
  assert.match(html, /<button[^>]*disabled=""/);
  assert.doesNotMatch(html, /<fieldset[^>]*disabled=""/);
});
