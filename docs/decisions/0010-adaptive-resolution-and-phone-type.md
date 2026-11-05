# Decision 0010 — Adaptive resolution, phone type ramp and hardened rules

> Status: proposed (implemented on `feat/adaptive-foundation-hardening`, pending gallery acceptance)
> Date: 4 November 2026
> Supersedes parts of: [0001](0001-adaptive-foundation.md) (presets), [0003](0003-unified-density-composition.md) (mobile preset)

## Problem

Components looked right in Storybook/Widgetbook and on tablets/desktops but
too large and too airy on phones, most visibly on iPhone and on Android
devices whose system font size defaults above 100 %. Causes found in the
repository:

1. The configuration was chosen once per app (`KDesignConfiguration.mobileApp`)
   while the galleries rendered whatever the toolbar selected. Gallery and
   device therefore did not receive the same tokens. `windowClass` defaulted to
   `compact` and was never derived at runtime.
2. `mobileApp` combined Spacious density with the Standard ramp: H1 36/44,
   card inset 24, section gap 48, controls 44 — on a 360–393 pt wide screen.
3. System text scaling multiplied every role equally and without bounds, while
   both galleries reviewed at 1.0.
4. The foundation contained off-grid spacing (5, 6, 7, 9, 10, 14, 15 px) and
   type below the platform minimum (8 and 9 px).

## Decision

### 1. Resolve adaptive axes at runtime

`resolveKAdaptive` (Web) and `resolveKAdaptiveConfiguration` (Flutter) derive:

| Axis        | Source                                                                                   |
| ----------- | ---------------------------------------------------------------------------------------- |
| windowClass | available width of the rendering region (unchanged breakpoints)                          |
| inputMode   | primary pointer is coarse → touch (Web `(pointer: coarse)`; Flutter iOS/Android/Fuchsia) |
| typeScale   | compact window → `mobile`; every larger window → `standard` (input never changes type)   |
| density     | `standard` unless overridden                                                             |

**Parity rule.** Tablet and desktop render the same design; mobile Web and the
mobile app render the same design. Therefore only the window class selects the
type ramp. Input mode changes hit targets (48 touch / 24 pointer) and nothing
else. Data-dense desktop screens opt into `dense` density and the `compact`
ramp explicitly (`KDesignConfiguration.dashboard`), with a stated reason.

Input detection is the same rule on both platforms — the primary pointer.
Phones and tablets resolve touch, desktops pointer, on Web and Flutter alike.
Hybrid devices (touch laptops, tablets with a mouse) resolve to their primary
pointer; apps may override `inputMode`.

Explicit values win. Presets become overrides: `mobileApp` is now Standard
density + `mobile` ramp + touch (it no longer implies Spacious).
Flutter apps use `KAdaptiveTheme`; Web apps call `applyKAdaptive(element)`.
Both galleries default to the same resolution ("auto"/"device") so a review in
a phone frame equals the device.

### 2. Phone type ramp (`typeScale: mobile`)

| Role      | Size/line                           |
| --------- | ----------------------------------- |
| Heading 1 | 28 / 34                             |
| Heading 2 | 24 / 30                             |
| Heading 3 | 20 / 26                             |
| Heading 4 | 18 / 24                             |
| Heading 5 | 16 / 22                             |
| Heading 6 | 15 / 20                             |
| Body      | 16 / 24                             |
| Small     | 14 / 20                             |
| Label     | 14 / 20                             |
| Control   | 16 (prevents iOS Safari input zoom) |

Minimum type size is 11 px (`font.caption2Size`); `font.microSize` and
`font.microLabelSize` are removed.

### 3. Capped system text scaling per role

`text.scaleMax.body = 3.0`, `text.scaleMax.control = 3.0`,
`text.scaleMax.heading = 2.0`. All text reaches at least 200 % (WCAG 1.4.4);
headings grow less than body text at the largest accessibility sizes, as on
iOS. From 1.3× rows stack (`KSettingsRow` auto layout; Web `data-text-large`
set by `setKTextScale`).
Flutter: `KAdaptiveTheme` clamps globally to the body cap; `KText` applies the
heading cap. Web: `.k-text` and controls use `min(var(--k-text-scale), cap)`.

