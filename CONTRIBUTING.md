# Contributing to K Design System

K Design System is the shared UI source for Web and Flutter applications. Changes
must strengthen a reusable contract rather than move product-specific behavior
into the library.

## Before changing code

1. Read `AGENTS.md` and the relevant approved Plan or decision.
2. Check the public exports, component catalog, Storybook and Widgetbook before
   creating a component.
3. Keep product data, permissions, routing and business rules in the host app.
4. Define the component outcome, public API, affected paths and verification.
5. If a token change is requested, establish whether it is a project-local host
   override or a shared default. Do not edit a token source while that ownership
   is ambiguous.

## Component contract

A reusable component should:

- expose content, controlled state and relevant events to consumers;
- use design tokens for appearance and existing primitives for composition;
- provide equivalent Web and Flutter behavior, or document an approved platform
  exception;
- preserve keyboard, pointer, touch and semantic accessibility;
- respond to density, input mode, text scale, window class and theme where they
  affect the component;
- include matching deterministic Storybook and Widgetbook fixtures;
- avoid importing gallery or example code into a package.

Add a token only when no existing semantic or component role expresses the
design intent. Change platform-neutral sources and regenerate projections with
`pnpm generate`; never edit generated files directly.

## Verification and acceptance

Use focused checks while iterating. Before proposing a commit, run:

```bash
pnpm verify
```

Tests and builds establish technical evidence. A UI change additionally needs a
human visual review in Storybook and Widgetbook at the relevant themes,
densities, viewports and input modes. Do not update a consuming application or
its submodule pointer until that review is accepted.

## Git submodule contributions

When working from a consuming project, enter `vendor/k-design-system` and treat
it as its own repository. Commit and push library changes there only with the
required authorization. After the accepted design-system commit is available,
return to the host repository, update the submodule pointer and integrate the
public API. Do not mix host branding into the design-system commit.

See [consumer integration](docs/integration/submodule.md) for the complete flow.
