import assert from "node:assert/strict";
import test from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KInlineSideSheet } from "./dist/overlays/inline-side-sheet.js";
import { KButton } from "./dist/primitives/button.js";
import {
  sheetDetentConfiguration,
  sheetHandoffSnap,
} from "./dist/overlays/sheet-detents.js";

test("inline hero sheet has an accessible region, one close action and a fixed footer", () => {
  const html = renderToStaticMarkup(
    createElement(
      KInlineSideSheet,
      {
        open: true,
        onOpenChange: () => {},
        title: "Booking details",
        hero: "Map",
        floatingActions: "More",
        heroOverlays: "Travel time",
        footer: "Confirmation",
        closeLabel: "Close details",
      },
      "Booking content",
    ),
  );
  assert.match(html, /role="region" aria-labelledby=/);
  assert.match(html, /k-overlay-header--hidden/);
  assert.equal((html.match(/aria-label="Close details"/g) ?? []).length, 1);
  assert.ok(html.indexOf("Map") < html.indexOf("Booking content"));
  assert.match(html, /<footer[^>]*>Confirmation<\/footer>/);
  assert.doesNotMatch(html, /aria-modal|k-overlay-backdrop/);
});

test("closed and guarded inline sheets cannot expose a close action", () => {
  const props = {
    open: false,
    onOpenChange: () => {},
    title: "Details",
    hero: "Map",
    children: "Content",
  };
  assert.equal(
    renderToStaticMarkup(createElement(KInlineSideSheet, props)),
    "",
  );
  const html = renderToStaticMarkup(
    createElement(KInlineSideSheet, {
      ...props,
      open: true,
      dismissible: false,
    }),
  );
  assert.doesNotMatch(html, /<button/);
});

test("destructive tone is explicit and leaves ordinary buttons unchanged", () => {
  assert.doesNotMatch(
    renderToStaticMarkup(createElement(KButton, null, "Save")),
    /data-tone/,
  );
  assert.match(
    renderToStaticMarkup(
      createElement(KButton, { tone: "destructive" }, "Cancel booking"),
    ),
    /data-tone="destructive"/,
  );
});

test("named detents keep the legacy default and order close, half, full", () => {
  assert.deepEqual(sheetDetentConfiguration(), {
    enabled: false,
    points: [0, 1],
    initialSnap: 1,
  });
  assert.deepEqual(sheetDetentConfiguration(["full", "half"]), {
    enabled: true,
    points: [0, 0.5, 1],
    initialSnap: 1,
  });
  assert.equal(
    sheetDetentConfiguration(["half", "full"], "full").initialSnap,
    2,
  );
});

test("list scroll handoff settles at half before closing, respects guards and cancellation", () => {
  const snaps = [0, 0.5, 1];
  assert.equal(sheetHandoffSnap(300, 800, snaps, 2, false, true, false), 1);
  assert.equal(sheetHandoffSnap(650, 800, snaps, 2, false, true, false), 0);
  assert.equal(sheetHandoffSnap(650, 800, snaps, 2, false, false, false), 1);
  assert.equal(sheetHandoffSnap(50, 800, snaps, 2, true, true, false), 1);
  assert.equal(sheetHandoffSnap(650, 800, snaps, 2, false, true, true), 2);
});
