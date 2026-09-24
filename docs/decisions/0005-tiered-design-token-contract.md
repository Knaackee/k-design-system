# Decision 0005 — Tiered design-token contract

> Status: **accepted for implementation**  
> Date: 24 September 2026  
> Scope: platform-neutral tokens and consumer theming across Web and Flutter
> Human approval: 24 September 2026 — “Ich genehmige den Plan und akzeptiere Decision 0005.”

## Context

K Design System already generates Web CSS variables and a Flutter
`ThemeExtension` from platform-neutral DTCG sources. Components use many of
those roles, but handwritten Web and Flutter source still contains visual
colors, radii, spacing, sizes, shadows and motion values. Component-specific
defaults also need to remain customizable without breaking global theming.

The repository currently contains 132 candidate Web declarations in 12 package
stylesheets and 125 candidate Flutter literals in 30 handwritten package files.
These figures include legitimate structural values and are an audit input, not
an instruction to replace every number mechanically.

## Decision

Use three public token tiers from one platform-neutral DTCG source:

1. **Foundation tokens** contain context-free scales and raw values.
2. **Semantic tokens** describe reusable design roles such as surface, text,
   border, focus, spacing, shape, elevation, opacity, motion and icon geometry.
3. **Component tokens** describe a named component part and property only when
   consumers need independent control or a semantic role is insufficient.

Component tokens reference semantic tokens by default. They do not duplicate
literal values. Token names describe purpose rather than current appearance,
for example `component.mobileAppBar.container.radius.floating` rather than
`component.mobileAppBar.radius24`.

### Runtime alias behavior

Aliases remain live at the consumer boundary:

- Web component custom properties default to semantic CSS variables with
  `var(...)`. Scoped consumer overrides therefore cascade naturally.
- Flutter generation records component-to-semantic dependencies. Changing a
  semantic field through generated `copyWith` also updates component values
  that still use that default. An explicit component override wins.
- `kDesignTheme` exposes a token-transform hook so applications can install a
  generated `copyWith` theme without reconstructing `ThemeData`.

This makes both broad changes, such as removing all rounding, and narrow changes,
such as changing only the floating app-bar radius, supported public use cases.

### What is tokenized

The public appearance contract covers:

- colors and interactive state colors;
- typography and icon geometry;
- spacing, visible component sizes and layout rhythm;
- radii, border widths, focus rings and elevation;
- opacity, scrims, blur and glass parameters;
- animation duration and easing;
- component-part values that require independent customization.

Content, callbacks, state ownership, accessibility semantics and behavioral
configuration remain component API concerns. Percentages, flex/grid mechanics,
calendar/date arithmetic, pointer coordinates, collection indices and reset
values such as zero margins are structural implementation values unless they
express visible design intent.

### Safety and accessibility

Defaults continue to meet the system's contrast, focus and touch-target
requirements. Consumers may theme appearance, while semantic behavior and
accessible names remain intact. Hit-target tokens stay independent from visible
control dimensions. Generated documentation identifies overrides that can
reduce contrast or touch usability.

### Enforcement

Add a source audit to the repository verification. It rejects new unapproved
raw visual colors, radii, shadows, typography, opacity and motion in component
package source. Dimension literals are classified deliberately because many
complex components contain non-visual geometry. Necessary exceptions are
documented narrowly beside the audit configuration; galleries and generated
files never become token sources.

## Alternatives considered

- **Semantic tokens only:** simple, but cannot customize one component without
  changing unrelated components.
- **Component tokens only:** flexible, but destroys system-wide theming and
  creates excessive public API.
- **Independent resolved component values:** matches initial defaults, but a
  later global theme override no longer cascades.
- **Expose arbitrary style objects only:** useful as an escape hatch, but lacks
  cross-platform parity and a common design vocabulary.

## Consequences

- The generated public token surface grows and requires naming discipline.
- Adding or renaming a token is a public API decision.
- Existing component behavior remains unchanged during migration; default
  screenshots should remain visually stable.
- Web and Flutter consumers gain equivalent global and per-component theming.
- New components must use existing roles or explicitly add reviewed tokens
  before entering the library.

Acceptance of this decision authorizes the contract, not commits, releases,
baseline updates or publication.
