# Plan 0001 — Incremental cross-platform bootstrap

> Status: **approved**  
> Approved: 28 August 2026  
> Execution model: small, independently verified slices

## Outcome

Create a token-driven React/Web and Flutter design-system workspace, then add
shared primitives and components one at a time with matching Storybook and
Widgetbook fixtures and a joint visual review.

The strategic master plan remains a reference. This operational plan controls
the next implementation step.

## Governing boundaries

- DTCG token data is platform-neutral and externally themeable.
- Web and Flutter are projections of the same design intent.
- Primitives are delivered before product-level components.
- Consumers may compose missing components from tokens and primitives.
- No speculative catalog migration.
- One approved slice and one green Git checkpoint at a time.

## Slice 1 — Repository baseline

**Status:** completed (28 August 2026)  
**Outcome:** A fresh contributor can install, navigate, build and test empty Web
and Flutter package boundaries.  
**Allowed paths:** repository configuration, routing docs, empty packages,
placeholder gallery/example directories and CI.  
**Dependencies:** none.  
**Verification:** `pnpm install`, `dart pub get`, `pnpm verify`.  
**Evidence:** successful local `pnpm verify` and the initial repository-baseline
Git commit.

## Slice 2 — Minimal token pipeline

**Status:** completed (28 August 2026)  
**Outcome:** Foundation and semantic token sources generate typed Web and Flutter
outputs for Orbit Light/Dark and a visibly different Reference theme.  
**Dependencies:** Slice 1 accepted.  
**Verification:** deterministic generation, drift check and package tests.  
**Evidence:** unchanged component marker renders with both themes.

## Slice 3 — Storybook and Widgetbook

**Status:** completed (28 August 2026)  
**Outcome:** Both galleries start independently and display matching token-driven
fixtures.  
**Dependencies:** Slice 2 accepted.  
**Verification:** static Storybook build, Flutter analyze/test and Widgetbook
startup smoke check.  
**Evidence:** matching Light/Dark screenshots from browser and emulator.

## Slice 4 — Primitives

**Status:** pending  
**Order:** Text → Icon → Surface → Stack → Inline → Divider.  
**Outcome:** Consumers can compose their own components without raw design
values.  
**Dependencies:** Slice 3 accepted.  
**Verification per primitive:** Web/Flutter tests, matching gallery fixture IDs,
Light/Dark, Reference theme and visual review.  
**Evidence:** accepted side-by-side screenshots and one green commit per
primitive.

## Slice 5 — Components one at a time

**Status:** pending  
**Candidate order:** Button → IconButton → Input → Field → Checkbox → Dialog.  
The next component is selected jointly after the previous visual acceptance.

## Definition of done per primitive or component

- Web and Flutter implementation exists, or a platform exception is documented.
- Only approved tokens and primitives are used.
- Storybook and Widgetbook use matching deterministic fixture IDs.
- Light, Dark, Orbit and Reference are covered.
- Relevant interaction and accessibility behavior is tested.
- Browser and emulator screenshots were compared.
- Visual review is accepted or an explicit deviation is recorded.
- Repository verification is green.
- Work ends in a bounded Git commit.

## Collision boundary

Only one infrastructure or token slice may run at a time. Component work may run
in parallel later only when it does not change shared tokens, primitives or the
same fixture IDs.

## Next handoff

Complete and review Slice 1. Do not start the token pipeline without a new
explicit instruction.
