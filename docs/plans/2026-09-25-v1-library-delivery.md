---
title: "V1 library delivery and consumer workflow"
date: 2026-09-25
status: approved
---

# V1 library delivery and consumer workflow

## Outcome

Deliver the first consumable K Design System version for React/Web and Flutter.
Applications include this repository as a Git submodule, depend on its platform
packages, and keep their own brand token overrides and product configuration in
the host repository.

The user approved this scope on 25 September 2026: "Du hast die Freigabe. ...
Also go."

## Scope

- Turn accepted gallery references that represent library components into public
  Web and Flutter package exports; galleries consume those exports.
- Add real Web and Flutter consumer examples with host-owned token overrides.
- Prove Web production builds and tree shaking while preserving required CSS.
- Harden package metadata, package contents, dependency contracts, versioning,
  CI and release checks for an initial version.
- Replace the bootstrap README with consumer, contributor, submodule and
  migration documentation.
- Add a reusable repository skill that makes the submodule the first place an
  agent checks and requires gallery review plus human acceptance before a new
  reusable component is integrated into a host application.

## Boundaries

The design-system repository owns primitives, components, patterns, default
tokens, generators, galleries and shared behavior. The consuming project owns
its chosen theme, token overrides, business data, navigation and application
logic. A host must never edit shared default tokens merely to brand one product.

No registry publication or remote release is performed in this slice. The
repository becomes release-ready and submodule-consumable; publishing remains a
separate explicit action.

## Verification

- Build and type-check both Web packages and the standalone Web consumer.
- Assert that an unused component is absent from the production Web bundle.
- Analyze and test both Flutter packages and the standalone Flutter consumer.
- Verify generated tokens and repository tooling.
- Run the repository `pnpm verify` program and report any pre-existing immutable
  document-format blocker separately.

## Acceptance

Provide installation commands, example paths, public exports, theming examples,
the workflow skill and exact verification results for human acceptance.
