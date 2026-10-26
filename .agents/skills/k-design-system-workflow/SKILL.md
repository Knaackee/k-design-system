---
name: k-design-system-workflow
description: Build or migrate UI in an application that consumes K Design System through a Git submodule. Use when choosing existing components, adding reusable UI, changing design tokens, or updating the pinned design-system version.
---

# K Design System consumer workflow

Before any consumer UI edit, read `docs/integration/ui-composition.md` relative to
this Skill's repository root. This is mandatory, including small fixes.
No global Skillset installation is required. If available, also follow the global
`design-system/k-design-system-consumer` Reference for integration lifecycle.
Repository-owned instructions and explicit user migration boundaries still apply.

## Locate and update

Resolve the library through .gitmodules, vendor/k-design-system, local package
paths, then one bounded search. Inspect AGENTS.md, public exports and catalog.
Fetch origin and compare the pin with origin/main (or the verified remote default
branch). Fast-forward only a clean non-divergent checkout; preserve local work.
Use a feature branch for library changes. Do not silently integrate unpublished APIs.

## Mandatory composition

Map requested controls to public K components before coding. Native HTML,
Material/Cupertino or upstream UI controls are not substitutes in consumer code.
Structural layout is permitted. Missing reusable behavior belongs in the library.
Use KStack/KInline and existing semantic tokens for spacing; follow the linked
contract for card insets, hierarchy, density and responsive behavior.
Never patch private component selectors or duplicate reusable primitives locally.

Before coding, record a short composition map: requested screen -> existing
shell/pattern -> public K controls -> spacing and typography token roles. Use
`docs/integration/ui-composition.md` for the decision table and reference stories.
Inspect the implementation and public props; never infer behavior from names alone.
If a reference exists, adapt that composition rather than inventing a replacement.

Verify complete journeys, not screenshots of the initial state: navigation and
return, overlay dismissal and focus return, invalid/valid submission, empty search
and recovery. Exercise short mobile viewports, touch input, larger type and every
density. Report actual checked states and omissions. A successful build or scanner
is not evidence that these journeys work. Keep demos separate from package APIs.

## Ownership and acceptance

Host owns product data, navigation, events and theme overrides. Library owns
reusable components and shared defaults. For ambiguous token changes ask whether
host overrides or shared defaults are intended before editing.
New APIs require matching Web/Flutter gallery fixtures, required verification and
human visual acceptance before host integration. Commit, push, merge and sync
retain their separate authorization requirements. Update the host pin only to
the intended published revision and run host checks.

## Completion evidence

Report revision, reused/added components, spacing/token roles, override location,
consumer-check results, inspected responsive/density/theme states and unverified
platforms. Build success is not visual acceptance. For migration also follow
`docs/integration/migration.md` relative to this repository.
