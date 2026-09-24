import assert from "node:assert/strict";
import test from "node:test";

import { auditSource } from "./audit-visual-literals.mjs";

test("finds raw Web colors, visual declarations and motion", () => {
  const findings = auditSource(
    ".fixture { color: #fff; opacity: .5; padding: 8px; border: 1px solid currentColor; transition: color 150ms ease; }",
    ".css",
  );
  assert.deepEqual(findings.map(({ rule }) => rule).sort(), [
    "appearance",
    "appearance",
    "color",
    "dimension",
    "motion",
  ]);
});

test("finds raw Flutter visual values but ignores zero reset values", () => {
  const findings = auditSource(
    "const Color(0xffffffff); final a = BorderRadius.circular(8); final b = Duration(milliseconds: 150); final c = BorderRadius.circular(0); final d = SizedBox(width: 24); final e = EdgeInsets.all(8);",
    ".dart",
  );
  assert.deepEqual(findings.map(({ rule }) => rule).sort(), [
    "color",
    "dimension",
    "motion",
    "radius",
    "spacing",
  ]);
});

test("accepts token-backed Web and Flutter appearance", () => {
  assert.equal(
    auditSource(".fixture { color: var(--k-color-text-primary); }", ".css")
      .length,
    0,
  );
  assert.equal(
    auditSource("BorderRadius.circular(tokens.radiusControl)", ".dart").length,
    0,
  );
  assert.equal(
    auditSource(
      ".fixture { margin: 0px; padding: var(--space); border: var(--stroke) solid color-mix(in srgb, red 12%, transparent); }",
      ".css",
    ).length,
    0,
  );
});
