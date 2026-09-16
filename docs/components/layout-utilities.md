# Container, Grid, Icon and Separator

These primitives share one contract across React/Web and Flutter. Dimensions are
CSS pixels on Web and logical pixels in Flutter. The components add no external
margins. All gallery entries live under Primitives and use automatic alphabetical
sorting.

## Container

`KContainer` centers its child with density/window-class token gutters on both
sides. `maxWidth` defaults to 760 and limits content, excluding gutters. It must
be positive and finite. Very narrow parents clamp content to zero without
negative padding. Flutter requires bounded horizontal constraints. It adds no
vertical spacing or scrolling.

## Grid

`KGrid` uses available parent width, not viewport width. `minColumnWidth` defaults
to 240 and must be positive and finite. `gap` reuses control/action/section with
section as default. In automatic mode, columns are calculated as
`max(1, floor((availableWidth + gap) / (minColumnWidth + gap)))`.

Optional `columns` selects a fixed positive integer count and overrides the
automatic calculation. Omit it for responsive reflow. Both galleries expose
Auto/1/2/3/4/6 columns, minimum column width and the three semantic gap roles.
Fixed columns can become impractically narrow on small screens; select Auto for
content that must adapt to available space.

Columns have equal widths, including a partially occupied final row. In Auto,
a parent narrower than the minimum gets one shrinking column. Each row follows
its tallest child; children align at the start without vertical stretching.
Empty grids have zero height. Flutter requires bounded horizontal constraints.
The grid does not scroll or virtualize; large data collections need a separate
list contract.

## Icon

`KIcon` uses the same Lucide 1.46.0 SVG source on both platforms. The curated
catalog contains 48 common icons, including navigation, actions, files, people
and status. Web exports `kIconNames`; Flutter exposes `KIconName.values`.
Hyphenated Web names map to camelCase Dart enum values (arrow-right/arrowRight).

`size` defaults to 16 and must be positive and finite; it does not follow text
scaling. Both galleries offer 12/16/20/24 px controls and a compact catalog with
hover names. `color` defaults to the primary text token. Stroke geometry scales
with size.

Icons are decorative without a nonempty `label`. A label exposes a meaningful
image to assistive technology. Interactive controls still need their own label
and target size; KIcon itself is not interactive.

The canonical SVGs and upstream license are in `assets/icons/lucide/`. Run
`pnpm generate` after changing the curated set. `pnpm generate:check` detects
projection drift. Do not edit generated TS/Dart data. Flutter uses flutter_svg;
Web uses an SVG mask tinted with the same color. Raster edge antialiasing can
still differ between renderers despite identical vector geometry.

## Separator

`KSeparator` is a decorative line with the default border color and width tokens.
Orientation defaults to horizontal; it fills available width unless `length` is
provided. Vertical separators default to length 24. Length must be nonnegative
and finite. Separators add no margins; use KStack/KInline for spacing. Semantic
grouping belongs to surrounding content. Flutter dimensions remain subject to
parent constraints; do not stretch a deliberately short separator.

## Verification and fixtures

Matching fixture IDs: container-bounds, grid-responsive, icon-lucide and
separator-orientations. Existing fixture URLs are preserved.

- `pnpm verify`: generation drift, builds, formatting, analysis and native tests.
- `flutter test test/additional_primitives_test.dart` in k_design_ui: grid
  boundaries, narrow containers, icon size/semantics, separators and invalid input.
- `node apps/storybook/src/additional-primitives.test.mjs`: 27 Web grid boundary
  cases and 48 screenshot pairs with position/size comparisons. Start both
  galleries first; set KDS_PLAYWRIGHT_MODULE if Playwright is not locally resolved,
  and KDS_PARITY_OUTPUT to an output directory. The matrix covers 375/1024 widths,
  all three densities, Orbit Light at 100% and Reference Dark at 200% text scale.

Visual human acceptance remains separate from automated checks.
