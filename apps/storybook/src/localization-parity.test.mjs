import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { readFile, readdir } from "node:fs/promises";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
const button = (p, name) => p.getByRole("button", { name, exact: true });
try {
  for (const name of (
    await readdir(new URL("../../../locales/", import.meta.url))
  ).filter((n) => n.endsWith(".json"))) {
    const code = name.slice(0, -5),
      pack = JSON.parse(
        await readFile(
          new URL(`../../../locales/${name}`, import.meta.url),
          "utf8",
        ),
      );
    for (const width of [375, 700, 1024]) {
      const wc =
        width === 375 ? "compact" : width === 700 ? "medium" : "expanded";
      const vp =
        width === 375
          ? "Compact · 375"
          : width === 700
            ? "Medium · 700"
            : "Expanded · 1024";
      const options = { viewport: { width, height: 900 } };
      const web = await browser.newPage(options),
        flutter = await browser.newPage(options);
      await web.goto(
        "http://localhost:6006/iframe.html?" +
          new URLSearchParams({
            id: "forms-datetimepicker--states",
            viewMode: "story",
            globals: `language:${code};theme:dark;density:standard;typeScale:compact;inputMode:pointer;windowClass:${wc}`,
          }),
      );
      await web.getByText("Schedule", { exact: true }).waitFor();
      await web.evaluate(() => document.fonts.ready);
      await flutter.goto(
        "http://localhost:6007/#/?" +
          new URLSearchParams({
            path: "forms/datetimepicker/date-time-picker-states",
            preview: "",
            language: `{locale:${code}}`,
            viewport: `{name:${encodeURIComponent(vp)}}`,
            theme: "{name:Orbit%20Dark}",
            "k-design": `{density:standard,type-scale:compact,input-mode:pointer,window-class:${wc}}`,
          }),
      );
      await flutter
        .locator("flt-semantics-placeholder")
        .evaluate((e) => e.click());
      for (const page of [web, flutter]) {
        await button(page, pack.messages.chooseDateTime).first().click();
        await page
          .getByRole("group", { name: pack.messages.hours, exact: true })
          .waitFor();
      }
      for (const label of [
        `${pack.messages.month}: ${pack.months[8]}`,
        `${pack.messages.year}: 2026`,
        pack.messages.cancel,
        pack.messages.apply,
      ]) {
        const a = await button(web, label).boundingBox(),
          b = await button(flutter, label).boundingBox();
        for (const dimension of ["x", "y", "width", "height"])
          assert.ok(
            Math.abs(a[dimension] - b[dimension]) <= 0.5,
            `${code} ${width} ${label} ${dimension}: ${a[dimension]} vs ${b[dimension]}`,
          );
      }
      for (const page of [web, flutter])
        await button(page, pack.messages.apply).click();
      for (const page of [web, flutter])
        await page
          .getByText("Value: 2026-09-16T12:30:00.000Z", { exact: true })
          .first()
          .waitFor();
      console.log(
        `${code} ${width}: language, calendar, geometry and canonical value passed`,
      );
      await web.close();
      await flutter.close();
    }
  }
} finally {
  await browser.close();
}
