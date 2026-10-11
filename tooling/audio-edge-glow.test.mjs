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
  new URL(
    "../packages/web/ui/src/feedback/audio-edge-glow.tsx",
    import.meta.url,
  ),
  "utf8",
);
const output = ts.transpileModule(source, {
  compilerOptions: {
    module: ts.ModuleKind.ESNext,
    jsx: ts.JsxEmit.ReactJSX,
    target: ts.ScriptTarget.ES2022,
  },
}).outputText;
const resolved = output.replace(
  /from "(react(?:\/jsx-runtime)?)"/g,
  (_, name) => `from "${pathToFileURL(require.resolve(name)).href}"`,
);
const { KAudioEdgeGlow } = await import(
  `data:text/javascript;base64,${Buffer.from(resolved).toString("base64")}`
);

test("inactive edge glow renders no decorative surface", () => {
  assert.equal(
    renderToStaticMarkup(createElement(KAudioEdgeGlow, { color: "#84cc16" })),
    "",
  );
});
test("capture and processing expose a pointer-transparent decorative canvas", () => {
  for (const state of ["capturing", "processing"]) {
    const html = renderToStaticMarkup(
      createElement(KAudioEdgeGlow, {
        color: "var(--character-color)",
        state,
        audioLevel: 0.4,
      }),
    );
    assert.match(html, /aria-hidden="true"/);
    assert.match(html, /pointer-events:none/);
    assert.match(html, new RegExp(`data-k-audio-edge-glow="${state}"`));
    assert.match(html, /color:var\(--character-color\)/);
  }
});
