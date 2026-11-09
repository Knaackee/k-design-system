import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { after, before, test } from "node:test";

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const base = process.env.KDS_STORYBOOK_URL || "http://localhost:6006";
let browser;

before(async () => {
  browser = await chromium.launch();
});
after(async () => {
  await browser?.close();
});

async function story(t, id, options) {
  const page = await browser.newPage(options);
  t.after(() => page.close());
  await page.goto(`${base}/iframe.html?id=${id}&viewMode=story`);
  return page;
}

test("mobile link dialog validates, cancels, preserves selection and inserts an undoable link", async (t) => {
  const page = await story(t, "data-display-markdown--editor-integration", {
    viewport: { width: 390, height: 844 },
    hasTouch: true,
    isMobile: true,
  });
  await page.getByRole("button", { name: "Markdown", exact: true }).click();
  const editor = page.locator(".cm-content");
  const sourceStyle = await editor.evaluate(async (node) => {
    await document.fonts.ready;
    const style = getComputedStyle(node);
    const line = getComputedStyle(node.querySelector(".cm-line"));
    return {
      font: style.fontFamily,
      size: parseFloat(style.fontSize),
      lineHeight: parseFloat(style.lineHeight),
      bodySize: parseFloat(style.getPropertyValue("--k-font-body-size")),
      relaxedHeight: parseFloat(
        style.getPropertyValue("--k-font-relaxed-height"),
      ),
      inset: style.getPropertyValue("--k-space-medium-inset").trim(),
      left: style.paddingInlineStart,
      right: style.paddingInlineEnd,
      lineInset: line.paddingInlineStart,
    };
  });
  assert.match(sourceStyle.font, /^KDesignMono\b/);
  assert.equal(sourceStyle.size, sourceStyle.bodySize);
  assert.ok(
    Math.abs(
      sourceStyle.lineHeight - sourceStyle.size * sourceStyle.relaxedHeight,
    ) < 0.1,
  );
  assert.equal(sourceStyle.left, sourceStyle.inset);
  assert.equal(sourceStyle.right, sourceStyle.inset);
  assert.equal(sourceStyle.lineInset, "0px");
  const link = page
    .locator(".k-markdown-editor-dictation")
    .getByRole("button", { name: "Link", exact: true });
  const original = await editor.innerText();
  await editor.focus();
  await page.keyboard.press("Control+Home");
  await page.keyboard.press("Shift+End");
  const selected = await page.evaluate(() => getSelection().toString());
  assert.equal(selected, "# Ein guter Start");

  await link.click();
  await page
    .getByRole("textbox", { name: "Link-Adresse" })
    .fill("javascript:alert(1)");
  await page.getByRole("button", { name: "Einfügen", exact: true }).click();
  await page.getByText("Gib eine gültige Link-Adresse ein.").waitFor();
  await page.getByRole("button", { name: "Abbrechen", exact: true }).click();
  await page.waitForFunction(() =>
    document.activeElement?.classList.contains("cm-content"),
  );
  assert.equal(await editor.innerText(), original);
  assert.equal(await page.evaluate(() => getSelection().toString()), selected);

  await link.click();
  await page
    .getByRole("textbox", { name: "Link-Adresse" })
    .fill("https://example.org/docs(a)");
  await page.getByRole("button", { name: "Einfügen", exact: true }).click();
  await page.waitForFunction(() =>
    document.activeElement?.classList.contains("cm-content"),
  );
  assert.match(
    await editor.innerText(),
    /https:\/\/example.org\/docs\\\(a\\\)/,
  );
  await page.getByRole("button", { name: "Vorschau", exact: true }).click();
  await page.getByRole("link", { name: selected }).click();
  await page
    .getByRole("status")
    .getByText("Link ausgewählt: https://example.org/docs(a)")
    .waitFor();
  await page.getByRole("button", { name: "Markdown", exact: true }).click();
  await editor.focus();
  await page.keyboard.press("Control+z");
  assert.equal(await editor.innerText(), original);
});

