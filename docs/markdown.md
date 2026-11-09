# Markdown

## Scope and review status

The approved phased work is recorded in
[markdown-optimization.md](plans/markdown-optimization.md). The user authorized
completion of the core Markdown work for gallery review on 2026-11-09.

The existing editor and collaboration engines are retained. The shared renderer
is used by document previews, editor previews and chat. Streaming and editor
hardening extend that same contract; no second editable rich-text model is added.

**Consumer decision:** the CRDT engine and transport remain the consuming app's
responsibility. Flutter's adapter is hardened and demonstrated, but a built-in
native Yjs-compatible engine is not part of this delivery. Web's existing Yjs
integration remains available. Adapter tests do not prove Web/Flutter wire-level
interoperability. Human visual acceptance in both galleries remains separate.

## Composition

Document -> `KPage` -> `KMarkdownPreview` -> `KMarkdownRenderer`.
Chat preview -> `KPage` -> `KMarkdownRenderer` with the `chat` profile.
The profiles change semantic heading hierarchy and spacing, not the global
density, input mode or type scale. Layout uses existing page and section roles.
Links use K link semantics; code/table actions use K buttons; task indicators
remain read-only. Native renderer elements are library internals, not permission
for consumers to bypass K controls.

### Editor and chat integration

`KMarkdownEditor.markdownOptions` and `KChatConversation.markdownOptions`
forward element policy, image resolution, selection, copy and localized labels.
Flutter uses `KMarkdownOptions`; Web uses a typed subset of renderer props.
Source, presentation profile and streaming state remain wrapper-owned.

Existing top-level link/image callbacks take precedence over options. Links do
not navigate implicitly; copy controls require `onCopy`. Host callbacks own
routing, clipboard access and feedback. Chat's optional
`userMarkdownAllowedElements` reduces only user-message content; assistant
messages retain their policy. Chat selection defaults use input mode instead of
assuming every narrow window is touch-only; consumers can explicitly override it.

Both platforms use standard Markdown paragraph flow for soft line breaks. The
editor/chat integration fixtures share `basic.md` and own their scrolling and
insets without duplicate page gutters. The editor begins in preview and can
switch to source. The streaming fixture retains message/part identity across
steps; the host decides whether to follow incoming text.

## Shared public contract

| Capability               | Web                                                       | Flutter                                                     | Ownership                                                       |
| ------------------------ | --------------------------------------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------- |
| Source                   | `content`                                                 | `content`                                                   | Consumer Markdown string                                        |
| Presentation             | `profile: document / chat`                                | `KMarkdownProfile.document / chat`                          | Semantic roles, same adaptive axes                              |
| Streaming                | `streaming`                                               | `streaming`                                                 | Shared deterministic block-boundary policy                      |
| Element policy           | `allowedElements`                                         | `allowedElements`                                           | HTML tag-name allowlist; supported defaults when omitted        |
| Link activation          | `onLinkActivate(string)`                                  | `onLinkActivate(Uri)`                                       | Host routing; no implicit navigation                            |
| Images                   | `renderImage({src, alt, title})`                          | `imageBuilder(Uri, alt, title)`                             | Host resolution of relative/private images                      |
| Selection                | `selectable`                                              | `selectable`                                                | Host override; chat defaults resolve input mode                 |
| Copy                     | `onCopy`, labels                                          | `onCopy`, labels                                            | Host clipboard and feedback; opt-in actions                     |
| Preview width/states     | `contentMaxWidth`, loading/empty slots                    | Equivalent properties                                       | Host composition                                                |
| Editor source/mode       | `markdown`, `mode`, `onChange`, `onModeChange`            | `markdown`, `mode`, `onChanged`, `onModeChanged`            | Controlled or default source/read mode                          |
| Link request             | `onLinkRequested(selection)`, `linkLabels`                | `onLinkRequested(selection)`, `KEditorLabels` link fields   | Host hook overrides default K form; null cancels                |
| Editor size              | `contentMaxWidth`, `minHeight`                            | Same intent                                                 | Host available-space constraint                                 |
| Toolbar                  | `formatActions`, fixed/floating visibility                | Same intent                                                 | Optional actions; tokenized targets                             |
| Read-only/search/history | `readOnly`, source editor handle                          | `readOnly`, public `KCodeEditorState`                       | Public mutations respect read-only                              |
| Source editor access     | `sourceEditorRef`                                         | `GlobalKey<KMarkdownEditorState>.currentState.sourceEditor` | Public wrapper handle; no private engine access needed          |
| Focus/selection          | `onFocus`, `onBlur`, `onSelectionChange`                  | `onFocus`, `onBlur`, `onSelectionChanged`                   | Consumer events                                                 |
| Dictation                | `dictation` state/level/start/stop and insertion callback | State/level/action props and `insertDictation`              | Host recording, transcription and permission                    |
| Collaboration            | Existing optional Yjs document/transport                  | Consumer `KEditorCollaborationAdapter`                      | Engine and transport remain consumer-owned                      |
| User-message policy      | `userMarkdownAllowedElements`                             | Same property                                               | Optional user-only policy; does not restrict assistant messages |

