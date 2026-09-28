import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { build } from "esbuild";

const projectDirectory = path.dirname(
  path.dirname(fileURLToPath(import.meta.url)),
);

const result = await build({
  entryPoints: [path.join(projectDirectory, "src/tree-shaking-entry.ts")],
  bundle: true,
  format: "esm",
  metafile: true,
  minify: true,
  platform: "browser",
  write: false,
  external: ["react", "react/jsx-runtime", "react-dom"],
});

const contributions = Object.values(result.metafile.outputs).flatMap((output) =>
  Object.entries(output.inputs).map(([input, details]) => ({
    input: input.replaceAll("\\\\", "/"),
    bytes: details.bytesInOutput,
  })),
);

const contributedBytes = (suffix) =>
  contributions
    .filter(({ input }) => input.endsWith(suffix))
    .reduce((total, { bytes }) => total + bytes, 0);

assert.ok(
  contributedBytes("/primitives/button.js") > 0,
  "The imported KButton implementation must contribute to the consumer bundle.",
);
assert.equal(
  contributedBytes("/patterns/calendar.js"),
  0,
  "KCalendar must be removed when the consumer only imports KButton.",
);
assert.equal(
  contributedBytes("/charts/line-chart.js"),
  0,
  "KLineChart must be removed when the consumer only imports KButton.",
);

const bundledBytes = result.outputFiles.reduce(
  (total, output) => total + output.contents.byteLength,
  0,
);
assert.ok(
  bundledBytes < 10_000,
  `The isolated KButton bundle is unexpectedly large (${bundledBytes} bytes).`,
);

console.log(
  `Tree-shaking verified: KButton retained; Calendar and charts removed (${bundledBytes} bytes).`,
);
