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

| Axis        | Source                                                                                     |
| ----------- | ------------------------------------------------------------------------------------------ |
| windowClass | available width of the rendering region (unchanged breakpoints)                            |
| inputMode   | Web: `(pointer: coarse)`; Flutter: iOS/Android/Fuchsia → touch                             |
| typeScale   | compact window → `mobile`; medium → `standard`; expanded+ → touch ? `standard` : `compact` |
| density     | `standard` unless overridden                                                               |

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

`text.scaleMax.body = 2.0`, `text.scaleMax.control = 1.6`,
`text.scaleMax.heading = 1.4`. Headings grow less than body text, as on iOS.
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

## Consequences

- Breaking (pre-release): removed tokens, changed `mobileApp`, snapped spacing,
  changed Storybook/Widgetbook defaults. See CHANGELOG.
- Typography geometry tests now assert the capped heading scale. Web Chromium
  measurements for 2.0 headings must be re-taken in gallery review.
- Visual acceptance in both galleries is still required (Decision 0001).
