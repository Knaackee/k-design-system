# Page sheet — Web review

Approved scope: a Web-first Apple-style page presentation for visual review in
Storybook. Flutter implementation follows separate visual acceptance. Existing
bottom-sheet callers retain their content-sized presentation.

`KPageSheet` reuses `KBottomSheet` (Radix focus/modal semantics and the installed
`react-modal-sheet` gestures, scrolling and keyboard avoidance). It adds a tall
presentation and requires `presentationRootId`: the ID of a dedicated,
viewport-sized application surface. The sheet portal must be outside that
surface. Scroll the application inside the surface, not the document body.

Content, title, description, actions, close label, open state and dismissal are
consumer-owned through the existing overlay props and `onOpenChange`.
`dismissible={false}` prevents gesture, backdrop and Escape dismissal.

The application recedes in proportion to the actual sheet position, including
interactive dragging and closing. Inset uses `--k-space-layout-gutter`; corners
use `--k-radius-overlay`. Original inline styles are restored after closing or
unmount. No document theme is overwritten. Reduced-motion behavior comes from
the existing sheet adapter. Use a dedicated surface without an existing visual
transform. Concurrent sheets targeting the same surface are not supported in
this first review slice.

Story: `overlays-pagesheet--app` / fixture `page-sheet-app`.
Includes an editable project name, long scrolling content and controlled actions.

Source: https://github.com/Temzasse/react-modal-sheet#-ios-modal-view-effect
The upstream modal effect hardcodes presentation values and changes body styles;
our adapter subscribes to its public motion value instead, using design tokens.

Verification: browser checks confirmed the receding surface, internal scrolling,
drag dismissal, style restoration and focus return to the opening button.
Full repository command and output: `pnpm verify`,
`.dart_tool/page-sheet-verify.log`. Final status is recorded at handover.

Flutter parity and real-device software-keyboard testing remain outside this
Web review. No claim of verified cross-platform pixel parity is made yet.
