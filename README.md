# K Design System

K Design System is a cross-platform, token-driven component library for React/Web
and Flutter. Consumers can use the provided components or compose product-specific
components from shared primitives and design tokens.

The repository is intentionally built incrementally: establish the workspace,
prove token delivery, add galleries, then deliver one primitive or component at a
time with a shared visual review.

## Current state

Repository baseline only. Storybook, Widgetbook, token generation and production
components are deliberately deferred to the next approved slices.

The active plan is [docs/plans/0001-incremental-bootstrap.md](docs/plans/0001-incremental-bootstrap.md).
The complete strategic design is preserved in
[docs/plans/orbit-ds2-strategic-master-plan.md](docs/plans/orbit-ds2-strategic-master-plan.md).

## Packages

| Path                               | Purpose                             | Current state               |
| ---------------------------------- | ----------------------------------- | --------------------------- |
| `packages/web/tokens`              | Generated and typed Web tokens      | Empty package baseline      |
| `packages/web/ui`                  | React/Web primitives and components | Empty package baseline      |
| `packages/flutter/k_design_tokens` | Generated Flutter tokens and themes | Empty package baseline      |
| `packages/flutter/k_design_ui`     | Flutter primitives and components   | Empty package baseline      |
| `apps/storybook`                   | Web component gallery               | Reserved for the next slice |
| `apps/widgetbook`                  | Flutter component gallery           | Reserved for the next slice |

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

## Working agreement

Read [AGENTS.md](AGENTS.md) before changing the repository. Implement one approved
slice at a time. Do not add a component, token axis, dependency or public API that
is not part of the active slice.
