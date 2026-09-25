---
title: "Cross-platform collaborative Markdown and code editors"
date: 2026-09-24
---

# Cross-platform collaborative Markdown and code editors

## Objective

Deliver reusable, token-driven Markdown and code editors for Web and Flutter with
matching formatting, keyboard, pointer and touch behavior. Both editors work as
controlled standalone components and expose an optional transport-neutral boundary
for CRDT document updates, remote cursors and presence.

Mode: Regular. The user selected Regular on 24 September 2026.

Status: approved on 24 September 2026. The user accepted Decision 0007 and
requested Web implementation first; Flutter follows after Human visual acceptance
of the Web components.

## Scope

- Web and Flutter public editor models, controllers and callbacks.
- A rich Markdown editor with edit, source and read modes, selection-driven floating
  formatting bar and configurable fixed actions.
- A code editor with syntax highlighting, line numbers, wrapping, indentation,
  search, replace, read-only mode and optional diagnostics/completions.
- Locally bundled TipTap and CodeMirror runtimes with a typed Flutter bridge.
- Transport-neutral collaboration interfaces plus optional Yjs runtime adapters.
- Remote caret/selection presentation, participant labels and connection state.
- Matching Storybook and Widgetbook fixtures, including a two-participant local
  collaboration demonstration.
- Focused interaction, accessibility, bridge and convergence tests.

No collaboration server, authentication, persistence, code execution, language
server, cloud asset, document migration, visual-baseline update, commit, push or
publication is in scope.

## Governing decisions

- Proposed [Decision 0007](../decisions/0007-collaboration-ready-editor-contract.md)
  owns document and collaboration boundaries.
- [Decision 0005](../decisions/0005-tiered-design-token-contract.md) owns visual
  customization.
- [Decision 0001](../decisions/0001-adaptive-foundation.md) owns input, window and
  accessibility behavior.
- [Decision 0003](../decisions/0003-unified-density-composition.md) owns density.

## Public component set

1. **`KMarkdownEditor`** — controlled rich document, Markdown import/export,
   edit/source/read modes, placeholder, read-only state and consumer callbacks.
2. **`KEditorFormatBar`** — configurable floating or fixed commands for block type,
   bold, italic, strike, inline code, links, lists, tasks, quote and code block.
3. **`KCodeEditor`** — controlled text, language, highlighting, line numbers,
   wrapping, folding, search/replace, diagnostics and completion hooks.
4. **`KEditorSelection` / `KEditorTransaction`** — serializable selection and local
   change events without engine-specific types.
5. **`KEditorCollaborationAdapter`** — applies remote updates and publishes local
   updates, awareness and connection state; Yjs is an optional implementation.
6. **`KEditorParticipant` / `KRemoteSelection`** — consumer-owned identity, name,
   color, caret and selection information.

All visible labels, icons, available actions, custom action renderers, link and
attachment intents, language lists and empty/error states are configurable.

## Implementation waves

### 1. Contracts and local editor runtimes

- Add equivalent serializable TypeScript and Dart models.
- Implement `KMarkdownEditor` with rich/source/read modes and a selection-driven
  floating format bar.
- Implement `KCodeEditor` with the scoped editing capabilities.
- Package the editor runtime locally and add a versioned typed Flutter bridge.
- Reuse existing buttons, icon buttons, popovers, tooltips, tabs and scrollbars.

### 2. Collaboration and presence

- Add the transport-neutral adapter lifecycle and connection states.
- Add optional Yjs adapters for rich XML documents and text documents.
- Use relative positions for collaborative selections and preserve raw offsets for
  standalone controlled state.
- Render remote carets/selections without blocking local selection or scrolling.
- Keep awareness ephemeral and document updates durable.

### 3. Galleries and hardening

- Add matching fixtures: `markdown-editor`, `markdown-source`, `markdown-readonly`,
  `code-editor`, `code-diagnostics`, `editor-presence` and `editor-collaboration`.
- Demonstrate two independently focused editors exchanging local updates in memory.
- Verify compact portrait, medium and large layouts; keyboard, mouse and touch;
  Dense/Standard/Spacious; Light/Dark; increased text scale and reduced motion.
- Compare Web and Flutter screenshots and interaction traces before Human Acceptance.

## Acceptance criteria

- Formatting applies to the current selection and the floating bar follows selection
  without obscuring text or leaving the viewport.
- Rich/source/read transitions preserve all supported document structures.
- Code highlighting, selection, search, undo/redo and two-axis scrolling behave on
  keyboard, mouse and touch.
- Components remain usable with no collaboration adapter.
- Two editors converge under concurrent insert, delete and format operations; remote
  carets follow edits and disappear when presence expires.
- Consumers can replace every label/action and own persistence, transport and user
  identity without importing TipTap, CodeMirror or Yjs types.
- No runtime editor asset is downloaded from the network.

## Verification

Targeted iteration:

- Web typecheck/build and focused editor interaction tests.
- Flutter analyze and focused widget/bridge tests.
- Shared contract fixtures and CRDT convergence tests.
- Storybook and Widgetbook interaction review on desktop and compact portrait.

Final integrated program:

```text
pnpm install --frozen-lockfile
dart pub get
pnpm verify
git diff --check
```

Passing automation does not constitute Human visual acceptance. Commit and push remain
separate explicit gates.

## Risks and controls

- **Embedded-runtime startup:** bundle assets locally, initialize once and expose a
  deterministic loading/error state.
- **IME and touch selection:** include composition, Android/iOS selection and compact
  viewport scenarios in focused testing.
- **Schema drift:** version the bridge and rich schema; reject incompatible updates
  without mutating the document.
- **Large documents:** defer non-visible work, avoid full-document React/Flutter
  rebuilds and include a large-document fixture.
- **Dependency weight:** keep editor engines in editor-specific entry points and avoid
  loading them for consumers that never import an editor.

## Human gates

Plan approval and Decision 0007 acceptance authorize implementation of this exact
scope. Human Acceptance follows final verification and side-by-side gallery review.
Commit, push and publication remain separately authorized.
