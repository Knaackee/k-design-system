---
title: "Unified density and cross-platform composition"
date: 2026-09-16
---

# Unified density and cross-platform composition

## Objective

Replace the presentation/density split with one shared Dense / Standard /
Spacious contract. Compose existing components through shared layout primitives
so Web and Flutter agree at matched settings and widths, rather than relying on
independently maintained gallery spacing recipes.

Mode: Regular. The user confirmed the density-only direction on 2026-09-16.
Detailed Plan approval and acceptance of Decision 0003 are still pending.

## Scope

One integrated token-and-layout foundation slice, not new product component work.
Approval of this Plan explicitly covers the coupled token, projection, primitive
and fixture changes listed here.

Allowed paths:

- `tokens/semantic.tokens.json` and `tokens/modes/`: remove presentation modes,
  extend density modes with card inset and section spacing, add the semantic
  content/action gap defined in Decision 0003.
- `tooling/generate-tokens.mjs`, `tooling/generate-tokens.test.mjs`: adapt the
  generator contract and regression coverage, without changing build tooling.
- `packages/web/tokens/` and `packages/flutter/k_design_tokens/`: update runtime
  configuration and tests; generated files change only through generation.
- `packages/web/ui/` and `packages/flutter/k_design_ui/`: add and export KStack
  and KInline, retain the preceding Button fix, add package-level tests.
- `apps/storybook/.storybook/`, `apps/storybook/src/`, `apps/widgetbook/lib/` and
  `apps/widgetbook/test/`: remove presentation controls, migrate existing
  internal sibling composition to shared layouts, match Card/Surface frames,
  and add matching deterministic layout fixtures.
- `README.md`, `docs/components/`, this draft Plan, its index and the proposed
  `docs/decisions/0003-unified-density-composition.md`: document the new contract
  and the pre-release migration. Accepted Plan/decision bodies remain unchanged.

No new dependencies, product components, palette/type/opacity changes, baseline
updates, repository initialization, commits or publication are authorized.

## Governing Decisions

- [Proposed Decision 0003](../decisions/0003-unified-density-composition.md)
  specifies numeric roles, primitive behavior, configuration migration and
  fixture geometry. It must be accepted explicitly before implementation.
- [Decision 0001](../decisions/0001-adaptive-foundation.md) remains authoritative
  outside the portions explicitly replaced by Decision 0003.
- [Decision 0002](../decisions/0002-linear-default-and-visual-review-flow.md)
  continues to govern visual review and human acceptance.

## Requirements

1. Only density controls component and composition rhythm; presentation is no
   longer a supported axis. Preserve other axes and native interaction semantics.
2. Use Decision 0003's proposed spacing table and Standard default. Preserve
   Pointer/Touch target protection and accessible text growth.
3. Export equivalent KStack/KInline behavior for consumer composition, with
   token-backed semantic gap roles and no default child stretching. No package
   implementation may depend on galleries.
4. Existing Text and Button components do not acquire external margins. Card
   resolves its inset from density-aware tokens. Migrate repeated sibling-gap
   recipes in existing fixtures; do not redesign unrelated gallery chrome.
5. Match Card/Surface viewport widths, responsive columns, content widths,
   content, configuration and fixture IDs. Preserve natural line-box and visible
   control sizes when neighboring copy wraps.
6. Update all in-repository presentation usages and presets. Document removal
   of the pre-release API without preserving a hidden presentation override.

## Phases

After exact Human Plan Approval and ADR acceptance, the initiating agent owns
one integration phase:

1. Establish failing behavioral coverage for density resolution, runtime
   updates, layout primitives and matching composed geometry.
2. Implement the shared token/projection contract and both primitives together;
   migrate gallery composition and configuration; regenerate outputs.
3. Verify the integrated state, refresh both running galleries, and present the
   matched fixtures for human visual acceptance. No automatic AI review gate.

The current uncommitted fixes and two regression-test files from the Rapid
iteration are retained as inputs, not treated as accepted delivery. Fold their
coverage into the new contract rather than discarding it. Avoid materially
expanding the existing 750-line Widgetbook main file: extract touched fixtures
and configuration into focused modules as part of this integration.

## Risks

- Removing presentation is a pre-release breaking API change, including the
  Marketing preset. Search all in-repository usages and document exact migration.
- Changing widths can change wrapping independently of spacing. Compare actual
  fixture viewport geometry rather than similar-looking screenshots alone.
- Flutter Material density and touch-target padding must not override visual
  token sizes; preserve the preceding regression tests and measure hit targets
  separately from visible bounds.
- Identical token values alone do not prove equivalent layout. Include live
  theme updates, wrapping, empty/single-child cases and consumer compositions.

## Definition of Done

All Requirements hold; regression tests and the repository gate pass. Both
updated galleries stay available for review at matched settings. Show evidence
for the three densities, small/large widths, brand/color combinations and
accessible text scaling. Report omissions and residual rendering differences.

Human visual acceptance is a separate gate. Do not call passing tests acceptance
or commit without additional explicit authorization.

## Verification

Before implementation: inspect current diff and preserve unrelated work. Required
dependency checks: `pnpm install --frozen-lockfile` and `dart pub get`.

During development:

- `pnpm generate`, followed by `pnpm generate:check` and `pnpm test:tooling`.
- `pnpm build:web` and `pnpm typecheck:web`.
- `flutter test` in the affected Flutter token, UI and Widgetbook packages.
- Browser-driven geometry checks against actual rendered Web primitives and
  equivalent Flutter render-object assertions, with the 0.5 logical px tolerance
  in Decision 0003. Exercise live density switching without remounting.
- Matched Card, Surface and layout fixture screenshots at 375 and 1024 logical
  px; Dense/Standard/Spacious, Orbit/Reference and Light/Dark; 100/200 percent
  text scaling and Pointer/Touch coverage. Compare both type scales in tests.
- Consumer-style package composition with externally overridden token values.

Final integrated gate: `pnpm verify`, `git diff --check`, and session diagnostics.
Run Plan/ADR document checks where their format is supported; the existing
`docs/decisions` series is unindexed legacy documentation and is not silently
migrated to another ADR directory. Native Flutter tests and Flutter Web gallery
verification apply; a native-device/emulator screenshot check is unavailable
until a target is identified and must be reported, not claimed.

No package release, visual-baseline update, commit or remote publication is part
of this Plan.