### 4. Strict spacing grid

Spacing uses 0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64. Former off-grid
semantic roles keep their names but snap to the grid (5→4, 6→8, 7→8, 9→8,
10→12, 14→16, 15→16, 3→2). Compact windows use a 24 px section gap; dense
density is not intended for compact windows.

### 5. Hardened composition rules

Enforced by `tooling/check-ui-rules.mjs` and debug assertions:

- **No nested cards.** A KCard/KSurface card must not contain another card.
- **Leading icons align to the first text line**, never to the vertical centre
  of a multi-line block. Use `KLeading`.
- Icon sizes 16/20/24 only, chosen by the adjacent text role.
- No raw spacing/font literals in components; semantic tokens only.

### 6. Gates that keep Web and Flutter honest on phones

| Gate                                                                               | Runs                                                                                                                                               | Fails on                                                                                                                                         |
| ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `apps/widgetbook/test/gates/phone_gate.dart` (`pnpm gate:phone-flutter`, 6 shards) | every Widgetbook use case (knob use cases included) at 360×740 and 393×852, iOS and Android, text 1.0/1.3/2.0/3.0, each configuration opened fresh | any RenderFlex overflow                                                                                                                          |
| `tooling/web-phone-gate.mjs` (`pnpm gate:phone-web`)                               | every Storybook story at 360 and 393 CSS px, coarse pointer, overlay scrollbars, same text scales                                                  | horizontal page overflow, an element past the right edge outside a scrolling/clipping container, or a story that does not load (after one retry) |
| `geometry_parity_test.dart` + `tooling/geometry-parity.mjs` (`pnpm gate:geometry`) | the shared reference `Review/GeometryParity` on phone (393, touch) and desktop (1280, pointer) at 1.0/1.3/2.0                                      | any size difference above 1 px between Flutter and Web                                                                                           |

Both phone gates go up to 300 %, the body/control cap; WCAG 1.4.4 asks for
200 %. There is no exception list. Use cases that need a device or network
(maps, media, embedded browser, remote images) are listed as skipped, never
as passed. Flutter use cases that throw something other than an overflow (a
map platform view inside a screen, a framework assertion) are listed as NOTE;
their layout is still checked.

What the 300 % pass required, as rules for new work:

- Rows of text plus a trailing value or action stack from 1.3× (Flutter
  `MediaQuery.textScalerOf`, Web `[data-text-large]`), so neither the title
  nor a number truncates. Library examples: `KDataTable` single column,
  `KOfferOverview`, `KWebSearch`, `KQuestionnaire` actions (wrap).
- Headers of dialogs scroll with the content at large text
  (`KCatalogEditorDialog`); fixed stages use a minimum height.
- Flutter `KCarousel` scales its slide height with the system text size (Web
  slides size to their content).
- Web layout children never exceed their parent (`.k-layout`,
  `.k-layout > *`, size containers get `width: 100%`, implicit grid columns
  are `minmax(0, 1fr)`); text and nested layouts in a row shrink like
  Flutter's `Flexible`; long words break; badges wrap like Flutter's
  flexible label; a button's hit area bleeds vertically only.

Optical size (`opsz`) follows the _scaled_ font size on both platforms; Web
does this through `font-optical-sizing: auto`, Flutter components pass the
`TextScaler` to their text styles.

## Consequences

- Breaking (pre-release): removed tokens, changed `mobileApp`, snapped spacing,
  changed Storybook/Widgetbook defaults. See CHANGELOG.
- Typography geometry tests assert the capped heading scale; the geometry
  parity gate replaces manual Chromium re-measurement for the reference set.
- Playwright is a machine tool, not a repository dependency. CI installs it
  globally before `pnpm verify:gates`.
- Visual acceptance in both galleries is still required (Decision 0001).
