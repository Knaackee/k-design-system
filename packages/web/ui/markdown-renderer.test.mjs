import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KMarkdownRenderer, KMarkdownPreview } from "./dist/markdown/index.js";
import { markdownTableText } from "./dist/markdown/markdown-renderer.js";

const streamingSequence = JSON.parse(
  readFileSync(
    new URL(
      "../../../fixtures/markdown/streaming-sequence.json",
      import.meta.url,
    ),
    "utf8",
  ),
);

const render = (content, props = {}) =>
  renderToStaticMarkup(
    React.createElement(KMarkdownRenderer, { content, ...props }),
  );

test("renderer preserves GFM structure, alignment and task state", () => {
  const html = render(
    "# Release\n\n| Name | Count |\n| :--- | ---: |\n| Ready | 42 |\n\n- [x] Done\n- [ ] Pending",
  );
  assert.match(html, /<h1[^>]*>Release/);
  assert.match(html, /text-align:right/);
  assert.match(html, /class="k-checkbox/);
  assert.match(html, /disabled=""[^>]*checked=""/);
  assert.doesNotMatch(html, /k-button--ghost/);
});

test("allowedElements unwraps formatting without dropping text", () => {
  const html = render("# Title\n\n**Strong** and [link](https://example.com)", {
    allowedElements: ["p"],
  });
  assert.doesNotMatch(html, /<h1|<strong|<a /);
  assert.match(html, /Title/);
  assert.match(html, /Strong/);
  assert.match(html, /link/);
});

test("untrusted HTML and unsafe image/link protocols never reach custom rendering", () => {
  const seen = [];
  const html = render(
    "<script>alert(1)</script>\n\n[bad](javascript:alert%281%29)\n\n![bad](data:image/svg+xml,evil)\n\n![good](./picture.png)",
    {
      renderImage: (image) => {
        seen.push(image.src);
        return React.createElement("span", null, image.alt);
      },
    },
  );
  assert.doesNotMatch(html, /<script|href="javascript:|src="data:/);
  assert.deepEqual(seen, ["./picture.png"]);
});

test("code uses supported syntax tokens and copy actions are consumer opt-in", () => {
  const content = "```js\nconst count = 42;\n```";
  assert.match(render(content), /tok-keyword/);
  assert.doesNotMatch(render(content), /<button/);
  assert.match(
    render(content, { onCopy: () => {}, copyLabel: "Kopieren" }),
    /Kopieren/,
  );
  assert.match(render("```unknown\nplain text\n```"), /plain text/);
});

test("alerts use the K alert primitive and accept localized titles", () => {
  const html = render("> [!NOTE]\n> A useful note.", {
    alertLabels: { NOTE: "Hinweis" },
  });
  assert.match(html, /k-alert/);
  assert.match(html, /Hinweis/);
  assert.match(html, /A useful note/);
  assert.doesNotMatch(html, /\[!NOTE\]/);
});

test("preview loading and empty slots do not expose hidden document contents", () => {
  const loading = renderToStaticMarkup(
    React.createElement(KMarkdownPreview, {
      content: "hidden",
      loading: true,
      loadingContent: "Loading",
    }),
  );
  assert.match(loading, /aria-busy="true"/);
  assert.match(loading, /Loading/);
  assert.doesNotMatch(loading, /hidden/);
  const empty = renderToStaticMarkup(
    React.createElement(KMarkdownPreview, {
      content: "  ",
      emptyContent: "Nothing yet",
    }),
  );
  assert.match(empty, /Nothing yet/);
});

test("table copy emits header and data rows as TSV, without formatting markup", () => {
  const element = (tagName, children) => ({
    type: "element",
    tagName,
    children,
  });
  const text = (value) => ({ type: "text", value });
  const copied = markdownTableText(
    element("table", [
      text("\n"),
      element("thead", [
        element("tr", [
          element("th", [text("Name")]),
          element("th", [text("Count")]),
        ]),
      ]),
      text("\n"),
      element("tbody", [
        element("tr", [
          element("td", [element("strong", [text("Ready")])]),
          element("td", [text("42")]),
        ]),
      ]),
    ]),
  );
  assert.equal(copied, "Name\tCount\nReady\t42");
});

test("shared streaming frames commit only finished Markdown blocks", () => {
  const frames = Object.fromEntries(
    streamingSequence.map(({ id, content, streaming }) => [
      id,
      render(content, { streaming, profile: "chat" }),
    ]),
  );
  for (const [id, html] of Object.entries(frames)) {
    assert.match(html, /<h2\b[^>]*>Live-Bericht<\/h2>/, id);
    assert.match(html, /Die Prüfung startet\./, id);
    if (id !== "complete") assert.match(html, /aria-busy="true"/, id);
  }
  assert.match(frames["open-emphasis"], /\*\*Ergebnis/);
  assert.doesNotMatch(frames["open-emphasis"], /<strong>/);
  assert.match(frames["closed-emphasis"], /<strong>Ergebnis:<\/strong>/);
  assert.match(
    frames["open-link"],
    /\[Dokumentation\]\(https:\/\/example\.org\/d/,
  );
  assert.doesNotMatch(frames["open-link"], /<a /);
  assert.match(frames["closed-link"], /href="https:\/\/example\.org\/docs"/);
  assert.match(frames["open-code"], /k-markdown__code-block/);
  assert.match(frames["closed-code"], /bereit/);
  assert.match(frames["open-table"], /\| Plattform \| Status \|/);
  assert.doesNotMatch(frames["open-table"], /<table/);
  assert.match(frames["closed-table"], /<table/);
  assert.equal(
    frames.complete,
    render(streamingSequence.at(-1).content, { profile: "chat" }),
  );
});

test("streaming respects fence marker and length and keeps unfinished HTML inert", () => {
  const html = render(
    "Paragraph\r\n~~~~md\r\n```\r\n~~~\r\n\r\nStill inside\r\n~~~~\r\n<img src=x>",
    {
      streaming: true,
    },
  );
  assert.match(html, /k-markdown__code-block/);
  assert.match(html, /Still inside/);
  assert.match(html, /&lt;img src=x&gt;/);
  assert.doesNotMatch(html, /<img /);
});
