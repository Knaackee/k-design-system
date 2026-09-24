---
title: "Tiered design-token architecture and component migration"
date: 2026-09-24
---

# Tiered design-token architecture and component migration

## Objective

Make the complete shipped Web and Flutter component library externally
themeable from one platform-neutral token source while preserving current
behavior, accessibility and visual defaults. Establish a guard that prevents
new components from reintroducing unreviewed visual literals.

Mode: Regular. The user selected Regular on 24 September 2026 and requested
fast execution before more components are added.

Status: approved on 24 September 2026. The user explicitly approved this Plan
and accepted Decision 0005. Existing visual output must remain unchanged; token
defaults reproduce the accepted UI.

## Scope

This is one coordinated migration delivered in reviewable waves. It changes the
public token API, generator and existing component styling; it does not add new
product components.

Allowed paths:

- `tokens/`: extend foundation and semantic DTCG sources and add component
  roles; preserve themes and modes as orthogonal overrides.
- `tooling/generate-tokens.mjs`, its tests, and one focused style-audit tool:
  preserve aliases, project required DTCG types and enforce the source policy.
- generated Web and Flutter token projections, changed only by generation.
- `packages/web/ui/src/` and `packages/flutter/k_design_ui/lib/src/`: migrate
  shipped primitives, forms, actions, overlays, navigation, data components and
  patterns to the shared contract.
- package tests and matching Storybook/Widgetbook fixtures needed to prove
  consumer overrides and visual parity.
- token/component documentation, this Plan, its index and proposed Decision 0005.

No new runtime dependency, component redesign, behavioral API redesign, visual
baseline update, commit, push or publication is authorized by Plan approval.
Existing oversized Flutter files are split only where the touched code would
otherwise make them materially harder to maintain; extraction must preserve
their public API and behavior.

## Governing decisions

- [Proposed Decision 0005](../decisions/0005-tiered-design-token-contract.md)
  defines the three tiers, live aliases, customization surface and audit policy.
- [Decision 0001](../decisions/0001-adaptive-foundation.md) continues to own
  adaptive axes, input modes and accessible target separation.
- [Decision 0003](../decisions/0003-unified-density-composition.md) continues
  to own density and composition roles.

## Requirements

1. Foundation, semantic and component tokens are authored once in DTCG data and
   project deterministically to typed Web and Flutter APIs.
2. Web custom properties and Flutter `copyWith` preserve semantic-to-component
   alias behavior. Explicit component overrides take precedence.
3. Flutter consumers can install a transformed token set through
   `kDesignTheme`; Web consumers can scope the equivalent custom properties to
   a subtree.
4. All shipped component-package appearance uses tokens for colors, type/icon
   geometry, visible spacing/sizing, radii, borders, focus, elevation, opacity,
   blur/glass and motion. Structural calculations remain ordinary code and are
   documented by narrowly scoped audit exceptions when ambiguous.
5. Current Orbit/Reference, Light/Dark, density, type-scale, input-mode and
   window-class behavior remains intact. Default visual output does not change
   except for corrections explicitly accepted during gallery review.
6. Accessibility semantics, keyboard behavior, focus visibility and minimum
   touch targets remain intact under defaults. Tests demonstrate a square/no-
   radius theme and one component-specific override on both platforms.
7. Repository verification rejects new raw visual literals in package source
   and rejects stale generated projections.

## Migration waves

Each wave is integrated before the next begins so failures remain local. Hot
reload galleries remain available for quick user review; full builds run at
the final gate rather than after every visual edit.

1. **Contract and generator**
   - Add missing scales and semantic roles supported by evidence from current
     source: state/scrim colors, icon and handle sizes, shape/stroke roles,
     opacity, blur/glass, motion duration and easing.
   - Add component token groups only for independently customizable component
     parts found in the audit, beginning with Mobile App Bar.
   - Preserve aliases in Web output and implement dependent Flutter `copyWith`
     behavior plus the theme transform hook.
   - Add generation, alias-cascade and external-override tests.
2. **Foundation components**
   - Migrate primitives, layout, typography, buttons, cards, surfaces,
     separators, badges, avatars, skeleton, progress, slider and switch.
   - Establish audit rules using this smaller, well-understood set before
     enabling them repository-wide.
3. **Interactive components**
   - Migrate forms, actions, menus, pickers, overlays, drawers, app bars,
     sidebars, tabs, toast and navigation components.
   - Validate Hover/Pressed/Focus/Disabled, Pointer/Touch and all densities.
4. **Complex data and patterns**
   - Migrate tables/DataTable, calendar, Kanban and remaining composed patterns.
   - Keep time/grid/drag arithmetic structural; tokenize rendered geometry and
     feedback without changing interaction behavior.
5. **Close the boundary**
   - Enable the hardcode audit for all handwritten component-package source.
   - Document token names, defaults, Web scoping, Flutter transformation and
     accessibility responsibilities.
   - Compare representative Storybook and Widgetbook fixtures and correct only
     parity regressions caused by the migration.

## Verification

During development, use the narrowest affected checks:

- `pnpm generate`, `pnpm generate:check`, and token-generator/tooling tests;
- Web package build and typecheck;
- affected Flutter token/UI tests and `flutter analyze`;
- audit fixtures proving accepted and rejected literals;
- consumer-style tests for global radius removal, scoped color/type changes,
  component-specific overrides and live theme updates;
- matching Storybook/Widgetbook review for each migration wave.

Final integrated program:

```text
pnpm install --frozen-lockfile
dart pub get
pnpm verify
git diff --check
```

The final report lists audit exceptions, changed public token names, generated
outputs, observed gallery parity and any remaining structural literals. Passing
automation does not constitute human visual acceptance.

## Risks and controls

- **Token explosion:** require a consumer-visible reason for every component
  token; reuse semantic roles for shared intent.
- **Broken global cascading:** generator tests cover Web aliases and Flutter
  dependent `copyWith` updates before component migration.
- **Accidental redesign:** preserve default values and compare the galleries;
  visual improvements require explicit user feedback.
- **Over-tokenized algorithms:** classify calendar, drag, virtualization and
  coordinate constants by whether they alter rendered design intent.
- **Large files:** extract touched component implementations where required by
  the repository file-size rule, without unrelated refactoring.

## Definition of done

All Requirements hold; the final verification program passes; all
component-package source is covered by the audit or a documented narrow
exception; Web and Flutter demonstrate equivalent external customization; both
galleries are available for human visual review.

Human acceptance, commit authorization and publication remain separate gates.
