import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import {
  DARK_MAP_TOKENS,
  createMapStyle,
} from "../../../web/ui/dist/maps/index.js";

const outputUrl = new URL(
  "../test/fixtures/map-style-parity.json",
  import.meta.url,
);
const customSettings = {
  lang: "en",
  roadWidthScale: 1.35,
  casingScale: 0.7,
  labelScale: 1.2,
  haloWidth: 2.1,
  showLanduse: false,
  showBuildings: false,
  buildingMinZoom: 16,
  showRail: false,
  showPaths: false,
  showPois: false,
  poiMinZoom: 17,
  poiMaxRank: 7,
  poiDotScale: 1.6,
  roadLabelMinZoom: 14.5,
  showQuarterLabels: false,
};
const customSources = {
  tiles: "https://example.test/tiles.json",
  glyphs: "https://example.test/fonts/{fontstack}/{range}.pbf",
  attribution: "Example attribution",
};
const customTokens = {
  background: "#010203",
  road: "#ABCDEF",
  tunnelOpacity: 0.72,
  fontRegular: ["Example Regular", "Fallback Regular"],
  fontBold: ["Example Bold"],
  fontItalic: ["Example Italic"],
};

const fixtures = {
  lightDefault: createMapStyle(),
  darkDefault: createMapStyle({ tokens: DARK_MAP_TOKENS }),
  custom: createMapStyle({
    tokens: customTokens,
    settings: customSettings,
    sources: customSources,
  }),
};
const content = `${JSON.stringify(fixtures, null, 2)}\n`;

if (process.argv.includes("--check")) {
  const existing = await readFile(outputUrl, "utf8").catch(() => "");
  if (existing !== content) {
    console.error(
      `Map style parity fixture is stale. Run node ${fileURLToPath(import.meta.url)}`,
    );
    process.exitCode = 1;
  }
} else {
  await writeFile(outputUrl, content);
}
