# Decision 0007 — Collaboration-ready editor contract

> Status: **accepted for implementation**  
> Date: 24 September 2026  
> Scope: Markdown and code editor document, rendering and collaboration boundaries
> across Web and Flutter
> Human approval: 24 September 2026 — “Okay, ja, ich genehmige.”

## Context

K Design System needs a formatted Markdown editor and a code editor with matching
behavior on Web and Flutter. Both must support local editing without a collaboration
backend and allow consumers to connect CRDT state, remote selections and presence
without replacing the visual component.

The Bullets reference uses TipTap/ProseMirror with Yjs for structured content,
CodeMirror for source editing and a locally bundled Web editor inside Flutter. Its
contract correctly separates durable document updates from ephemeral presence.

## Decision

The component packages expose controlled editor state and transport-neutral
collaboration adapters. They do not own networking, persistence, authentication,
document rooms or user identity.

### Markdown editor

The canonical editable value is a structured rich document. Markdown is a supported
import, export and source-mode projection. This preserves headings, task lists,
marks, links, code blocks and concurrent structural edits. Exact preservation of
arbitrary Markdown spelling and whitespace is not promised after rich editing.

Web uses TipTap/ProseMirror. Flutter hosts the same locally bundled editor runtime
behind a typed bridge so document semantics, formatting commands and collaboration
positions stay equivalent. The bridge is an implementation detail; consumers use
Flutter-native models and callbacks.

### Code editor

The canonical editable value is text. Web uses CodeMirror 6. Flutter uses the same
locally bundled CodeMirror runtime behind the typed bridge. Language support,
highlighting, diagnostics and completions are capabilities supplied through the
public contract and remain optional.

### Collaboration boundary

Both editors expose local transactions, selection changes and focus changes. A
consumer-provided collaboration adapter can apply remote document updates and
render remote selections. Durable updates and ephemeral presence are separate.
Selections use stable relative positions when a CRDT adapter supports them; raw
offsets remain available for non-collaborative controlled use.

The first implementation includes an optional Yjs adapter for the Web runtime and
the embedded Flutter runtime. The core editor API does not expose Yjs types. Shared
undo/redo is adapter-owned, while local mode uses editor-native history.

### Customization and safety

Content, labels, toolbar actions, supported formats, language definitions,
diagnostics, completion providers, attachments and link intents are component API.
Appearance uses Decision 0005 tokens. HTML execution, arbitrary scripts, live code
execution and network-loaded editor assets are outside the editor contract.

The embedded runtime is packaged locally and communicates only through the typed
host bridge. Consumers may replace collaboration and language adapters but not
inject executable UI through document content.

## Alternatives considered

- **Markdown text as the rich editor source of truth:** preserves exact source but
  makes structured concurrent editing and stable formatting behavior substantially
  weaker.
- **Separate native Flutter editor engines:** avoids an embedded runtime but creates
  incompatible document schemas, cursor geometry and command behavior.
- **Expose Yjs directly:** reduces adapter code but makes the public design-system
  API dependent on one collaboration implementation.
- **Bundle transport and persistence:** produces a demo faster but prevents consumers
  from using their own sync, storage and authorization systems.

## Consequences

- Web and Flutter share editor semantics and can apply the same CRDT updates.
- Flutter carries a locally bundled editor runtime and platform-view integration.
- Native accessibility, keyboard, IME, clipboard and touch behavior require explicit
  cross-platform verification.
- Consumers that require byte-exact Markdown should use source mode or the code/text
  editor contract instead of round-tripping through rich mode.

Acceptance authorizes this contract for implementation. It does not authorize a
commit, push, publication, collaboration backend or data migration.
