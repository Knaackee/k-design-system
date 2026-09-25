# Decision 0008 — Markdown-canonical editor model

> Status: **accepted for implementation**  
> Date: 25 September 2026  
> Scope: Markdown editor modes and collaborative source of truth  
> Human approval: 25 September 2026 — “ok” after the explicit recommendation to
> remove the rich Edit mode and retain one writable Markdown model plus Preview.

## Context

Decision 0007 selected a structured rich document as the canonical collaborative
state and treated Markdown as an import/export boundary. The first Web slice then
exposed both rich Edit and Markdown source as writable modes. Supporting both would
require lossless bidirectional conversion while preserving collaborative cursors,
relative positions, undo history and exact Markdown syntax.

## Decision

`KMarkdownEditor` exposes one writable Markdown document and a derived read-only
Preview. CodeMirror binds that Markdown text directly to the consumer-provided Yjs
document. Fixed and contextual formatting controls transform Markdown syntax in
the same document.

A future Live Preview may change how Markdown is rendered around the cursor, but it
must remain a presentation of the same text editor and CRDT state. It must not add
a second writable rich-text document.

This decision supersedes only the rich-document canonicalization and
rich/source/read mode portions of Decision 0007. Its transport, presence,
persistence and package-boundary decisions remain accepted.

## Consequences

- Exact Markdown spelling and whitespace remain stable unless the user edits them.
- Cursor, selection, undo and remote-update semantics have one authoritative model.
- Preview cannot mutate the document.
- Formatting commands operate through Markdown transformations.
- Consumers persist the same Markdown value used during collaboration.
