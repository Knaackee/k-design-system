import test from "node:test";
import assert from "node:assert/strict";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KMarkdownPreview } from "./dist/editors/markdown-preview.js";

const render = (markdown, props = {}) =>
  renderToStaticMarkup(
    React.createElement(KMarkdownPreview, {
      markdown,
      ariaLabel: "Preview",
      ...props,
    }),
  );

test("preview renders GFM tables, images and code without modifying source", () => {
  const text =
    "| Name | Value |\n| --- | --- |\n| first | **second** |\n\n![Diagram](https://example.com/diagram.png)\n\n```js\nconst answer = 42;\n```";
  const html = render(text);
  assert.match(html, /<table/);
  assert.match(html, /<strong>second<\/strong>/);
  assert.match(html, /alt="Diagram"/);
  assert.match(html, /const answer = 42/);
});

test("preview omits raw HTML and executable URLs", () => {
  const html = render(
    "<script>alert(1)</script>\n\n[bad](javascript:alert%281%29)\n\n<img src=x onerror=alert(1)>",
  );
  assert.doesNotMatch(html, /<script|<img[^>]*onerror=|href="javascript:/);
});

test("host resolves relative images without replacing the Markdown document", () => {
  const images = [];
  const html = render('![Local](./picture.png "Caption")', {
    renderImage: (image) => {
      images.push(image);
      return React.createElement("span", null, image.alt);
    },
  });
  assert.equal(images.length, 1);
  assert.equal(images[0].src, "./picture.png");
  assert.equal(images[0].alt, "Local");
  assert.match(html, /<span>Local<\/span>/);
});
