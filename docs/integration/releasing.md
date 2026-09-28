# Release process

This checklist applies to a supported design-system release and to a commit that
will be pinned by consuming applications.

## Release gates

- Public Web and Flutter exports contain the intended component set.
- Package manifests contain only required runtime assets and dependencies.
- External Web and Flutter examples install without workspace-only assumptions.
- The Web example proves production bundling and tree-shaking; CSS remains an
  explicit root import.
- Generated token projections are current and host override examples pass.
- `pnpm verify` succeeds on the release commit.
- Storybook and Widgetbook build successfully and the affected fixtures have
  human visual acceptance.
- The changelog describes consumer-visible behavior and migration needs.
- Package versions and the Git tag agree with the selected semantic version.
- A repository distribution license and required third-party notices are present.
- CI runs for the repository's release branch and the release tag.

## Versioning

- Patch: compatible fixes without public contract changes.
- Minor: backward-compatible components, props, callbacks or tokens.
- Major: removed or incompatible public APIs, token renames or changed behavior
  that requires consumer migration.

Until the first supported tag is created, manifests and changelog entries remain
pre-release. Do not describe a commit as released solely because both galleries
render it.

## Consumer handoff

Publish the accepted commit or tag, then let each host project update its
submodule pointer deliberately. The host keeps its existing theme overrides and
runs its own production and integration checks before accepting the update.
