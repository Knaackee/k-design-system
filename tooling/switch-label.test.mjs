import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { test } from "node:test";
import { readFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";
const require = createRequire(
  new URL("../packages/web/ui/package.json", import.meta.url),
);
const { createElement } = require("react");
const { renderToStaticMarkup } = require("react-dom/server");
const ts = require("typescript");
const source = await readFile(
  new URL("../packages/web/ui/src/extended-components.tsx", import.meta.url),
  "utf8",
);
const component = source.slice(
  source.indexOf("export interface KSwitchProps"),
  source.indexOf("export interface KSliderProps"),
);
const output = ts
  .transpileModule(component, {
    compilerOptions: {
      module: ts.ModuleKind.ESNext,
      jsx: ts.JsxEmit.ReactJSX,
      target: ts.ScriptTarget.ES2022,
    },
  })
  .outputText.replace(
    /from "(react(?:\/jsx-runtime)?)"/g,
    (_, name) => `from "${pathToFileURL(require.resolve(name)).href}"`,
  );
const { KSwitch } = await import(
  `data:text/javascript;base64,${Buffer.from(output).toString("base64")}`
);
test("switch exposes visible text and accessible checked state by default", () => {
  const html = renderToStaticMarkup(
    createElement(KSwitch, {
      label: "Anrufe",
      checked: true,
      onCheckedChange: () => {},
    }),
  );
  assert.match(html, /k-switch-field__label">Anrufe<\/span>/);
  assert.match(html, /aria-label="Anrufe"/);
  assert.match(html, /aria-checked="true"/);
});
test("surrounding labeled rows can suppress visible text without losing accessibility", () => {
  const html = renderToStaticMarkup(
    createElement(KSwitch, {
      label: "Anrufe",
      checked: false,
      disabled: true,
      showLabel: false,
      onCheckedChange: () => {},
    }),
  );
  assert.doesNotMatch(html, /k-switch-field/);
  assert.match(html, /aria-label="Anrufe"/);
  assert.match(html, /disabled/);
});
