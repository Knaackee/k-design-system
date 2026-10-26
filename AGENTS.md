# Repository instructions

These instructions are written for human contributors and coding agents,
including GPT-5.6 Sol.

## Start here

1. Read `README.md`.
2. Read `docs/plans/0001-incremental-bootstrap.md`.
3. Check `git status --short --branch`.
4. Work only on the explicitly approved slice.
5. Run `pnpm verify` before proposing a commit.

For every UI change, read `.agents/skills/k-design-system-workflow/SKILL.md` and
its linked composition contract before choosing controls, layouts or styling.

## Product contract

- The system targets React/Web and Flutter.
- Design tokens are platform-neutral source data.
- Consumer appearance must be configurable from outside the component packages.
- Shared primitives are the foundation for both library and consumer components.
- Storybook and Widgetbook will use matching fixture IDs for visual review.
- Platform-specific behavior is allowed only when documented.

## Change boundaries

- Do not copy the old catalog wholesale.
- Do not create speculative components or token axes.
- Do not edit generated files once generation exists; change their sources.
- Do not import underlying UI libraries from consumer-facing code unless an
  approved wrapper contract permits it.
- Do not update visual baselines merely to make a check pass.
- Do not combine repository infrastructure, tokens and component work in one
  unapproved change.

## Small-slice rule

A slice must state its outcome, allowed paths, dependencies, verification and
observable evidence. If a missing decision would change public API, token names,
package boundaries or platform behavior, stop and request a decision.

## Package boundaries

- `packages/web/tokens`: Web token projection only.
- `packages/web/ui`: Web primitives/components; may depend on Web tokens.
- `packages/flutter/k_design_tokens`: Flutter token projection only.
- `packages/flutter/k_design_ui`: Flutter primitives/components; may depend on
  Flutter tokens.
- `apps/storybook` and `apps/widgetbook`: galleries, never package source.
- `examples`: consumer verification, never hidden package implementation.
- `docs/plans`: approved work and long-term strategy.

## Required checks

```bash
pnpm install
dart pub get
pnpm verify
```

When a future slice adds narrower commands, prefer the narrow check while
iterating and finish with `pnpm verify`.
