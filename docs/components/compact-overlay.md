# Compact overlay scroll contract

Review candidate, 2026-11-04. Local consumer integration was explicitly authorized and applied in Assetry;
Human Acceptance of the complete visual migration is not claimed. Prepared on `codex/compact-sheet-fixed-actions` from published
`54e10296382a9dd35709cec62fc1a9372fc0d174` for the Assetry visual alignment request.

Flutter `KDialog`, `KBottomSheet` and compact `KAdaptiveDialog`
(`expandBody: false`) keep the title, description and actions outside the body
scroll view. Short content determines the surface height. Constrained content
scrolls within the remaining space; the actions stay visible. The bottom-sheet
show helper reserves the software keyboard inset for compact content too.
Expanded/page-sheet layout and controlled dismissal remain unchanged.

This brings Flutter's compact layout into line with the existing Web overlay
header/body/actions structure. No new public props or tokens are introduced.
Callers still own actions, fields, validation and dismissal decisions. Body
content should not add an independent vertical scroll owner.

Matching gallery fixture: `compact-sheet-fixed-actions`. Storybook:
`overlays-bottomsheet--compact-fixed-actions`. Widgetbook: Overlays → BottomSheet
→ compact-sheet-fixed-actions. Toggle Long form, open the sheet, scroll fields,
focus inputs, cancel/save and reopen. Gallery Save only reports local demo state.

Verification: 27 focused Flutter tests passed (compact overlay, existing overlay
and page-sheet suites). The new matrix covers all three densities, 1.0/1.8 text,
light/dark, dialog/sheet, keyboard inset, fixed header/actions and dismissal.
Full pnpm verify passed, including package tests, analyzers, Web/Flutter consumer
checks and release gallery builds. Web and Flutter short/long fixtures were
visually checked, including scrolling, dismissal and light/dark appearance.
Assetry also verified the compact actions with a real Pixel software keyboard.

The user explicitly authorized local integration of this unpublished candidate
in Assetry. The submodule commit pointer remains unchanged. No commit, push or
deployment is authorized. Full verification log: .dart_tool/compact-overlay-verify.log.
