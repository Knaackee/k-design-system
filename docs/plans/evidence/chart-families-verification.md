# Chart families — implementation evidence

## Authorization and scope

On 2026-09-25 the user approved the proposed next group with “Freigabe erteilt”, after accepting and backing up the reference chart. This follow-up implements Bar/Column (vertical/horizontal, grouped/stacked), Area (single/multiple/stacked), and Donut/Pie. Remaining proposed chart families are not part of this change. The existing adapter and design-token decisions remain in effect; no dependency change is planned.

Implementation is split by platform library and gallery composition. Public models stay renderer-independent. Appearance uses tokens; data, labels, formatters, visibility and selection remain consumer-controlled. The optional data-table action belongs to demo composition and opens existing KDialog/KTable.

## Verification agreed before implementation

- Meaningful model tests for grouping/stacking, missing/nonfinite values, negative values, invalid/zero pie totals, stable selection IDs and immutable consumer data.
- Targeted Flutter interaction/layout tests, Web typecheck/build and style audit.
- Browser checks of matching fixtures, chart selection, legend toggles, dialog table and compact rendering; compare rendered geometry and capture screenshots where useful.
- Full integrated pnpm verify at completion. Report actual evidence and limitations rather than claiming unmeasured pixel identity.
- Native device testing is unavailable through the current Widgetbook checkout because it has no Android host; do not add a platform scaffold within this slice.

## Result

Implemented KBarChart, KAreaChart and KDonutChart on Web and Flutter, with seven matching gallery variants. Data-table actions remain gallery composition using KDialog and KTable.

Targeted checks passed: model and fixture tests, Web type checking/build, eight Flutter chart-family tests (including 27 combinations of width, density and family), seven Flutter gallery tests, and the existing line-chart tests.

Browser inspection covered grouped/horizontal/stacked bars, ordinary/stacked areas, donut and pie at compact width, plus a 700-wide light/Spacious view. Selection, legend hiding/restoration, empty state, keyboard selection and modal table behavior were checked. Screenshots are in artifacts/chart-families. Flutter preview scaling in Widgetbook differs from Storybook at the wider viewport, so screenshots are visual evidence rather than a pixel-difference certification.

The first full verification stopped on a missing-braces lint in the gallery FutureBuilder; the braces were added. The integrated pnpm verify rerun passed: formatting, generated-source check, 66 tooling tests, style audit, Web build/typecheck, Flutter analysis, 416 Flutter tests, Storybook build and Widgetbook release build. The build still reports a CupertinoIcons font asset warning; it did not fail the build and these charts do not introduce Cupertino icons.

Native Android interaction was not tested: this Widgetbook checkout has no Android host. No native scaffold or dependencies were added.
