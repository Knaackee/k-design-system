import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";
import { chromium } from "@playwright/test";

const require = createRequire(
  new URL("../../../../apps/storybook/package.json", import.meta.url),
);
const { createServer } = await import(pathToFileURL(require.resolve("vite")));
const fixture = "/map-routes-idle-fixture.js";
const server = await createServer({
  configFile: false,
  root: fileURLToPath(new URL("../../../..", import.meta.url)),
  esbuild: { jsx: "automatic" },
  server: { host: "127.0.0.1", port: 0 },
  plugins: [
    {
      name: "map-routes-idle-regression",
      configureServer(server) {
        server.middlewares.use((request, response, next) => {
          if (request.url !== "/") return next();
          response.setHeader("Content-Type", "text/html");
          response.end(
            `<div id="root"></div><script type="module" src="${fixture}"></script>`,
          );
        });
      },
      resolveId(id) {
        if (id === fixture) return id;
      },
      load(id) {
        if (id !== fixture) return;
        return `
        import { createElement as h, useState } from 'react';
        import { createRoot } from 'react-dom/client';
        import { MapOverlays } from '/packages/web/ui/src/maps/map-overlays.tsx';
        const listeners = new Map(), layers = new Map(), sources = new Map();
        window.routeDraws = 0;
        window.styleReady = true;
        const map = {
          on(type, ...args) { const callback = args.at(-1); const values = listeners.get(type) ?? []; values.push({ callback }); listeners.set(type, values); return map; },
          once(type, callback) { const values = listeners.get(type) ?? []; values.push({ callback, once: true }); listeners.set(type, values); return map; },
          off(type, ...args) { listeners.set(type, (listeners.get(type) ?? []).filter(value => value.callback !== args.at(-1))); return map; },
          isStyleLoaded: () => window.styleReady,
          getContainer: () => document.getElementById('root'),
          getLayer: id => layers.get(id), getSource: id => sources.get(id),
          addSource: (id, value) => sources.set(id, { ...value, setData() {} }),
          addLayer: value => { layers.set(value.id, value); if (value.id.includes('-route-')) window.routeDraws++; },
          removeLayer: id => layers.delete(id), removeSource: id => sources.delete(id), setPaintProperty() {},
        };
        window.emitIdle = () => {
          for (const value of [...(listeners.get('idle') ?? [])]) {
            if (value.once) map.off('idle', value.callback);
            value.callback();
          }
        };
        window.routeLayers = () => [...layers.keys()].filter(id => id.includes('-route-')).length;
        function Fixture() {
          const [revision, setRevision] = useState(0);
          window.rerenderRoutes = () => setRevision(value => value + 1);
          return h('div', { 'data-revision': revision }, h(MapOverlays, { map, routes: [{ id: 'route', coordinates: [[13,52],[14,53]] }] }));
        }
        const root = createRoot(document.getElementById('root'));
        window.unmountRoutes = () => root.unmount();
        root.render(h(Fixture));
      `;
      },
    },
  ],
});
let browser;
try {
  await server.listen();
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(`http://127.0.0.1:${server.httpServer.address().port}`);
  await page.waitForFunction(() => window.routeLayers?.() === 1);
  await page.evaluate(() => {
    window.styleReady = false;
    window.rerenderRoutes();
  });
  await page.waitForFunction(() => window.routeLayers() === 0);
  await page.evaluate(() => {
    window.styleReady = true;
    window.emitIdle();
  });
  assert.equal(
    await page.evaluate(() => window.routeLayers()),
    1,
    "route redraws on idle without another style.load",
  );
  const draws = await page.evaluate(() => window.routeDraws);
  await page.evaluate(() => window.emitIdle());
  assert.equal(
    await page.evaluate(() => window.routeDraws),
    draws,
    "idle redraw is one-shot",
  );
  await page.evaluate(() => {
    window.styleReady = false;
    window.rerenderRoutes();
  });
  await page.waitForFunction(() => window.routeLayers() === 0);
  await page.evaluate(() => {
    window.unmountRoutes();
    window.styleReady = true;
    window.emitIdle();
  });
  assert.equal(
    await page.evaluate(() => window.routeLayers()),
    0,
    "cleanup cancels pending redraw",
  );
  console.log(
    "Route redraw after transient style readiness, one-shot idle and cleanup passed.",
  );
} finally {
  await browser?.close();
  await server.close();
}
