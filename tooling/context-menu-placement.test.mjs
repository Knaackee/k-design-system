import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

test("submenu flip CSS consumes the placement attribute rather than the action ID", () => {
  const source = readFileSync(
    new URL("../packages/web/ui/src/actions/context-menu.tsx", import.meta.url),
    "utf8",
  );
  const css = readFileSync(
    new URL("../packages/web/ui/src/actions.css", import.meta.url),
    "utf8",
  );
  assert.match(source, /container\.dataset\.side = "left"/);
  assert.match(source, /data-context-submenu=\{action\.id\}/);
  assert.match(
    css,
    /\[data-context-submenu\]\[data-side="left"\]\s*>\s*\.k-context-menu__submenu\s*\{[^}]*right:[^}]*left:\s*auto/s,
  );
  assert.doesNotMatch(css, /\[data-context-submenu="left"\]/);
});
