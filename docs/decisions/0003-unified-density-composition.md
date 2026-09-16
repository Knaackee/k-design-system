# Decision 0003 — Unified density and cross-platform composition

> Status: **accepted**  
> Date: 16 September 2026  
> Human acceptance: 16 September 2026 — user confirmed Decision 0003: “Ja, mache ich. Jetzt setze das bitte um.”

## Confirmed direction

The user selected **Nur Density (Recommended)** for a Regular planning step.
This confirms one density axis, not the proposed numeric values or APIs below.

## Evidence

The existing Card fixture uses different layout rules between platforms.
Productive/Expressive changed Web card widths from 364 to 348 px, causing a
body-text line wrap. Padding stayed 16 px, text gap 8 px and action gap 16 px.
Flutter uses fixed 340 px cards. The apparent change in internal spacing was
therefore not a change in text margins.

The preceding uncommitted correction fixed Flutter's missing action gap,
Web grid-track stretching and double Material compaction of Dense buttons.
These fixes remain pending visual acceptance and do not replace composition
primitives.

## Proposed decision

Keep **Dense / Standard / Spacious**, with Standard as the default. Remove the
separate presentation axis from token modes, generated projections, Flutter
configuration and gallery controls. Preserve independent brand, color mode,
type scale, input mode, window class and accessibility text scale.

Density resolves component and composition spacing from shared semantic tokens.
Proposed values in CSS px / Flutter logical px:

| Role                           | Dense | Standard | Spacious |
| ------------------------------ | ----: | -------: | -------: |
| `space.controlGap`             |     4 |        8 |       12 |
| `space.contentActionGap` (new) |     8 |       16 |       24 |
| `space.controlInsetInline`     |     8 |       12 |       16 |
| `space.cardPadding`            |    12 |       16 |       24 |
| `space.layoutSectionGap`       |    16 |       32 |       48 |
| `size.control`                 |    32 |       36 |       44 |

Reference the existing foundation scale. Standard preserves the corrected Card
composition. Layout gutters continue to follow window class; density does not
change font metrics or minimum touch targets.

## Composition contract

- Export `KStack` (vertical) and `KInline` (horizontal) from both UI packages.
- Both accept a semantic `gap` role: `control` (default), `action` or `section`,
  resolving respectively to the three shared gap tokens above.
- Both accept cross-axis `align`: `start` (default), `center`, `end`, `stretch`.
  Flutter exposes typed enums with matching values; Web exposes string unions.
- `KInline.wrap` is explicit, defaults to false, and uses the selected gap role
  for both horizontal and vertical gaps when enabled. Wrapped cross-axis
  stretching is unsupported on both platforms and must be rejected explicitly.
- Default layout preserves natural child size. It must not stretch text line
  boxes or visible buttons to consume spare space.
- `KText` and `KButton` have no implicit external margins. Parents own sibling
  spacing. `KCard` owns its semantic inset, not gaps inferred from child types.
- Card composition nests a control-gap heading/body stack inside an action-gap
  content/action stack. Remove gallery-only action margins and `SizedBox`
  spacing recipes for compositions migrated in this slice.
- Consumers can use these primitives and externally supplied tokens without
  depending on gallery source.

## Configuration migration

Remove `KPresentation`, `KDesignConfiguration.presentation`, generated
presentation variants and Web `data-presentation` support together. Old
Productive/Expressive URL parameters become inert; density controls the result.
Document this pre-release breaking change and update all in-repository usages.

Preserve Dashboard = Dense, Desktop = Standard and Mobile = Spacious. Map
Marketing to Spacious with Standard type scale and Pointer input. Do not
introduce a compatibility mechanism that keeps a hidden second spacing axis.

## Comparable fixtures

Gallery frames, not components, own viewport placement. Card and Surface
fixtures use identical available-width calculations, token gutters and a
maximum content width of 760 logical px. Use one column below a 600 logical px
fixture viewport and two at or above it. Subtract the resolved section gap
before dividing the available row width. Physical viewport width and the
window-class setting are distinct and must be matched deliberately for review.

Keep fixture IDs, text, fonts and configuration identical. Include one-line and
wrapped copy; compare relative geometry, not gallery chrome or page position.

## Alternatives and consequences

- Keeping both axes preserves independent editorial rhythm but retains the
  complexity the user rejected.
- Keeping only Productive/Expressive replaces the existing working three-level
  density control.
- Patching gallery margins alone gives consumers no reusable composition rule.

On acceptance, this decision replaces only the presentation/density and
corresponding preset portions of
[Decision 0001](0001-adaptive-foundation.md). Preserve that accepted document
unchanged. Its other axes and interaction/accessibility protections remain
applicable, as does Decision 0002's human visual review process.

This slice adds no product components and changes no colors, opacity, typography
or interaction feedback. It does not promise identical arbitrary consumer
compositions or identical font rasterization.

## Verification and human acceptance

Test both layout primitives and Card/Surface compositions at all three densities,
including a live configuration update without remounting. Cover both type scales,
Pointer/Touch, 100/200 percent text scaling and all four brand/color combinations.
Test wrapping, zero/one/multiple children, external token overrides and a
consumer-style composition outside gallery source.

Compare matched Web browser and Flutter render geometry within 0.5 logical px
for spacing and visible control sizes. Compare screenshots at 375 and 1024 px;
text antialiasing need not be identical. Run the full repository gate, obtain
human visual acceptance, and request commit authorization separately.
