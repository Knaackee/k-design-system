# K Design System

K Design System is a cross-platform, token-driven component library for React/Web
and Flutter. Consumers can use the provided components or compose product-specific
components from shared primitives and design tokens.

The repository is intentionally built incrementally: establish the workspace,
prove token delivery, add galleries, then deliver one primitive or component at a
time with a shared visual review.

## Current state

The repository baseline, minimal token pipeline, Storybook and Widgetbook are
operational. Button, Typography, Surface and Card prove the complete path from
platform-neutral tokens to both galleries. The adaptive presentation foundation,
semantic color roles, radius scale and restrained elevation hierarchy are
available in both galleries for visual iteration.

The active plan is [docs/plans/0001-incremental-bootstrap.md](docs/plans/0001-incremental-bootstrap.md).
The complete strategic design is preserved in
[docs/plans/orbit-ds2-strategic-master-plan.md](docs/plans/orbit-ds2-strategic-master-plan.md).

## Packages

| Path                               | Purpose                             | Current state            |
| ---------------------------------- | ----------------------------------- | ------------------------ |
| `packages/web/tokens`              | Generated CSS and typed Web tokens  | Operational              |
| `packages/web/ui`                  | React/Web primitives and components | Core primitives          |
| `packages/flutter/k_design_tokens` | Generated Flutter tokens and themes | Operational              |
| `packages/flutter/k_design_ui`     | Flutter primitives and components   | Core primitives          |
| `apps/storybook`                   | Web component gallery               | Operational on port 6006 |
| `apps/widgetbook`                  | Flutter component gallery           | Operational on port 6007 |

## Prerequisites

- Node.js 22
- pnpm 11
- Flutter 3.44 / Dart 3.12

Melos is a repository dev dependency and does not need a global installation.

## Native checks

```bash
pnpm install
dart pub get
pnpm verify
```

Run `pnpm verify` before every commit. It builds and type-checks the Web packages,
analyzes and tests the Flutter packages, and checks Markdown/JSON/YAML formatting.

## Galleries

```bash
pnpm storybook
pnpm widgetbook
```

Storybook runs at `http://localhost:6006`; Widgetbook runs as Flutter Web at
`http://localhost:6007`. Both expose Orbit/Reference and Light/Dark theme
selection and use the fixture IDs `button-primary` and `button-states`.
Presentation, density, type scale, input mode, window size and accessibility
text scaling can be reviewed independently. The contract and working agreement
are recorded in
[Decision 0001](docs/decisions/0001-adaptive-foundation.md).
The component-by-component Linear calibration and visual acceptance workflow is
recorded in
[Decision 0002](docs/decisions/0002-linear-default-and-visual-review-flow.md).
The primitive contracts are documented under
[Button](docs/components/button.md),
[Typography](docs/components/typography.md),
[Semantic colors](docs/components/colors.md), and
[Shape, elevation, Surface, and Card](docs/components/surface-card.md).

## Working agreement

Read [AGENTS.md](AGENTS.md) before changing the repository. Implement one approved
slice at a time. Do not add a component, token axis, dependency or public API that
is not part of the active slice.
