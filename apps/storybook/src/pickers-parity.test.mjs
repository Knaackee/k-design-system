import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir, writeFile } from "node:fs/promises";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const output = process.env.KDS_PARITY_OUTPUT;
assert.ok(output);
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ channel: "msedge", headless: true });
const web = await browser.newPage(),
  flutter = await browser.newPage();
const group = (o) =>
  "{" +
  Object.entries(o)
    .map(([k, v]) => encodeURIComponent(k) + ":" + encodeURIComponent(v))
    .join(",") +
  "}";
const results = [];
const mobile = process.env.KDS_PARITY_MOBILE === "1";
const h12 = process.env.KDS_PARITY_H12 === "1";
const manual = process.env.KDS_PARITY_MANUAL === "1";
const timeFormat = h12 ? "h12" : "h24";
const locale = mobile ? "de" : "en",
  inputMode = mobile ? "touch" : "pointer";
try {
  for (const kind of ["date", "time", "date-time"])
    for (const width of mobile
      ? [375]
      : process.env.KDS_PARITY_QUICK
        ? [1024]
        : [375, 700, 1024])
      for (const density of mobile
        ? ["dense", "standard", "spacious"]
        : process.env.KDS_PARITY_QUICK
          ? ["dense"]
          : ["dense", "standard", "spacious"])
        for (const scale of mobile
          ? [2]
          : process.env.KDS_PARITY_QUICK
            ? [1]
            : [1, 2]) {
          const height = width === 375 ? 812 : 900,
            wc =
              width === 375 ? "compact" : width === 700 ? "medium" : "expanded";
          await web.setViewportSize({ width, height });
          await flutter.setViewportSize({ width, height });
          const id = kind.replaceAll("-", "") + "picker";
          await web.goto(
            "http://localhost:6006/iframe.html?" +
              new URLSearchParams({
                id: `forms-${id}--states`,
                viewMode: "story",
                args: `locale:${locale};timeFormat:${timeFormat};allowTextInput:${manual}`,
                globals: `theme:dark;density:${density};textScale:${scale};inputMode:${inputMode};windowClass:${wc};typeScale:compact`,
              }),
          );
          await web.getByText("Schedule", { exact: true }).waitFor();
          await web.evaluate(() => document.fonts.ready);
          await flutter.goto(
            "http://localhost:6007/#/?" +
              new URLSearchParams({
                path: `forms/${id}/${kind}-picker-states`,
                preview: "",
                knobs: group({ locale, timeFormat, allowTextInput: manual }),
                viewport: group({
                  name:
                    width === 375
                      ? "Compact · 375"
                      : width === 700
                        ? "Medium · 700"
                        : "Expanded · 1024",
                }),
                theme: group({ name: "Orbit Dark" }),
                "k-design": group({
                  density,
                  "type-scale": "compact",
                  "input-mode": inputMode,
                  "window-class": wc,
                }),
                "text-scale": group({ factor: scale }),
              }),
          );
          await flutter.reload();
          await flutter
            .locator("flt-semantics-placeholder")
            .evaluate((e) => e.click());
          const title = mobile
            ? kind === "date"
              ? "Datum wählen"
              : kind === "time"
                ? "Uhrzeit wählen"
                : "Datum und Uhrzeit wählen"
            : kind === "date"
              ? "Choose date"
              : kind === "time"
                ? "Choose time"
                : "Choose date and time";
          await flutter
            .getByRole("button", { name: title, exact: true })
            .first()
            .waitFor();
          const measurements = [];
          const measure = async (label, a, b) =>
            measurements.push({
              label,
              web: await a.boundingBox(),
              flutter: await b.boundingBox(),
            });
          const fieldLabel =
            kind === "date"
              ? "Date"
              : kind === "time"
                ? "Time"
                : "Date and time";
          measurements.push({
            label: "input",
            web: await web
              .getByRole("textbox", { name: fieldLabel, exact: true })
              .locator("xpath=..")
              .boundingBox(),
            flutter: await flutter
              .getByRole("textbox", { name: fieldLabel, exact: true })
              .evaluate((e) => {
                const r = e
                  .closest("[id^=flt-semantic-node-]")
                  .getBoundingClientRect();
                return { x: r.x, y: r.y, width: r.width, height: r.height };
              }),
          });
          await measure(
            "trigger",
            web
              .getByRole("button", { name: title, exact: true })
              .first()
              .locator("xpath=.."),
            flutter.getByRole("button", { name: title, exact: true }).first(),
          );
          await web
            .getByRole("button", { name: title, exact: true })
            .first()
            .click();
          await flutter
            .getByRole("button", { name: title, exact: true })
            .first()
            .click();
          await flutter
            .getByRole("button", {
              name: mobile ? "Übernehmen" : "Apply",
              exact: true,
            })
            .waitFor();
          if (kind !== "time")
            await measure(
              "selected day",
              web
                .getByRole("dialog")
                .getByRole("button", { name: /16\.09\.2026/, exact: true }),
              flutter.getByRole("button", { name: "16.09.2026", exact: true }),
            );
          if (kind !== "time") {
            for (const label of [
              mobile ? "Monat: September" : "Month: September",
              mobile ? "Jahr: 2026" : "Year: 2026",
            ]) {
              await measure(
                label,
                web
                  .getByRole("dialog")
                  .getByRole("button", { name: label, exact: true })
                  .locator("xpath=.."),
                flutter.getByRole("button", { name: label, exact: true }),
              );
            }
          }
          if (kind !== "date") {
            for (const [label, value] of [
              [mobile ? "Stunden" : "Hours", h12 ? "02" : "14"],
              [mobile ? "Minuten" : "Minutes", "30"],
              ...(h12 ? [[mobile ? "Tagesh\u00e4lfte" : "Period", "PM"]] : []),
            ]) {
              await measure(
                `selected ${label}`,
                web
                  .getByRole("dialog")
                  .getByRole("group", { name: label, exact: true })
                  .getByRole("button", { name: value, exact: true }),
                flutter
                  .getByRole("group", { name: label, exact: true })
                  .getByRole("button", { name: value, exact: true }),
              );
            }
          }
          const name = `${kind}-${width}-${density}-${scale}${h12 ? "-h12" : ""}${manual ? "-manual" : ""}`;
          const applyName = mobile ? "\u00dcbernehmen" : "Apply";
          const webApply = web
            .getByRole("dialog")
            .getByRole("button", { name: applyName, exact: true })
            .locator("xpath=..");
          const flutterApply = flutter.getByRole("button", {
            name: applyName,
            exact: true,
          });
          const webFooter = await webApply.boundingBox();
          const flutterFooter = await flutterApply.boundingBox();
          if (
            webFooter.y + webFooter.height > height - 8 ||
            flutterFooter.height < webFooter.height - 0.5
          ) {
            await web.screenshot({ path: `${output}/${name}-initial-web.png` });
            await flutter.screenshot({
              path: `${output}/${name}-initial-flutter.png`,
            });
            // Scroll the outer panel, not the independently scrolling time columns.
            const anchor =
              kind !== "time"
                ? mobile
                  ? "Monat: September"
                  : "Month: September"
                : title;
            for (const platform of [web, flutter]) {
              const target =
                kind !== "time"
                  ? platform.getByRole("button", { name: anchor, exact: true })
                  : platform.getByText(anchor, { exact: true }).last();
              const bounds = await target.boundingBox();
              await platform.mouse.move(
                bounds.x + bounds.width / 2,
                bounds.y + bounds.height / 2,
              );
              await platform.mouse.wheel(0, 1000);
              await platform.waitForFunction(
                (label) =>
                  new Promise((resolve) => {
                    let previous,
                      stable = 0;
                    const tick = () => {
                      const node = [
                        ...document.querySelectorAll('button,[role="button"]'),
                      ].find(
                        (e) =>
                          (
                            e.getAttribute("aria-label") || e.textContent
                          ).trim() === label,
                      );
                      const y = node?.getBoundingClientRect().y;
                      stable = y === previous ? stable + 1 : 0;
                      previous = y;
                      if (stable >= 8) resolve(true);
                      else requestAnimationFrame(tick);
                    };
                    requestAnimationFrame(tick);
                  }),
                applyName,
              );
            }
          }
          for (const label of mobile
            ? ["Leeren", "Abbrechen", "Übernehmen"]
            : ["Clear", "Cancel", "Apply"])
            await measure(
              label,
              web
                .getByRole("dialog")
                .getByRole("button", { name: label, exact: true })
                .locator("xpath=.."),
              flutter.getByRole("button", { name: label, exact: true }),
            );

          await web.screenshot({ path: `${output}/${name}-web.png` });
          await flutter.screenshot({ path: `${output}/${name}-flutter.png` });
          results.push({ name, measurements });
          await writeFile(
            `${output}/results.json`,
            JSON.stringify(results, null, 2),
          );
          console.log(name, JSON.stringify(measurements));
        }
  const differences = results.flatMap((r) =>
    r.measurements.flatMap((m) =>
      ["x", "y", "width", "height"]
        .filter((k) => Math.abs(m.web[k] - m.flutter[k]) > 0.5)
        .map((k) => ({
          name: r.name,
          label: m.label,
          key: k,
          web: m.web[k],
          flutter: m.flutter[k],
        })),
    ),
  );
  await writeFile(
    `${output}/differences.json`,
    JSON.stringify(differences, null, 2),
  );
  assert.deepEqual(differences, []);
  console.log(`${results.length} picker configurations passed`);
} finally {
  await browser.close();
}
