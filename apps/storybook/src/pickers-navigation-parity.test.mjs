import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
const button = (page, name) => page.getByRole("button", { name, exact: true });
try {
  for (const width of [375, 700, 1024]) {
    const options = { viewport: { width, height: 900 } };
    const web = await browser.newPage(options),
      flutter = await browser.newPage(options);
    const wc =
      width === 375 ? "compact" : width === 700 ? "medium" : "expanded";
    const vp =
      width === 375
        ? "Compact · 375"
        : width === 700
          ? "Medium · 700"
          : "Expanded · 1024";
    await web.goto(
      "http://localhost:6006/iframe.html?" +
        new URLSearchParams({
          id: "forms-datetimepicker--states",
          viewMode: "story",
          args: "allowTextInput:false",
          globals: `theme:dark;density:standard;textScale:1;inputMode:pointer;windowClass:${wc};typeScale:compact`,
        }),
    );
    await web.getByText("Schedule", { exact: true }).waitFor();
    await web.evaluate(() => document.fonts.ready);
    await flutter.goto(
      "http://localhost:6007/#/?" +
        new URLSearchParams({
          path: "forms/datetimepicker/date-time-picker-states",
          preview: "",
          knobs: "{allowTextInput:false}",
          viewport: `{name:${encodeURIComponent(vp)}}`,
          theme: "{name:Orbit%20Dark}",
          "k-design": `{density:standard,type-scale:compact,input-mode:pointer,window-class:${wc}}`,
        }),
    );
    await flutter
      .locator("flt-semantics-placeholder")
      .evaluate((e) => e.click());
    for (const page of [web, flutter])
      await button(page, "Choose date and time").first().click();
    for (const [header, choice] of [
      ["Month: September", "September"],
      ["Year: 2026", "2026"],
    ]) {
      for (const page of [web, flutter]) {
        await button(page, header).click();
        await page
          .getByRole("group", { name: "Hours", exact: true })
          .waitFor({ state: "hidden" });
        assert.equal(
          await page.getByRole("group", { name: "Hours", exact: true }).count(),
          0,
        );
      }
      for (const label of [choice, "Cancel", "Apply"]) {
        const a = await button(web, label).boundingBox(),
          b = await button(flutter, label).boundingBox();
        for (const dimension of ["x", "y", "width", "height"])
          assert.ok(
            Math.abs(a[dimension] - b[dimension]) <= 0.5,
            `${width} ${header} ${label} ${dimension}: ${a[dimension]} vs ${b[dimension]}`,
          );
      }
      for (const page of [web, flutter]) {
        await button(page, choice).click();
        assert.equal(
          await page.getByRole("group", { name: "Hours", exact: true }).count(),
          0,
        );
        await button(page, "16.09.2026").click();
        await page.getByRole("group", { name: "Hours", exact: true }).waitFor();
      }
    }
    console.log(
      `${width}: month/year geometry and day-gated time selection passed`,
    );
    await web.close();
    await flutter.close();
  }
} finally {
  await browser.close();
}
