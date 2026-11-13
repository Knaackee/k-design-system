import assert from "node:assert/strict";
import test from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KColorSwatches } from "./dist/patterns/color-swatches.js";
import {
  KBookingPageLayout, KBookingPageActions,
  KBookingThemePicker,
} from "./dist/patterns/booking-page-management.js";
import { KSegmentedControl } from "./dist/navigation/segmented-control.js";
const options = Array.from({ length: 11 }, (_, i) => ({
  id: String(i),
  label: `Design ${i}`,
  image: `/${i}.png`,
}));

test("carousel makes every design accessible while the original grid keeps its four-item summary", () => {
  const props = { options, value: "8", onChange: () => {} };
  const legacy = renderToStaticMarkup(h(KBookingThemePicker, props));
  assert.equal((legacy.match(/aria-pressed=/g) ?? []).length, 4);
  assert.match(legacy, /Design 8/);
  const carousel = renderToStaticMarkup(
    h(KBookingThemePicker, {
      ...props,
      layout: "carousel",
      footer: "Colour controls",
    }),
  );
  assert.equal((carousel.match(/aria-pressed=/g) ?? []).length, 11);
  assert.match(carousel, /Alle 11 ansehen/);
  assert.match(carousel, /Colour controls/);
});
test("swatches announce names and selection and keep exactly one tab stop, including an unknown value", () => {
  const props = {
    options: [
      { value: "red", label: "Rot" },
      { value: "blue", label: "Blau" },
    ],
    label: "Markenfarbe",
    onValueChange: () => {},
  };
  for (const value of ["blue", "unknown"]) {
    const html = renderToStaticMarkup(h(KColorSwatches, { ...props, value }));
    assert.equal((html.match(/tabindex="0"/g) ?? []).length, 1);
    assert.match(html, /role="radiogroup" aria-label="Markenfarbe"/);
    assert.match(html, /aria-label="Blau" title="Blau"/);
  }
  const disabled = renderToStaticMarkup(
    h(KColorSwatches, { ...props, value: "red", disabled: true }),
  );
  assert.equal((disabled.match(/disabled=""/g) ?? []).length, 2);
});
test("icon-only segments retain accessible names and tooltips", () => {
  const html = renderToStaticMarkup(
    h(KSegmentedControl, {
      label: "Bildform",
      value: "square",
      segments: [
        { value: "square", label: "Eckig", icon: "square" },
        { value: "round", label: "Rund", icon: "circle" },
      ],
      showLabels: false,
      onValueChange: () => {},
    }),
  );
  assert.match(html, /aria-label="Eckig" title="Eckig"/);
  assert.match(html, /aria-label="Rund" title="Rund"/);
  assert.doesNotMatch(html, /k-segmented-control__label/);
});
test("settings preview is opt-in and retains supplied live renderer", () => {
  const html = renderToStaticMarkup(
    h(
      KBookingPageLayout,
      { presentation: "settings", preview: h("span", null, "Live draft") },
      "Form",
    ),
  );
  assert.match(html, /data-presentation="settings"/);
  assert.match(html, /Live draft/);
  assert.match(
    renderToStaticMarkup(h(KBookingPageLayout, { preview: "Preview" }, "Form")),
    /data-presentation="default"/,
  );
});

test("status actions retain four complete labels in the shared mobile pattern", () => {
  const html=renderToStaticMarkup(h(KBookingPageActions,{previewAction:h('button',null,'Vorschau')},['Teilen','Kopieren','QR-Code'].map(label=>h('button',{key:label},label))));
  assert.equal((html.match(/<button/g) ?? []).length,4);
  for (const label of ['Teilen','Kopieren','QR-Code','Vorschau']) assert.ok(html.includes(label));
});