Additive renderer/editor APIs preserve existing integrations. Web imports public
`@k-design-system/ui/markdown` or the main entry, with the normal package styles;
editors use `@k-design-system/ui/editors`. Flutter exports through
`package:k_design_ui/k_design_ui.dart`.

Intentional platform seams: Web's existing Tiptap rich-host slots are optional
host integration, not a second shared Markdown editing mode. Flutter accepts
arbitrary widget composition around its editor instead. Flutter's optional
format-bar minimum extent is an additional constraint; ordinary control sizing
on both platforms remains governed by tokens. Neither platform requests
microphone permission or owns transcription. There is no claim that Web Yjs
binary transport and Flutter's consumer snapshot adapter are the same engine.

## Rendering policy

- Styles resolve existing K tokens; no new generator or parallel density system.
- Tables retain Markdown alignment, use horizontal separators and local horizontal
  scrolling. The page itself must not overflow because of a wide table.
- Code keeps whitespace and scrolls within its own region. Unknown languages fall
  back to readable plain code. Copy callbacks receive source text, not highlighted
  markup.
- HTTP(S) and relative links/images are allowed; `mailto` is link-only.
  Executable schemes must not reach either activation callbacks or image builders.
- Raw HTML is not an executable styling channel. Cross-platform omission and
  element filtering are covered by renderer tests.
- Copy controls, external navigation and private image resolution are opt-in
  consumer integration points. The library never requests microphone access here.

## Review fixtures

The source of truth is `fixtures/markdown/`. Web imports the files directly;
Flutter bundles the same files as assets. Generated Flutter asset copies are
ignored, not a second source.

| Gallery name (both platforms)                      | Source / purpose                                   |
| -------------------------------------------------- | -------------------------------------------------- |
| `renderer-document`                                | `basic.md`                                         |
| `renderer-chat`                                    | `chat-reply.md`                                    |
| `preview`                                          | `long-document.md`                                 |
| `tables`, `code`, `alerts`, `images`, `edge-cases` | Corresponding `.md` files                          |
| `editor-integration`, `chat-integration`           | `basic.md` through real wrappers                   |
| `streaming`                                        | `streaming-sequence.json`, ten deterministic steps |
| Forms/Editors `markdown`, `markdown-mobile`        | Editing without enabled dictation                  |
| Forms/Editors `markdown-read-only`                 | Selection/search without document mutation         |
| Forms/Editors `markdown-editor-dictation`          | Consumer-driven simulated speech UI                |
| Forms/Editors `editor-collaboration`               | Consumer-owned two-peer adapter boundary           |

The image fixture includes relative and missing images. Link activation reports
the URL without leaving the gallery. Copy sends the source payload to a consumer
clipboard handler. Demos use simulation where explicitly labelled; they do not
imply a microphone, backend or native CRDT service.

