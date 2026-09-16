import test from "node:test";
import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import ts from "typescript";
const catalog = {};
for (const name of await readdir(new URL("../locales/", import.meta.url))) {
  if (name.endsWith(".json"))
    catalog[name.slice(0, -5)] = JSON.parse(
      await readFile(new URL(`../locales/${name}`, import.meta.url), "utf8"),
    );
}
const source = await readFile(
  new URL("../packages/web/ui/src/localization/data.ts", import.meta.url),
  "utf8",
);
const javascript = ts.transpileModule(
  source.replace(
    'import { kLocaleCatalog } from "../generated/locales.js";',
    `const kLocaleCatalog = ${JSON.stringify(catalog)};`,
  ),
  {
    compilerOptions: {
      module: ts.ModuleKind.ESNext,
      target: ts.ScriptTarget.ES2022,
    },
  },
).outputText;
const { resolveLocalization, resolveLocale } = await import(
  `data:text/javascript;base64,${Buffer.from(javascript).toString("base64")}`
);
test("all 14 locales cover the same messages, placeholders and calendar", () => {
  assert.equal(Object.keys(catalog).length, 14);
  for (const [tag, pack] of Object.entries(catalog)) {
    assert.deepEqual(
      Object.keys(pack.messages).sort(),
      Object.keys(catalog.en.messages).sort(),
      tag,
    );
    assert.equal(pack.months.length, 12);
    assert.equal(pack.weekdays.length, 7);
    for (const [key, value] of Object.entries(pack.messages)) {
      assert.ok(value.trim(), `${tag}.${key}`);
      assert.equal(
        (value.match(/\{label\}/g) || []).length,
        key === "remove" ? 1 : 0,
      );
    }
  }
});
test("language region fallbacks and unknown language retain a usable catalog", () => {
  assert.equal(resolveLocale("DE_ch").messages.hours, "Stunden");
  assert.equal(resolveLocale("unknown").messages.hours, "Hours");
});
test("text, calendar, format and timezone resolve independently", () => {
  const data = resolveLocalization({
    locale: "fr",
    calendarLocale: "de",
    dateFormat: "iso",
    timeFormat: "h12",
    timeZone: "Asia/Tokyo",
    messages: { apply: "Confirmer" },
  });
  assert.equal(data.messages.hours, "Heures");
  assert.equal(data.messages.apply, "Confirmer");
  assert.equal(data.calendar.months[2], "März");
  assert.equal(data.timeFormat, "h12");
  assert.equal(data.timeZone, "Asia/Tokyo");
  const local = resolveLocalization(
    { locale: "fr", calendarLocale: "de" },
    "es",
  );
  assert.equal(local.messages.hours, "Horas");
  assert.equal(local.calendar.months[0], "enero");
});
test("custom regional packs and partial messages fall back without missing UI strings", () => {
  const custom = {
    ...catalog.en,
    name: "Custom",
    messages: { hours: "Custom hours" },
  };
  const data = resolveLocalization({
    locale: "xx-ZZ",
    locales: { XX: custom },
    messages: { minutes: "Custom minutes" },
  });
  assert.equal(data.messages.hours, "Custom hours");
  assert.equal(data.messages.minutes, "Custom minutes");
  assert.equal(data.messages.cancel, "Cancel");
});
