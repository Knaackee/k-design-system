# Decision 0001 — Adaptive presentation foundation

> Status: accepted for implementation  
> Date: 28 August 2026  
> Scope: shared Web and Flutter configuration contract

## Decision

K Design System models adaptive appearance as independent axes. Named presets
are convenience combinations and never replace the underlying token contract.

| Axis              | Values                                                 | Responsibility                                          |
| ----------------- | ------------------------------------------------------ | ------------------------------------------------------- |
| `presentation`    | `productive`, `expressive`                             | Product versus editorial layout rhythm                  |
| `density`         | `dense`, `standard`, `spacious`                        | Visual control size and component insets                |
| `typeScale`       | `compact`, `standard`                                  | 14 px versus 16 px base typography                      |
| `inputMode`       | `pointer`, `touch`                                     | 24 px versus 48 px minimum interaction target           |
| `windowClass`     | `compact`, `medium`, `expanded`, `large`, `extraLarge` | Responsive layout gutters                               |
| system text scale | 100–200% review range                                  | Accessibility scaling; never a production density token |

Density does not change font size, layout breakpoints or the system text scale.
Presentation does not change hit targets. A component may be visually compact
while retaining a larger touch target.

## Window classes

- Compact: below 600 logical pixels
- Medium: 600–839
- Expanded: 840–1199
- Large: 1200–1599
- Extra large: 1600 and above

Runtime integrations derive this value from the available window, never from a
phone/tablet/desktop device label. Flutter exposes `kWindowClassForWidth`; Web
uses the matching `data-window-class` contract until an application-level
responsive provider is introduced.

## Presets

| Preset      | Presentation | Type scale | Density  | Input mode         |
| ----------- | ------------ | ---------- | -------- | ------------------ |
| Dashboard   | Productive   | Compact    | Dense    | Pointer            |
| Desktop app | Productive   | Compact    | Standard | Pointer            |
| Mobile app  | Productive   | Standard   | Spacious | Touch              |
| Marketing   | Expressive   | Standard   | Standard | Pointer by default |

Flutter exposes these as constants on `KDesignConfiguration`. Web consumers set
the individual data attributes, which means presets can later be supplied as a
small helper without changing the CSS token contract.

## Token and runtime ownership

- `tokens/foundation.tokens.json` owns raw scales.
- `tokens/semantic.tokens.json` owns active component and layout roles.
- `tokens/modes/*.tokens.json` owns bounded overrides for each axis value.
- The generator validates every mode against the semantic contract and emits
  CSS selectors plus typed Flutter variant constants.
- Brand and color mode remain orthogonal to all adaptive axes.

## Visual iteration agreement

Storybook and Widgetbook remain the primary development surfaces. Every shared
primitive or component receives matching deterministic fixture IDs. The agent
implements and verifies source behavior; the user performs the visual review in
both galleries and returns `Accept` or concrete revision feedback. A component
is not visually accepted merely because automated checks pass.

The galleries must expose brand, color mode, presentation, density, type scale,
input mode, window size and accessibility text scaling. During ordinary
iteration we review representative presets; exhaustive combinations belong to
release verification so that routine component work remains fast.

## Evidence behind the model

- Carbon separates productive 14 px product typography from expressive 16 px
  editorial typography.
- Flutter `VisualDensity` explicitly does not scale text or icons.
- Responsive behavior follows available window size rather than hardware type.
- Touch targets remain independent from their visible control bounds.

The exact visual values remain subject to gallery review. Changing axis names,
responsibilities or breakpoint boundaries requires a new decision; tuning a
token value does not.
