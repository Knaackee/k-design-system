import assert from "node:assert/strict";
import test from "node:test";

import { checkDart, checkWeb } from "./check-ui-rules.mjs";

const rules = (found) => found.map(([rule]) => rule);

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
