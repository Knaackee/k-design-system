import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { fileURLToPath, pathToFileURL } from "node:url";
import { chromium } from "@playwright/test";

const require = createRequire(
  new URL("../../../../apps/storybook/package.json", import.meta.url),
);
const { createServer } = await import(pathToFileURL(require.resolve("vite")));
const root = fileURLToPath(new URL("../../../..", import.meta.url));
const fixture = "/calendar-readonly-fixture.js";
const server = await createServer({
  configFile: false,
  root,
  esbuild: { jsx: "automatic" },
  server: { host: "127.0.0.1", port: 0 },
  plugins: [
    {
      name: "calendar-readonly-regression",
      configureServer(server) {
        server.middlewares.use((request, response, next) => {
          if (request.url?.split("?")[0] !== "/") return next();
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
        import { KCalendar } from '/packages/web/ui/src/patterns/calendar.tsx';
        import '/packages/web/ui/src/styles.css';
        import '/packages/web/tokens/src/generated/tokens.css';
        const event = { id: 'visit', start: new Date('2026-10-22T10:00:00Z'), end: new Date('2026-10-22T11:00:00Z') };
        function Fixture() {
          const [opens, setOpens] = useState(0);
          const [moves, setMoves] = useState(0);
          const query = new URLSearchParams(location.search);
          const editable = query.has('editable');
          const month = query.get('month');
          const [selectedDay, setSelectedDay] = useState('2026-10-22');
          const [dayEvents, setDayEvents] = useState([event]);
          return h('div', null,
            h('output', { id: 'opens' }, opens), h('output', { id: 'moves' }, moves),
            h('output', { id: 'day-agenda' }, dayEvents.map(value => value.id).join(',') || 'Empty'),
            h(KCalendar, {
              date: new Date('2026-10-22T12:00:00Z'), view: month ? 'month' : 'day', events: [event],
              ...(month ? {
                monthEventDisplay: month,
                selectedMonthDay: selectedDay,
                onMonthDayOpen: (date, events) => {
                  setSelectedDay(date);
                  setDayEvents(events);
                },
              } : {}),
              getEventId: value => value.id, getEventStart: value => value.start, getEventEnd: value => value.end,
              renderEvent: () => new URLSearchParams(location.search).has('nested') ? h('button', { type: 'button' }, 'Nested action') : 'Visit',
              onEventOpen: () => setOpens(value => value + 1),
              ...(editable ? { onEventMove: () => setMoves(value => value + 1) } : {}),
              timeZone: 'UTC', locale: 'en', startHour: 8, endHour: 13,
            }),
          );
        }
        createRoot(document.getElementById('root')).render(h(Fixture));
      `;
      },
    },
  ],
});
let browser;
try {
  await server.listen();
  const address = server.httpServer.address();
  const origin = `http://127.0.0.1:${address.port}`;
  browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto(origin);
  const event = page.getByRole("button", { name: "Visit", exact: true });
  await event.click();
  await page.waitForFunction(
    () => document.querySelector("#opens")?.textContent === "1",
  );
  await event.focus();
  await page.keyboard.press("Enter");
  await page.waitForFunction(
    () => document.querySelector("#opens")?.textContent === "2",
  );
  await page.keyboard.press("Space");
  await page.waitForFunction(
    () => document.querySelector("#opens")?.textContent === "3",
  );
  assert.equal(await page.locator("#moves").textContent(), "0");

  await page.goto(`${origin}/?nested=1`);
  await page
    .getByRole("button", { name: "Nested action", exact: true })
    .last()
    .click();
  assert.equal(
    await page.locator("#opens").textContent(),
    "0",
    "nested actions must not open the event",
  );

  await page.goto(`${origin}/?editable=1`);
  await event.click();
  await page.waitForFunction(
    () => document.querySelector("#opens")?.textContent === "1",
  );
  assert.equal(
    await page.locator("#moves").textContent(),
    "0",
    "a click must not move an editable event",
  );
  const box = await event.boundingBox();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2 + 56, {
    steps: 8,
  });
  await page.mouse.up();
  await page.waitForFunction(
    () => document.querySelector("#moves")?.textContent === "1",
  );
  assert.equal(
    await page.locator("#opens").textContent(),
    "1",
    "dragging must not also open details",
  );

  const mobile = await browser.newContext({
    viewport: { width: 390, height: 844 },
    hasTouch: true,
    isMobile: true,
  });
  const phone = await mobile.newPage();
  await phone.goto(origin);
  await phone.getByRole("button", { name: "Visit", exact: true }).tap();
  await phone.waitForFunction(
    () => document.querySelector("#opens")?.textContent === "1",
  );
  assert.equal(await phone.locator("#moves").textContent(), "0");
  for (const [surface, display, touch] of [
    [page, "appointments", false],
    [phone, "indicators", true],
  ]) {
    await surface.goto(`${origin}/?month=${display}`);
    const booked = surface.locator('[data-month-day="2026-10-22"]');
    const empty = surface.locator('[data-month-day="2026-10-23"]');
    assert.equal(await booked.getAttribute("aria-pressed"), "true");
    if (touch) {
      await empty.tap();
    } else {
      await empty.focus();
      await surface.keyboard.press("Enter");
    }
    assert.equal(await empty.getAttribute("aria-pressed"), "true");
    assert.equal(await booked.getAttribute("aria-pressed"), "false");
    assert.equal(await surface.locator("#day-agenda").textContent(), "Empty");
    await booked.click();
    assert.equal(await surface.locator("#opens").textContent(), "0");
    assert.equal(await booked.getAttribute("aria-pressed"), "true");
    assert.equal(await surface.locator("#day-agenda").textContent(), "visit");
  }
  assert.deepEqual(errors, []);
  console.log(
    "Calendar read-only click, keyboard, touch and editable drag regression passed.",
  );
} finally {
  await browser?.close();
  await server.close();
}
