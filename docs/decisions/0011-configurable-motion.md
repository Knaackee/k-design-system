# Decision 0011 — Configurable motion roles

> Status: proposed (implemented on `feat/motion-tokens`, pending gallery acceptance)
> Date: 5 November 2026
> Builds on: [0010](0010-adaptive-resolution-and-phone-type.md) (adaptive axes)

## Problem

Components animated with ad-hoc durations (`var(--k-motion-fast)`,
`t.motionEntry`, literal `480ms`) and ad-hoc curves (`ease`, `easeOutCubic`,
four different `cubic-bezier`s). Web and Flutter therefore moved differently,
there was no way to choose a motion style per product, and an app-level
"reduce motion" setting did not exist. `--k-motion-slow` was referenced in
three chat animations but never defined (they did not animate).

## Decision

### 1. Roles, not durations

Components pick what moves; the style decides how.

| Role        | Use                                       |
| ----------- | ----------------------------------------- |
| `feedback`  | press, hover, focus                       |
| `control`   | toggle, select, expand, reorder, resize   |
| `enter`     | sheet, dialog, popover, toast appears     |
| `exit`      | something leaves (never bouncy)           |
| `page`      | screen and tab content change             |
| `attention` | rare emphasis (goal reached, celebration) |

Each role is a spring given by **perceptual duration** and **bounce** (the
model of SwiftUI and Flutter `SpringDescription.withDurationAndBounce`) plus a
**distance** multiplier for travelled offsets (1 full, 0 fade only).

Tokens: `motion.<role>.duration`, `motion.<role>.bounce`,
`motion.<role>.distance`. Web additionally gets the generated
`--k-motion-<role>-settle` (time until the spring rests within 0.1 %) and
`--k-motion-<role>-easing` (the same spring sampled into CSS `linear()`).
Flutter computes the identical spring (`tokens.motion(role)`: `.settle`,
`.curve`, `.spring`). Both platforms therefore follow the same curve; the
tooling and Flutter tests pin the settle times to each other.

### 2. Three styles, configurable

| Style             | Character                                                                           |
| ----------------- | ----------------------------------------------------------------------------------- |
| `apple` (default) | calm springs without bounce; `attention` bounces lightly                            |
| `expressive`      | Material Expressive-like: shorter, with bounce on spatial roles; exits never bounce |
| `reduced`         | 100–150 ms fades, no movement (`distance` 0), no bounce                             |

Values (perceptual duration / bounce):

| Role      | apple     | expressive | reduced |
| --------- | --------- | ---------- | ------- |
| feedback  | 100 / 0   | 100 / 0    | 100 / 0 |
| control   | 320 / 0   | 220 / 0.4  | 150 / 0 |
| enter     | 500 / 0   | 320 / 0.2  | 150 / 0 |
| exit      | 320 / 0   | 220 / 0    | 100 / 0 |
| page      | 500 / 0   | 450 / 0.2  | 150 / 0 |
| attention | 500 / 0.3 | 450 / 0.4  | 150 / 0 |

The style is an adaptive axis like density:

- Web: `applyKAdaptive(root, { motion: "expressive" })` sets
  `data-motion`; Storybook has a Motion toolbar.
- Flutter: `KAdaptiveTheme(overrides: KAdaptiveOverrides(motion: …))` or
  `KDesignConfiguration(motion: …)`; Widgetbook has a `motion` field.
- Single values stay overridable like every token (theme override files on
  Web, `tokenTransform` on Flutter).

**The person's setting always wins.** `prefers-reduced-motion: reduce`
(Web) and `MediaQuery.disableAnimations` (Flutter) resolve to `reduced`
whatever the app chose. An app may choose `reduced` itself (an in-app
setting); on Flutter this also sets `disableAnimations` below
`KAdaptiveTheme`, so every widget that already honours the platform setting
follows it.

### 3. Gate

`tooling/check-ui-rules.mjs` rule `raw-motion` (library code only): CSS
`transition`/`animation` with a literal duration, `ease*` or `cubic-bezier`,
and Flutter `duration: Duration(...)` / `curve: Curves.*` fail. Continuous
loops (spinners, shimmer, glow) and script-driven choreography (drag
rollback, screen switcher, call-bar waveform, attention keyframes) carry a
reviewed `k-ui-rules-ignore raw-motion: <reason>`.

## Consequences

- New public API: tokens `motion.<role>.*`, CSS `--k-motion-<role>-settle`
  and `-easing`, `data-motion`, Web `kMotion()`, `KMotionStyle`,
  `KMotionRole`, `KMotionSpec`, `KAdaptiveOverrides.motion`,
  `resolveKAdaptiveConfiguration(reduceMotion:)`.
- All library transitions moved to roles. The default `apple` style is
  slower than the previous 80–240 ms `ease` for `control`, `enter` and
  `page`; `feedback` is unchanged in feel. This needs gallery acceptance.
- The previous duration tokens (`motion.fast` … `motion.skeleton`) remain for
  loops and component timing; they are no longer used for transitions in
  library code.
- Web components that check `prefers-reduced-motion` directly do not react
  to an app-chosen `reduced` style; the role tokens do (fade only).