For shared documents prefer LF source on both platforms. Web's CodeMirror handle
reports UTF-16 offsets in its LF-normalized view; Flutter's adapter reports UTF-16
source offsets. If a host preserves CRLF, it must map these positions at the
adapter boundary (Yjs's internal Web binding already maps document edits).
Engine-neutral source/presence ownership is not a promise of identical engine APIs.

## Remaining phases

### Streaming

Both adapters use `fixtures/markdown/streaming-sequence.json` with the same
incremental contents and completion flag. While `streaming` is true, a trailing
unfinished paragraph/link/table remains literal and noninteractive. A complete
blank line commits the block. Confirmed top-level fenced code is rendered as
code while it grows; a valid closing fence commits it. Finishing the stream
renders the original input through the normal static pipeline. No fake closing
syntax is written back to the consumer's document.

This conservative policy intentionally delays inline formatting until the block
boundary. It avoids transient broken tables and actionable incomplete links.
Committed content is cached where possible; growing code still needs reparsing.
The renderer does not force scrolling or announce every chunk to screen readers.
The host retains scroll/follow-new-message policy.

### Editor and adapter hardening

Link insertion and link activation are separate operations. The default insertion
form uses K dialog, field, input and buttons; localized labels and a consumer
request hook are supported. A cancelled or stale request does not mutate the
current selection/document. The source editor remains the only editable model.

Controlled prop updates do not generate local-change echoes. Remote document
notifications carry `origin: remote`; consumers must not send them back as local
edits. Presence-only notifications are not document transactions. Flutter's
snapshot bridge clears incompatible local undo history when remote text replaces
the value, preventing Undo from erasing peer edits. This is a safety boundary,
not collaborative engine-level undo.

The consumer owns the collaboration engine, transport and presence lifecycle.
For a native CRDT adapter, supply a converged snapshot and resolved UTF-16
selection offsets. Preserve local/remote origins and implement local-origin undo
in the chosen engine; never use full-value history as a CRDT merge algorithm.
Web's optional Yjs transport exchanges binary updates/state vectors. Seed a shared
document once; independent nonempty initial documents merge as separate inserts.
Joiners must receive the authoritative seed/update rather than seed it again.

Matching editor-collaboration demos exercise the UI contract. The Flutter demo
is an explicitly labelled in-memory consumer adapter, not proof of a Yjs wire
protocol. Web tests additionally cover two independent Yjs replicas, offline
changes, reconnect, duplicate delivery and local undo preserving peer changes.

### Remaining acceptance and explicit limits

The core is presented for the user's Storybook and Widgetbook review. Optional
TOC/anchor navigation and split-view from phase 6 remain separately prioritized,
as specified in the approved plan. Neither is required for the repaired core.

Native build attempts for the same renderer/editor smoke harness are blocked by
unrelated platform dependencies: Android `maplibre_android` cannot resolve its
unversioned `org.jlleitschuh.gradle.ktlint` plugin; Windows compilation fails in
`audioplayers_windows` with MSVC C1001 in `winrt/base.h`. No dependency-cache,
platform-build or visual-baseline workaround is included in the Markdown change.
Consequently native Android/iOS/Windows visual acceptance is not claimed. Logs:
`.dart_tool/markdown-native-build.log`, `.dart_tool/markdown-windows-build.log`.

## Implementation evidence (2026-11-09)

Verified working tree on `main`, based on `9f9e942`; no commit or push requested.

- `pnpm verify` completed successfully with Flutter 3.47.9: package builds,
  consumer checks, analysis, package/gallery tests, Flutter phone gate,
  Storybook production build and Widgetbook release/font checks.
- Full Flutter UI tests: 881 passed. Focused final editor/renderer regressions
  also cover remote origins, readonly, link selection and nested phone dialogs.
- Web browser regressions: four passed, including real independent Yjs replicas,
  offline/reconnect/local undo, link insertion and stable streaming/chat scrolling.
- Web phone gate: 482 stories, zero overflow and load failures, 40 skipped.
- Flutter phone gate: 433 use cases, zero overflow, 39 skipped and 22 non-layout
  errors in other components. These are not claimed as functional passes.
- Geometry gate: six configurations, ten reference entries, zero differences
  above 1px. This does not prove equality of every Markdown glyph.
- Visual review at 390px checked source/preview, shared font and content insets,
  table width, chat gutters and localized link dialogs. The Flutter link dialog
  now stays inside the simulated phone viewport.
- Final logs: `.dart_tool/markdown-final-verify.log`,
  `.dart_tool/markdown-final-web-phone.log`, `.dart_tool/markdown-final-geometry.log`,
  `.dart_tool/markdown-final-browser.log`. Screenshots: `.dart_tool/markdown-proof/`.

The consumer owns the CRDT engine, as explicitly chosen by the user. The Flutter
collaboration fixture demonstrates adapter behavior, not native Yjs convergence.
Flutter chat defaults to nonselectable text in touch mode and selectable text in
pointer mode; Web retains native browser selection. Consumers can override this
platform gesture default.

Review `editor-integration`, `chat-integration`, `streaming` and
`editor-collaboration` in both galleries. Core implementation is ready for human
review. Native Android/iOS/Windows visual acceptance remains outstanding for the
build blockers documented above. Optional TOC and split-view remain outside this
core slice. No claim of exhaustive pixel equality or native release readiness is
made.
