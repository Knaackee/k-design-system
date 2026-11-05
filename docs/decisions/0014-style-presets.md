# Decision 0014 — Style presets

> Status: proposed (implemented on `feat/style-presets`, pending device acceptance)
> Date: 5 November 2026
> Builds on: [0010](0010-adaptive-resolution-and-phone-type.md), [0011](0011-configurable-motion.md), [0012](0012-apple-navigation.md)
> Sources: Apple Human Interface Guidelines (iOS 26), Material 3 Expressive

## Problem

Components took their spacing, row heights, radii and text roles from one
productivity look. A phone app built with the system looked like a narrow web
app: small type, tight rows, square buttons, a fixed tab bar. Agents then
compensated screen by screen, which is exactly what the system should prevent.

## Decision

1. **Style is an adaptive axis**, like density and motion: `linear` (default,
   productivity) and `apple` (iOS/iPadOS HIG). Web: `data-style`,
   `applyKAdaptive(root, { style })`; Flutter: `KStyle`,
   `KAdaptiveOverrides(style:)`. Both galleries have a style switch.
2. **Presets are token sets**, generated from `tokens/modes/style.*.tokens.json`:
   list row height, row padding, leading gap, group radius, section header
   spacing, page header spacing, button radius. Brand (colours, logo, font)
   stays a separate layer and works with every style.
3. **Text roles follow the style.** `apple` uses the iOS ramp on phones and
   tablets (`KTypeScale.apple`: body 17/22, subheadline 15/20, large title
   34/41), body-size list titles and values and sentence-case section
   headers; `linear` keeps the compact roles.
4. **Behaviour that is not a token** follows the style in the component:
   `apple` sets text in the system font (SF Pro) on Apple devices, uses the
   floating glass tab bar, borderless inset groups and a round back button.
5. **Material Expressive** follows as `material`, and `auto` (Apple devices →
   `apple`, Android → `material`, desktop → `linear`) becomes the default once
   it exists.

## Consequences

- New public API: `KStyle`, `KTypeScale.apple`, `KAdaptiveOverrides.style`,
  Web `KStyle`, `data-style`; tokens `component.list.*`,
  `component.pageHeader.*`, `component.button.radius`,
  `component.sidebar.activeBackground`, `layout.pageWidth`.
- `KList` draws its own grouped surface and takes `title`/`footer`;
  `KListItem.value` is the text value, `trailing` is for badges and dots.
- Visual acceptance happens on review sheets (`tooling/contact-sheet.mjs`,
  `apps/widgetbook/test/tools/review_screenshots_test.dart`) before a merge.
- Open for `apple`: collapsing large title, content under the glass tab bar,
  44 pt toolbar buttons, continuous corners, press feedback.
