# Integrating K Design System as a Git submodule

This guide describes the supported source-based integration. The host application
pins an accepted design-system commit and owns all application-specific
configuration. The submodule remains an independent repository for reusable UI.

## Ownership boundary

| Design-system submodule                  | Host application                       |
| ---------------------------------------- | -------------------------------------- |
| Shared primitives and components         | Product state and business logic       |
| Cross-platform public APIs               | Routing, permissions and data fetching |
| Shared default tokens                    | Brand and application token overrides  |
| Storybook and Widgetbook fixtures        | App screens and integration tests      |
| Package tests and accessibility behavior | Release cadence and submodule pin      |

Do not customize an application's brand by editing token sources in the
submodule. Put Web overrides and Flutter token transforms in the host repository.
Change shared defaults only when the intended result applies to all consumers.
Every token request must state which of those two scopes it targets before an
agent edits a token source.

## Add and pin the submodule

```bash
git submodule add https://github.com/Knaackee/k-design-system.git vendor/k-design-system
git submodule update --init --recursive
```

Commit `.gitmodules` and the submodule pointer in the host repository. Teammates
and CI should clone with submodules or run the update command after checkout.

The host always references a commit, not the moving tip of a branch. Updating is
therefore explicit and reviewable:

```bash
git -C vendor/k-design-system fetch origin
git -C vendor/k-design-system checkout <accepted-commit>
git add vendor/k-design-system
```

Review the library changelog and run the host application's checks before
committing the updated pointer.

## Web installation

Reference both local packages from the host `package.json`:

```json
{
  "dependencies": {
    "@k-design-system/tokens": "file:./vendor/k-design-system/packages/web/tokens",
    "@k-design-system/ui": "file:./vendor/k-design-system/packages/web/ui"
  }
}
```

Build the Web packages after a fresh submodule checkout and whenever their source
changes:

```bash
pnpm --dir vendor/k-design-system install --frozen-lockfile
pnpm --dir vendor/k-design-system build:web
pnpm install
```

Import the generated defaults and component styles once at the application root.
Import the host override after them:

```ts
import "@k-design-system/tokens/tokens.css";
import "@k-design-system/ui/styles.css";
import "./design-system/theme.css";
```

Use named ESM imports so the host bundler can remove unused JavaScript modules:

```tsx
import { KButton, KCard } from "@k-design-system/ui";
```

CSS is an explicit application-level side effect and is imported once. JavaScript
tree-shaking must be verified with the production bundler used by the host; the
external Web example records the repository's reference check.

### Project-local Web tokens

Keep overrides in the host, for example `src/design-system/theme.css`:

```css
:root {
  --k-color-action-primary-background: #2563eb;
  --k-color-action-primary-foreground: #ffffff;
}

[data-product-theme="square"] {
  --k-radius-control: 0px;
  --k-radius-card: 0px;
  --k-radius-overlay: 0px;
}
```

Scope overrides to an application root or subtree when multiple brands share a
page. Prefer semantic tokens for system-wide intent and component tokens for a
narrow exception. Preserve contrast, focus visibility and minimum hit targets.

## Flutter installation

Add local path dependencies to the host `pubspec.yaml`:

```yaml
dependencies:
  k_design_tokens:
    path: vendor/k-design-system/packages/flutter/k_design_tokens
  k_design_ui:
    path: vendor/k-design-system/packages/flutter/k_design_ui
```

Then run:

```bash
flutter pub get
```

Install the generated theme at the application root and keep the transform in a
host-owned file such as `lib/design_system/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

ThemeData buildAppTheme(Brightness brightness) {
  return kDesignTheme(
    brightness: brightness,
    configuration: KDesignConfiguration.mobileApp,
    // One brand colour for buttons, switches, tiles and the FAB.
    tokenTransform: (tokens) => tokens.withAccent(const Color(0xff2563eb)),
  );
}
```

Use the public component library from application code:

```dart
import 'package:k_design_ui/k_design_ui.dart';

KButton(label: 'Save', onPressed: saveChanges);
```

Choose `KDesignConfiguration` from actual viewport and input needs. Host token
transforms customize appearance; they must not replace component semantics or
state ownership.

## Developing a missing component

1. Search the public exports, catalog and both galleries.
2. Decide whether the need is reusable across products. Keep a one-off product
   composition in the host.
3. For reusable UI, work inside the submodule under its `AGENTS.md` contract.
4. Build the public Web and Flutter APIs, using existing tokens and primitives.
5. Add matching Storybook and Widgetbook fixtures and focused tests.
6. Run the required verification and present both galleries for human review.
7. After acceptance, commit and push the submodule change when authorized.
8. Update the host's submodule pointer and integrate the accepted public API.

The canonical agent instructions for this flow live in
`.agents/skills/k-design-system-workflow/SKILL.md`. Do not copy that directory
into the host: a copy goes stale when the submodule moves. Install the small
routing entry from [host-skill.md](host-skill.md) instead.
