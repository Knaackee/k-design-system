import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { chromium } from "@playwright/test";
import { createServer } from "vite";
const root = fileURLToPath(new URL("../../../..", import.meta.url));
const server = await createServer({
  configFile: false,
  root,
  server: { host: "127.0.0.1", port: 0 },
  plugins: [
    {
      name: "long-press-test",
      configureServer(s) {
        s.middlewares.use((req, res, next) => {
          if (req.url !== "/") return next();
          res.setHeader("Content-Type", "text/html");
          res.end(
            '<div id="root"></div><script type="module" src="/fixture.js"></script>',
          );
        });
      },
      resolveId(id) {
        if (id === "/fixture.js") return id;
      },
      load(id) {
        if (id !== "/fixture.js") return;
        return `import{createElement as h,useState}from'react';import{createRoot}from'react-dom/client';import{useKLongPressDrag}from'/packages/web/ui/src/util/use-long-press-drag.ts';window.events=[];function App(){const drag=useKLongPressDrag({delay:450,canStart:()=>true,onStart:()=>events.push('start'),onMove:()=>events.push('move'),onEnd:()=>events.push('end'),onCancel:()=>events.push('cancel')});return h('div',{...drag,id:'drag',style:{width:300,height:200,background:'#ddd'}},h('button',{onClick:()=>events.push('click')},'Edit'));}window.root=createRoot(document.getElementById('root'));root.render(h(App));`;
      },
    },
  ],
});
let browser;
try {
  await server.listen();
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.goto(`http://127.0.0.1:${server.httpServer.address().port}`);
  await page.locator("#drag").waitFor();
  const reset = () => page.evaluate(() => (window.events = []));
  const events = () => page.evaluate(() => window.events);
  await page.mouse.move(30, 20);
  await page.mouse.down();
  await page.waitForTimeout(550);
  await page.mouse.move(80, 90);
  await page.mouse.up();
  assert.deepEqual(
    await events(),
    ["start", "move", "end"],
    "hold-drag ends without editor click",
  );
  await page.waitForTimeout(710);
  await reset();
  await page.mouse.move(30, 20);
  await page.mouse.down();
  await page.mouse.move(60, 40);
  await page.waitForTimeout(550);
  await page.mouse.up();
  assert.ok(
    !(await events()).includes("start"),
    "motion before hold preserves scrolling",
  );
  await reset();
  await page.mouse.move(30, 20);
  await page.mouse.down();
  await page.evaluate(() => window.dispatchEvent(new Event("scroll")));
  await page.waitForTimeout(550);
  await page.mouse.up();
  assert.ok(!(await events()).includes("start"), "scroll cancels pending hold");
  await reset();
  await page.mouse.move(30, 20);
  await page.mouse.down();
  await page.mouse.move(500, 300);
  await page.mouse.up();
  await page.waitForTimeout(550);
  assert.ok(
    !(await events()).includes("start"),
    "outside release cancels pending hold",
  );
  for (const cancel of ["escape", "pointercancel", "blur"]) {
    await reset();
    await page.mouse.move(30, 20);
    await page.mouse.down();
    await page.waitForTimeout(550);
    if (cancel === "escape") await page.keyboard.press("Escape");
    else
      await page.evaluate(
        (type) => window.dispatchEvent(new Event(type)),
        cancel,
      );
    await page.mouse.up();
    assert.deepEqual(
      await events(),
      ["start", "cancel"],
      cancel + " cancels active drag",
    );
  }
  await reset();
  await page.mouse.move(30, 20);
  await page.mouse.down();
  await page.waitForTimeout(550);
  await page.evaluate(() => window.root.unmount());
  await page.mouse.up();
  assert.deepEqual(
    await events(),
    ["start", "cancel"],
    "unmount releases active drag",
  );
  assert.deepEqual(errors, []);
  const mobile = await browser.newPage({
    isMobile: true,
    hasTouch: true,
    viewport: { width: 390, height: 844 },
  });
  await mobile.goto(`http://127.0.0.1:${server.httpServer.address().port}`);
  await mobile.locator("#drag").waitFor();
  const cdp = await mobile.context().newCDPSession(mobile);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: 30, y: 20 }],
  });
  await mobile.waitForTimeout(550);
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [{ x: 70, y: 70 }],
  });
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  const touchEvents = await mobile.evaluate(() => window.events);
  assert.ok(
    touchEvents.includes("start") &&
      touchEvents.includes("move") &&
      touchEvents.includes("end"),
    "native touch hold drags without pointer cancellation",
  );
  assert.ok(!touchEvents.includes("click"));
  console.log(
    "PASS: hold/reorder lifecycle, click suppression, scroll/motion/outside-release cancellation, Escape/pointercancel/blur and unmount cleanup.",
  );
} finally {
  await browser?.close();
  await server.close();
}
