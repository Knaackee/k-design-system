# Collaborative editors

The Web package exposes `KMarkdownEditor`, `KCodeEditor` and
`createKEditorCollaborationDocument` from `@k-design-system/ui/editors`.
The separate entry point keeps the editor engines out of consumers that only
use the core primitives.

`KMarkdownEditor` has one writable Markdown document and a derived read-only
preview. Its permanent and selection-driven format bars edit Markdown syntax
in the same CodeMirror/Yjs document. Collaboration therefore never has to
reconcile a second writable rich-text model.

`KCodeEditor` is text-canonical and supports plain text, JavaScript,
TypeScript, JSON and Markdown syntax, line numbers, wrapping, search,
diagnostics and consumer-provided completions.
Its default surface stays focused on the document: the language header, line
numbers and diagnostic gutter are opt-in, while search is available from the
compact floating action. Consumers can configure these regions independently
with `showToolbar`, `showLineNumbers`, `showDiagnosticGutter` and
`showSearchButton`. The search action is a pressed-state toggle while its panel
is open. `lineWrapping` lets consumers trade horizontal scrolling for wrapped
lines; Markdown source editing enables the same wrapping behavior by default.

The exported `KEditorSearchPanel` composes the shared search field, checkbox
and button primitives. The query occupies a full-width first row; navigation,
options, replace and close actions use a separate row that remains usable at
compact widths. Every label is part of the editor label contract.

Both components expose controlled value, selection and transaction callbacks.
Remote cursors accept participant identity, label, background color and an
optional accessible foreground color. The opaque collaboration document lets
the consuming application attach its own provider, room, authentication,
awareness and persistence without exposing Yjs types in the public component
contract.

In compact touch layouts, Markdown mode controls keep their own row. A compact,
permanent formatting dock stays available at the lower editor edge, while a
selection-driven floating bar keeps contextual actions close to selected text.
Visible format controls use the compact control token inside slots sized by the
configured hit-target token.
Its action rail is horizontally scrollable when the available actions exceed
the viewport. The code editor enables two-axis touch panning; consumers can
enable `lineWrapping` when code should remain within a phone viewport.
Storybook provides dedicated `markdown-editor-mobile` and
`code-editor-mobile` fixtures at 375 × 812 with touch input enabled.

```tsx
import {
  KMarkdownEditor,
  createKEditorCollaborationDocument,
} from "@k-design-system/ui/editors";

const document = createKEditorCollaborationDocument({
  id: "release-notes",
  kind: "text",
});

<KMarkdownEditor
  markdown={markdown}
  onChange={(next) => setMarkdown(next)}
  collaborationDocument={document}
  labels={{ source: "Markdown", read: "Preview" }}
/>;
```

The design system does not own rooms, network providers, permissions,
presence lifetimes or storage. Those remain application concerns. See
[Decision 0007](../decisions/0007-collaboration-ready-editor-contract.md) and
[Decision 0008](../decisions/0008-markdown-canonical-editor-model.md).

Flutter remains a separate implementation phase after the Web contract and
visual behavior receive human acceptance.