test("localized search replaces text and read-only search hides replacement", async (t) => {
  const page = await story(t, "data-display-markdown--editor-integration");
  await page.getByRole("button", { name: "Markdown", exact: true }).click();
  await page.getByRole("button", { name: "Suchen", exact: true }).click();
  await page.getByRole("textbox", { name: "Suchbegriff" }).fill("guter Start");
  await page.getByRole("button", { name: "Show replace" }).click();
  await page.getByRole("textbox", { name: "Ersetzen" }).fill("guter Anfang");
  await page.getByRole("button", { name: "Replace all" }).click();
  assert.match(await page.locator(".cm-content").innerText(), /guter Anfang/);

  await page.goto(
    `${base}/iframe.html?id=forms-editors--markdown-read-only&viewMode=story`,
  );
  await page.getByRole("button", { name: "Search", exact: true }).click();
  await page.getByRole("textbox", { name: "Find" }).fill("Preview");
  assert.equal(
    await page.locator(".cm-content").getAttribute("contenteditable"),
    "false",
  );
  assert.equal(
    await page.getByRole("button", { name: "Show replace" }).count(),
    0,
  );
});

test("offline Web replicas converge and undo affects only the author’s edit", async (t) => {
  const page = await story(t, "forms-editors--collaboration");
  const first = page.locator(".cm-content").first();
  const second = page.locator(".cm-content").last();
  await page.getByRole("button", { name: "Disconnect Alex" }).click();
  await first.focus();
  await page.keyboard.press("Control+Home");
  await page.keyboard.insertText("Dennis offline ");
  await second.focus();
  await page.keyboard.press("Control+End");
  await page.keyboard.insertText(" Alex offline");
  assert.doesNotMatch(await first.innerText(), /Alex offline/);
  assert.doesNotMatch(await second.innerText(), /Dennis offline/);
  await page.getByRole("button", { name: "Reconnect Alex" }).click();
  await page.waitForFunction(() =>
    Array.from(document.querySelectorAll(".cm-content")).every(
      (editor) =>
        editor.innerText.includes("Dennis offline") &&
        editor.innerText.includes("Alex offline"),
    ),
  );
  await first.focus();
  await page.keyboard.press("Control+z");
  await page.waitForFunction(() =>
    Array.from(document.querySelectorAll(".cm-content")).every(
      (editor) =>
        !editor.innerText.includes("Dennis offline") &&
        editor.innerText.includes("Alex offline"),
    ),
  );
});

test("streaming keeps committed DOM and preserves manual scroll while the response grows", async (t) => {
  const page = await story(t, "data-display-markdown--streaming", {
    viewport: { width: 390, height: 275 },
    hasTouch: true,
  });
  const next = page.getByRole("button", { name: "Nächster Schritt" });
  await page.getByRole("heading", { name: "Live-Bericht" }).waitFor();
  await page.evaluate(() => {
    window.initialHeading = document.querySelector(".k-markdown h2");
  });
  for (let step = 0; step < 7; step++) await next.click();

  const log = page.getByRole("log");
  await page.waitForFunction(
    () => document.querySelector("[role=log]").scrollTop > 60,
  );
  assert.ok(
    await log.evaluate(
      (node) => node.scrollHeight - node.clientHeight - node.scrollTop < 2,
    ),
  );
  await log.evaluate((node) => {
    node.scrollTop = 0;
  });
  await page.getByRole("button", { name: "Zu neuesten Nachrichten" }).waitFor();
  await next.click();
  await next.click();
  assert.equal(await log.evaluate((node) => node.scrollTop), 0);
  assert.equal(
    await page.evaluate(
      () => window.initialHeading === document.querySelector(".k-markdown h2"),
    ),
    true,
  );
  assert.equal(await log.getAttribute("aria-busy"), null);
  assert.ok(
    await log.evaluate((node) => {
      const { left, right } = node.getBoundingClientRect();
      const codeBlock = node.querySelector(".k-markdown__code-block");
      const box = codeBlock.getBoundingClientRect();
      return box.left - left === right - box.right;
    }),
  );
  assert.match(
    await log
      .locator("pre code")
      .evaluate((node) => getComputedStyle(node).fontFamily),
    /^KDesignMono\b/,
  );
});
