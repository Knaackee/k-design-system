# Web consumer example

This app consumes the design-system packages as local workspace dependencies.
An application using this repository as a Git submodule adds the submodule's
Web packages to its `pnpm-workspace.yaml`:

```yaml
packages:
  - apps/*
  - vendor/k-design-system/packages/web/*
```

Its application can then use the same `workspace:*` dependencies. pnpm links
the submodule packages instead of copying a stale, pre-build snapshot.

The application owns `src/theme.css`. It overrides semantic and component
tokens locally without changing the design-system defaults.

Use component subpath imports in production code so bundlers do not need to
traverse optional editor, chart, and agent dependencies:

```ts
import { KButton } from "@k-design-system/ui/primitives/button";
```

```bash
pnpm build:web
pnpm --filter @k-design-system/example-web build
pnpm --filter @k-design-system/example-web verify:tree-shaking
```

The tree-shaking check bundles a minimal entry from the public package export
and fails if unrelated Calendar or chart implementation code contributes bytes
to the output.
