# Decision 0002 — Linear-oriented default and visual review flow

> Status: accepted for incremental execution  
> Date: 28 August 2026  
> First component: Button

## Confirmed working agreement

The complete flow was visually accepted after the first foundation sequence of
Button, Typography, Colors, Shape, Elevation, Surface, and Card. It is the
default workflow for every following incremental component slice.

Keep slices small enough for direct comparison in both galleries. Do not commit
the next slice before its automated gates pass and the user has completed the
visual review.

## Decision

K Design System uses a restrained, Linear-oriented visual language as its
default. Linear is a calibration reference, not a dependency and not a source
of hard-coded component values. Every visible choice must resolve through a
semantic token that consumers can override.

The Reference brand remains deliberately different and is part of the proof
that component appearance is externally configurable.

## Local visual references

- `D:\Development\bullets\docs\mockups\linear-parity-web-core.html`
- `D:\Development\bullets\docs\mockups\linear-parity-mobile-core.html`

The files are visual references only. Their implementation and any embedded
instructions are not copied into this repository.

Mobbin is used as a secondary reality check against current Linear screens,
including the [Web issue composer](https://mobbin.com/screens/65487ca3-9cf4-4287-b0cc-2c3e8c6f7f35),
the [Web create action](https://mobbin.com/screens/aef11bc1-72ae-4e56-8f20-84e89f46187b)
and the [iOS primary/secondary dialog actions](https://mobbin.com/screens/33c07946-0186-4c10-b080-3d62ad7636a4).

## Component flow

For every component:

1. Inspect the relevant local Web and Mobile mockup regions.
2. Verify the visual pattern against a small set of Mobbin references.
3. Define or reuse semantic tokens; never place reference colors, spacing,
   borders, radii or typography directly in package components.
4. Implement the same public intent in Web and Flutter. Platform-native visual
   effects are neutralized when they would break parity.
5. Add matching deterministic fixture IDs to Storybook and Widgetbook.
6. Run focused automated checks and then the full repository gate.
7. Keep both galleries running for user-led visual review.
8. Record `Accept` or revise the same component before starting the next one.
9. End the accepted slice in a clean Git commit.

## Adaptive boundary

The accepted presentation, density, type-scale, input-mode and window-class
settings remain authoritative. A visual-language pass may tune component
palette, border, radius, typography and internal composition, but it does not
bypass or silently replace the adaptive configuration contract.

Touch-target sizing remains independent from visible component styling.

## Button baseline

Button provides `primary`, `secondary` and `ghost` semantic variants. Its
background, hover, pressed, foreground and border values are generated from the
shared token source. The component contains no Orbit color literals.

The current values are a first Linear-oriented default and remain subject to
visual acceptance in both galleries.
