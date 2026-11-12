import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
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
