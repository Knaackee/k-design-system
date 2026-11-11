import assert from "node:assert/strict";
import test from "node:test";
import { execFileSync } from "node:child_process";
import { cpSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { checkDart, checkWeb } from "./check-ui-rules.mjs";

const rules = (found) => found.map(([rule]) => rule);

test("CLI resolves default paths and library rules across platforms", () => {
  const root = mkdtempSync(join(tmpdir(), "k ui rules "));
  try {
    for (const path of [
      "tooling",
      "packages/flutter/k_design_ui/lib",
      "packages/web/ui/src/stories",
      "apps/widgetbook/lib",
      "apps/storybook/src",
      "examples",
    ])
      mkdirSync(join(root, path), { recursive: true });
    cpSync(
      new URL("./check-ui-rules.mjs", import.meta.url),
      join(root, "tooling/check-ui-rules.mjs"),
    );
    const fixture = join(root, "packages/flutter/k_design_ui/lib/fixture.dart");
    writeFileSync(fixture, "EdgeInsets.all(gap)");
    writeFileSync(
      join(root, "packages/web/ui/src/stories/ignored.tsx"),
      "<KIcon size={18} />",
    );
    const run = () =>
      execFileSync(
        process.execPath,
        [join(root, "tooling/check-ui-rules.mjs"), "--json"],
        { cwd: root, encoding: "utf8" },
      );
    assert.deepEqual(JSON.parse(run()), []);
    writeFileSync(fixture, "EdgeInsets.all(8)");
    assert.throws(run, (error) => {
      assert.equal(error.status, 1);
      const findings = JSON.parse(error.stdout);
      assert.equal(findings.length, 1);
      assert.equal(findings[0].rule, "raw-spacing");
      return true;
    });
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("flags nested Flutter cards", () => {
  assert.deepEqual(rules(checkDart("KCard(child: KCard(child: x))")), [
    "nested-card",
  ]);
});

test("flags a centred leading icon beside a text column", () => {
  const row = `Row(children: [KIcon(KIconName.user), Expanded(child: Column(children: []))])`;
  assert.deepEqual(rules(checkDart(row)), ["centered-leading"]);
  const fixed = `Row(crossAxisAlignment: CrossAxisAlignment.start, children: [KLeading(child: KIcon(KIconName.user)), Expanded(child: Column(children: []))])`;
  assert.deepEqual(rules(checkDart(fixed)), []);
});

test("allows media tiles to centre beside text", () => {
  const row = `Row(children: [Container(child: KIcon(KIconName.file)), Expanded(child: Column(children: []))])`;
  assert.deepEqual(rules(checkDart(row)), []);
});

test("flags icon sizes, literal insets and tiny type", () => {
  assert.deepEqual(rules(checkDart("KIcon(KIconName.x, size: 18)")), [
    "icon-size",
  ]);
  assert.deepEqual(rules(checkDart("EdgeInsets.fromLTRB(8, 8, 8, 4)")), [
    "raw-spacing",
  ]);
  assert.deepEqual(rules(checkDart("EdgeInsets.all(gap * 2)")), []);
  assert.deepEqual(rules(checkDart("TextStyle(fontSize: 9)")), ["tiny-type"]);
});

test("flags nested React cards and odd icon sizes", () => {
  assert.deepEqual(rules(checkWeb("<KCard><KCard>x</KCard></KCard>", ".tsx")), [
    "nested-card",
  ]);
  assert.deepEqual(rules(checkWeb("<KCard /><KCard>x</KCard>", ".tsx")), []);
  assert.deepEqual(rules(checkWeb('<KIcon name="x" size={18} />', ".tsx")), [
    "icon-size",
  ]);
});

test("consumer apps get the motion rule, galleries do not", () => {
  const css = ".a { transition: opacity 200ms ease; }";
  assert.deepEqual(
    rules(checkWeb(css, ".css", { library: false, motion: true })),
    ["raw-motion"],
  );
  assert.deepEqual(rules(checkWeb(css, ".css", { library: false })), []);
  assert.deepEqual(
    rules(
      checkDart("AnimatedOpacity(curve: Curves.easeOut)", {
        library: false,
        motion: true,
      }),
    ),
    ["raw-motion"],
  );
});

test("flags literal motion in library code, not motion roles", () => {
  assert.deepEqual(
    rules(checkWeb(".a { transition: opacity 200ms ease; }", ".css")),
    ["raw-motion"],
  );
  assert.deepEqual(
    rules(
      checkWeb(
        ".a { transition: opacity var(--k-motion-feedback-settle) var(--k-motion-feedback-easing); }",
        ".css",
      ),
    ),
    [],
  );
  assert.deepEqual(
    rules(
      checkWeb(".a { transition: opacity 200ms ease; }", ".css", {
        library: false,
      }),
    ),
    [],
  );
  assert.deepEqual(rules(checkDart("AnimatedOpacity(curve: Curves.easeOut)")), [
    "raw-motion",
  ]);
  assert.deepEqual(
    rules(
      checkDart("AnimatedOpacity(duration: const Duration(milliseconds: 200))"),
    ),
    ["raw-motion"],
  );
  assert.deepEqual(
    rules(
      checkDart("AnimatedOpacity(duration: spec.settle, curve: spec.curve)"),
    ),
    [],
  );
});
