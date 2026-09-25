---
name: k-design-system-workflow
description: Build or migrate UI in an application that consumes K Design System through a Git submodule. Use when choosing existing components, adding reusable UI, changing design tokens, or updating the pinned design-system version.
---

# K Design System consumer workflow

Use the global Skillset Reference
`design-system/k-design-system-consumer` as the canonical operating contract.
This Skill is the discoverable execution entry point and must remain aligned
with that Reference.

The repository-owned Skill is the source for this global copy. If they differ,
refresh the global copy through Skillset review before using it elsewhere.

Treat the design system as the first source for reusable UI. The usual submodule
path is `vendor/k-design-system`; honor the host's configured path when different.

## Locate and update the submodule

Resolve the actual path in this order: the matching `.gitmodules` entry,
`vendor/k-design-system`, local Web or Flutter dependency paths, then one bounded
search for this Skill or the public package manifests. If no integration exists,
treat the repository as a migration and establish the design-system boundary
before reusable UI work.

Before design work, inspect the submodule working tree and compare its commit to
`origin/master`. Fetch the remote. With a clean, non-divergent state, check out
`master` and fast-forward it to `origin/master`; never discard local work or
resolve divergence implicitly. Create every design-system change on a new
feature branch from that current master.

## Establish the boundary

Read the host repository instructions and the submodule's `AGENTS.md`. Inspect
the public package exports, `docs/component-catalog.md`, Storybook and Widgetbook
before creating UI. Do not copy gallery implementation into the host.

The host owns product state, routing, permissions, data access, business logic
and application-specific composition. It also owns brand and product token
overrides. The submodule owns reusable primitives, components, shared patterns
and shared default tokens.

For every requested design-token change, explicitly establish one of these
scopes before editing any token source:

1. **Host override:** the change applies to one application or brand. Implement
   it in the host's CSS variables or Flutter token transform.
2. **Shared default:** the change intentionally applies to all consumers.
   Implement it in the submodule's platform-neutral token source and regenerate.

If the request does not distinguish these scopes, ask one concise question and
do not mutate host or shared token sources until the user answers.

## Reuse or extend

Use an existing public component when it satisfies the behavior. Compose a
product-specific element in the host from public primitives when it is not
reusable. Do not introduce a duplicate local primitive or raw visual styling.

When reusable UI is missing:

1. Work in the submodule under its delivery mode and repository rules.
2. Design consumer-controlled content, state and events; keep domain logic out.
3. Implement equivalent Web and Flutter contracts. Document any explicitly
   accepted platform adaptation.
4. Use existing primitives and tokens. Adding or renaming public tokens requires
   its own reviewed decision.
5. Add matching deterministic Storybook and Widgetbook fixtures and focused
   interaction/accessibility checks.
6. Run the submodule's required verification and show both galleries for human
   visual acceptance.
7. Do not integrate the new API into the host before that acceptance.

Commit, feature-branch push, merge to `master`, and `master` push are separate
actions and require their applicable authorization. After the accepted
submodule commit is available on `master`, update the host's submodule pointer,
integrate only public package exports and run the host's own checks. At the start
of later UI work, compare the host pin to `origin/master` again so no consuming
repository silently falls behind.

## Migration work

Migrate existing applications in bounded areas: theme and foundations first,
then controls, navigation/overlays, data display and screens. Preserve observable
product behavior and keep rollback possible through small host commits and an
explicit submodule pin. Follow `docs/integration/migration.md` in the submodule
for the detailed checklist, resolving that path from the configured submodule
rather than the host repository root.

## Completion evidence

Report the pinned design-system commit, components reused or added, where host
theme overrides live, checks run, gallery review status and any platform
differences. Passing automation does not replace human visual acceptance.
