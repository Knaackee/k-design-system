import test from "node:test";
import assert from "node:assert/strict";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { MenuLevel } from "./dist/actions/context-menu.js";
import { KMenuButton } from "./dist/actions/menu-button.js";

const actions = [
  {
    id: "selected",
    label: "Hoch",
    checked: true,
    iconContent: React.createElement("svg", { width: 48 }),
  },
  { id: "other", label: "Niedrig", checked: false },
  { id: "plain", label: "Issue-ID kopieren" },
];
for (const [name, render] of [
  ["nested", () => React.createElement(MenuLevel, { actions, close() {} })],
  [
    "flat",
    () => React.createElement(KMenuButton, { actions, label: "Actions" }),
  ],
]) {
  test(`${name} rows reserve identical leading and trailing slots and expose selection`, () => {
    const html = renderToStaticMarkup(render());
    assert.equal((html.match(/class="k-menu__icon"/g) ?? []).length, 3);
    assert.equal((html.match(/class="k-menu__label"/g) ?? []).length, 3);
    assert.equal((html.match(/class="k-menu__trailing"/g) ?? []).length, 3);
    assert.match(html, /role="menuitemradio" aria-checked="true"/);
    assert.match(html, /role="menuitemradio" aria-checked="false"/);
    assert.match(html, /class="k-menu__trailing" aria-hidden="true"><\/span>/);
  });
}
