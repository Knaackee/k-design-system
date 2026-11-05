// Temporary: prints what Chromium renders for the parity labels.
import { createRequire } from "node:module";
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";
const root = resolve(new URL("..", import.meta.url).pathname);
const dir = join(root, "apps/storybook/storybook-static");
const types = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".json": "application/json", ".woff2": "font/woff2", ".svg": "image/svg+xml", ".ttf": "font/ttf" };
const server = createServer(async (req, res) => {
  let p = normalize(join(dir, decodeURIComponent(req.url.split("?")[0])));
  if (p.endsWith("/")) p += "index.html";
  try { const b = await readFile(p); res.writeHead(200, { "content-type": types[extname(p)] ?? "application/octet-stream" }); res.end(b); }
  catch { res.writeHead(404); res.end(); }
}).listen(0);
const port = server.address().port;
const { chromium } = createRequire(import.meta.url)("playwright");
const browser = await chromium.launch();
console.log("browser", browser.version());
const page = await browser.newPage({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 });
await page.goto(`http://localhost:${port}/iframe.html?id=review-geometryparity--reference&viewMode=story`, { waitUntil: "load" });
await page.waitForSelector("[data-parity]");
const out = await page.evaluate(async () => {
  await Promise.all(["400 16px Inter", "500 16px Inter", "600 16px Inter"].map((f) => document.fonts.load(f)));
  await document.fonts.ready;
  const c = document.createElement("canvas").getContext("2d");
  const rows = [...document.querySelectorAll("[data-parity]")].map((e) => {
    const t = e.firstElementChild ?? e;
    const textEl = [...t.querySelectorAll("*")].find((n) => n.childNodes.length && [...n.childNodes].some((x) => x.nodeType === 3 && x.textContent.trim())) ?? t;
    const s = getComputedStyle(textEl);
    c.font = `${s.fontWeight} ${s.fontSize} ${s.fontFamily}`;
    const range = document.createRange(); range.selectNodeContents(textEl);
    return { id: e.dataset.parity, w: t.getBoundingClientRect().width, text: textEl.textContent.trim().slice(0, 30), font: c.font, ls: s.letterSpacing, fvs: s.fontVariationSettings, ffs: s.fontFeatureSettings, opsz: s.fontOpticalSizing, textW: range.getBoundingClientRect().width, canvasW: c.measureText(textEl.textContent.trim()).width, pad: s.paddingLeft + "/" + getComputedStyle(t).paddingLeft };
  });
  return { faces: [...document.fonts].filter((f) => f.family.includes("Inter")).map((f) => f.family + " " + f.weight + " " + f.status), rows, ua: navigator.userAgent };
});
console.log(JSON.stringify(out, null, 1));
await browser.close(); server.close();
