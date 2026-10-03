# Dictation controls

`KInput` and `KTextarea` accept an optional `trailingAction` (`ReactNode` on Web,
`Widget` on Flutter). Input places it at the end beside the clear control;
Textarea reserves a bottom row and places it at the bottom right. These slots
are intended for one icon action. Disabled and read-only fields hide the action;
password / concealed inputs also hide it.

`KDictationAction` is exported on both platforms. It takes a `KDictationState`,
a required accessible `label`, and an optional `onPressed` callback. Consumers
supply localized labels appropriate to the state, such as “Start dictation”,
“Stop dictation”, “Transcribing”, or “Retry dictation”.

| State         | Visual                    | Activation        |
| ------------- | ------------------------- | ----------------- |
| `ready`       | Microphone                | Consumer callback |
| `recording`   | Stop, selected appearance | Consumer callback |
| `processing`  | Progress                  | Disabled          |
| `unavailable` | Microphone off            | Disabled          |
| `error`       | Alert                     | Consumer callback |

No callback also disables the action. The action uses existing icon-button
semantics, keyboard support, focus appearance and token-defined hit targets.
Recording pulses the stop control; processing displays animated progress on both
platforms, respecting reduced motion. Neither platform starts a microphone, requests permission,
transcribes, edits text, or interprets errors. The host owns all those behaviors
and any status/error text associated with the field.

Matching galleries use fixture ID `dictation-controls` under Forms/Dictation.

Fields accept optional `dictationState` and `dictationOffset` for a decorative
three-dot insertion anchor. The host captures the cursor before starting audio.
`KDictationAnchor` is shared by fields and Markdown editors; Web also exports
`createKDictationAnchor` for editor decorations. Anchors never modify content.

Markdown editor fixture `markdown-editor-dictation` demonstrates start, stop and
cancel on both platforms. Flutter exposes `KMarkdownEditorState.selection` and
`insertDictation(text, selection: ...)`; collaborative hosts supply mapped ranges.
Web accepts optional `dictation` callbacks. Rich collaborative hosts can pass
their existing Tiptap `richEditor`, toolbar and presence overlay, preserving the
same document and transport. Install `KEditorDictationExtension` and use
`beginKEditorDictation`, `insertKEditorDictation`, `cancelKEditorDictation`.
The extension uses Tiptap's mappable positions, including Yjs-relative anchors.
Read-only/preview modes hide capture controls. There is no public CodeEditor
dictation API. Failed insertions return false; hosts retain the transcript.
