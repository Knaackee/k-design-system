import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KPresentationPicture } from "../dist/chat/presentation-picture.js";

test("sourced SVG logos remain isolated img resources with their public source URL", () => {
  const url =
    "https://assets.bundesliga.com/clublogos/DFL-SEA-0001KA/DFL-CLU-000010.svg?fit=70,70";
  const html = renderToStaticMarkup(
    createElement(KPresentationPicture, { src: url, alt: "FC Augsburg" }),
  );
  assert.match(html, /<img /);
  assert.ok(html.includes(`src="${url}"`));
  assert.match(html, /referrerPolicy="no-referrer"/);
  assert.doesNotMatch(html, /<(?:svg|iframe|object|embed|script)\b/);
});
