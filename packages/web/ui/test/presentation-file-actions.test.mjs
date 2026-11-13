import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KPresentationComparison } from "../dist/chat/presentations.js";
import {
  KPresentationFile,
  KPresentationGallery,
} from "../dist/chat/presentation-media.js";

test("file cards expose optional copy action with an accessible label and preserve the default", () => {
  const normal = renderToStaticMarkup(
    createElement(KPresentationFile, { name: "report.pdf" }),
  );
  assert.doesNotMatch(normal, /Save to Files/);
  const workspace = renderToStaticMarkup(
    createElement(KPresentationFile, {
      name: "report.pdf",
      onSave() {},
      saveLabel: "In Dateien speichern",
    }),
  );
  assert.match(workspace, /aria-label="In Dateien speichern: report.pdf"/);
});

test("gallery thumbnails retain logos without changing the photo default", () => {
  const html = renderToStaticMarkup(
    createElement(KPresentationGallery, {
      images: [
        { src: "https://example.com/photo.jpg", alt: "Photo" },
        { src: "https://example.com/logo.svg", alt: "Logo", fit: "contain" },
      ],
      selectedIndex: null,
      onSelectedIndexChange() {},
    }),
  );
  assert.match(html, /alt="Photo"[^>]*style="object-fit:cover"/);
  assert.match(html, /alt="Logo"[^>]*style="object-fit:contain"/);
});

test("comparison detail occupies its own row after both participants and the score", () => {
  const html = renderToStaticMarkup(
    createElement(KPresentationComparison, {
      label: "Bundesliga · Beendet",
      left: { name: "Borussia Mönchengladbach" },
      right: { name: "Eintracht Frankfurt" },
      value: "2 : 1",
      detail:
        "Endstand nach Verlängerung · Borussia zieht in die nächste Runde ein.",
    }),
  );
  assert.match(
    html,
    /__score"><strong>2 : 1<\/strong><\/div><div class="k-presentation-comparison__party"><strong>Eintracht Frankfurt<\/strong><\/div><\/div><small class="k-presentation-comparison__detail">Endstand nach Verlängerung/,
  );
});
