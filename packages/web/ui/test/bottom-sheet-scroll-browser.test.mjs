import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { chromium } from "@playwright/test";
import { createServer } from "vite";
const root = fileURLToPath(new URL("../../../..", import.meta.url));
const fixture = "/sheet-fixture.js";
const server = await createServer({
  configFile: false,
  root,
  esbuild: { jsx: "automatic" },
  server: { host: "127.0.0.1", port: 0 },
  plugins: [
    {
      name: "sheet-regression",
      configureServer(s) {
        s.middlewares.use((req, res, next) => {
          if (req.url !== "/") return next();
          res.setHeader("Content-Type", "text/html");
          res.end(
            `<meta name="viewport" content="width=device-width, initial-scale=1"><div id="root"></div><script type="module" src="${fixture}"></script>`,
          );
        });
      },
      resolveId(id) {
        if (id === fixture) return id;
      },
      load(id) {
        if (id !== fixture) return;
        return `import {createElement as h,useState} from 'react';import{createRoot}from'react-dom/client';import{KDialog}from'/packages/web/ui/src/overlays/overlay.tsx';import'/packages/web/ui/src/styles.css';import'/packages/web/tokens/src/generated/tokens.css';function App(){const[open,setOpen]=useState(false);window.openSheet=()=>setOpen(true);return h('div',null,h('output',{id:'state'},String(open)),h(KDialog,{open,onOpenChange:value=>{if(!window.guardClose)setOpen(value)},title:'Settings'},h('div',{style:{height:1400}},'Scrollable content')))}createRoot(document.getElementById('root')).render(h(App));`;
      },
    },
  ],
});
let browser;
try {
  await server.listen();
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 390, height: 844 },
    isMobile: true,
    hasTouch: true,
  });
  await page.goto(`http://127.0.0.1:${server.httpServer.address().port}`);
  await page.waitForFunction(() => typeof window.openSheet === "function");
  await page.evaluate(() => window.openSheet());
  await page.locator(".k-bottom-sheet").waitFor();
  await page.waitForTimeout(500);
  const cdp = await page.context().newCDPSession(page);
  async function swipe(y1, y2, interval = 40) {
    await cdp.send("Input.dispatchTouchEvent", {
      type: "touchStart",
      touchPoints: [{ x: 195, y: y1 }],
    });
    for (let i = 1; i <= 20; i++) {
      await cdp.send("Input.dispatchTouchEvent", {
        type: "touchMove",
        touchPoints: [{ x: 195, y: y1 + ((y2 - y1) * i) / 20 }],
      });
      await page.waitForTimeout(interval);
    }
    await cdp.send("Input.dispatchTouchEvent", {
      type: "touchEnd",
      touchPoints: [],
    });
    await page.waitForTimeout(500);
  }
  const scroller = page.locator(".k-overlay-body");
  async function reopen() {
    await page.evaluate(() => window.openSheet());
    await page.locator(".k-bottom-sheet").waitFor();
    await page.waitForTimeout(500);
  }
  await swipe(350, 410);
  assert.equal(
    await page.locator("#state").textContent(),
    "true",
    "short slow pull returns sheet",
  );
  await swipe(650, 350);
  assert.ok(
    (await scroller.evaluate((e) => e.scrollTop)) > 100,
    "upward swipe scrolls content",
  );
  assert.equal(
    await page.locator("#state").textContent(),
    "true",
    "scrolling does not dismiss",
  );
  await scroller.evaluate((e) => (e.scrollTop = 100));
  await page.waitForTimeout(100);
  await swipe(300, 650);
  assert.equal(
    await page.locator("#state").textContent(),
    "false",
    "same gesture continues into sheet dismissal after reaching top",
  );
  await reopen();
  await swipe(300, 650);
  assert.equal(
    await page.locator("#state").textContent(),
    "false",
    "existing drag from top remains intact",
  );
  await reopen();
  await page.evaluate(() => (window.guardClose = true));
  await scroller.evaluate((e) => (e.scrollTop = 100));
  await page.waitForTimeout(100);
  await swipe(300, 650);
  assert.equal(
    await page.locator("#state").textContent(),
    "true",
    "consumer guard can reject dismissal",
  );
  assert.ok(
    (await page.locator(".k-bottom-sheet").boundingBox()).y < 200,
    "guarded sheet snaps back open",
  );
  console.log(
    "PASS: upward scroll, continuous boundary handoff, top drag, reopen, guarded dismissal",
  );
} finally {
  await browser?.close();
  await server.close();
}
