import assert from "node:assert/strict";
import test from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KMetricCard } from "./dist/data-display/metric-card.js";
import { metricTrendPath } from "./dist/data-display/metric-trend.js";

test("metric trends preserve zero, descending/flat values and missing observations", () => {
  assert.equal(metricTrendPath([0, 10]), "M0.00,24.00 L100.00,0.00");
  assert.equal(metricTrendPath([4, 4]), "M0.00,12.00 L100.00,12.00");
  assert.equal(
    metricTrendPath([8, 4, null, 2, 0]),
    "M0.00,0.00 L25.00,12.00  M75.00,18.00 L100.00,24.00",
  );
  assert.equal(metricTrendPath([NaN, null, Infinity]), "");
  assert.equal(metricTrendPath([null, 1]), "");
});

test("metric card has a named region and never fabricates a trend or comparison", () => {
  const html = renderToStaticMarkup(
    createElement(KMetricCard, {
      label: "Umsatz",
      value: "0 €",
      description: "noch keine Termine",
    }),
  );
  assert.match(html, /<article[^>]*aria-labelledby=/);
  assert.match(html, /Umsatz/);
  assert.match(html, /0 €/);
  assert.match(html, /noch keine Termine/);
  assert.doesNotMatch(html, /<svg|k-badge|<progress/);
});

test("trend and comparison carry readable labels; progress uses its actual maximum", () => {
  const html = renderToStaticMarkup(
    createElement(KMetricCard, {
      label: "Buchungen",
      value: "8",
      description: "heute 3",
      comparison: {
        label: "+3",
        description: "gegenüber der Vorperiode",
        sentiment: "positive",
      },
      trend: { values: [0, 2, 8], label: "Buchungen im Zeitraum" },
    }),
  );
  assert.match(html, /aria-label="\+3: gegenüber der Vorperiode"/);
  assert.match(html, /role="img" aria-label="Buchungen im Zeitraum"/);
  assert.doesNotMatch(html, /NaN|Infinity/);
  const progress = renderToStaticMarkup(
    createElement(KMetricCard, {
      label: "Auslastung",
      value: "25 %",
      description: "4 von 16 Stunden",
      progress: { value: 4, max: 16, label: "Arbeitszeit" },
    }),
  );
  assert.match(progress, /aria-valuemax="16" aria-valuenow="4"/);
  assert.match(progress, /aria-label="Arbeitszeit"/);
});
