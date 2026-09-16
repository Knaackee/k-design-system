# Forms and filters

Rapid scope approved on 2026-09-16: KField, KInput, KSearchField, KCheckbox,
KSelect, KCombobox, KFilterChip and KFilterBar on Web and Flutter.
Table and DataTable remain a separate user review.

## Contract

- Field supplies a visible label, optional helper or error, and required state.
  Errors replace helper text; validation belongs to the application.
- Input is single-line. SearchField adds a decorative search icon. Both support
  disabled and read-only states without changing layout.
- Checkbox supports checked, unchecked and mixed states.
- Select selects one local option. Combobox adds case-insensitive local search.
  Disabled options cannot be selected; Escape cancels the current search.
  Arrow keys navigate options and Enter commits a selection.
- FilterChip exposes a named removal action. FilterBar wraps at available width,
  preserves normal Tab order and optionally offers “Reset all”. The application
  owns filter state, option loading and queries.
- Controls use shared density, input-mode, color and typography tokens. Control
  leading is evenly distributed; Inter optical size follows scaled text size.
- Galeries use matching category, component and fixture names, sorted identically.

Allowed paths: both UI packages, both galleries and their tests, this document
and the component catalog. No dependency, token-axis or accepted ADR changes.

Flutter uses the native editable TextField semantics, with expanded, selected,
required and invalid metadata. The installed Flutter framework rejects an
explicit `SemanticsRole.comboBox` in debug assertions, so its Web accessibility
bridge exposes a textbox rather than the Web wrapper's ARIA combobox role.
This platform distinction is documented; screen-reader validation remains open.

Mixed checkbox state is supplied by the application. User activation changes
mixed/unchecked to checked and checked to unchecked on both platforms.
Selection popups dismiss when the surrounding page scrolls; their own option
list remains scrollable. Input placeholders remain single-line at enlarged text.

Form label and helper line boxes round the scaled control font size to the
nearest logical pixel on both platforms. This makes 125%, 150% and 175% layout
predictable; 100% and 200% spacing is unchanged. Editable controls use measured
font bounding metrics for their baseline, and placeholders use the same strut.
These rules apply only to the new form controls, not to existing typography or
buttons. Browser pixel checks cover both the painted input border and text ink,
not just the accessible control bounds.

Clear actions and option media were approved as a Rapid extension on 2026-09-16.
Input, SearchField, Select and Combobox expose `clearable` (default false) and
`clearLabel` (default "Clear"); consumers should supply a field-specific,
localized label. Clear is available only with content and an enabled, editable
value. A select-only field is still selectable and can be cleared when enabled.
Checkboxes retain their direct toggle action without another reset button.

On Web, controlled inputs and selection controls use `onClear` to let the
application empty its value. The existing `onValueChange(string)` selection
contract is preserved. Uncontrolled inputs clear their own DOM value and call
`onClear` when provided; clear does not synthesize an input change event.
Flutter calls `onChanged('')` for text and `onChanged(null)` for selections.
Clearing a combobox removes its selection and draft query, closes its options,
and returns focus to the field. Escape continues to cancel only the draft.

`KFilterBar.resetLabel` defaults to "Reset all" and `resetEnabled` to true.
Applications supply the enabled state and reset callback. Clearing means an
empty value; resetting may restore application-defined defaults. The gallery
uses an unfiltered default and disables reset when no filters are active.
Required ordinary form fields need not offer clearing; validation remains with
the application if clearing is intentionally enabled.

Selection options accept optional `icon` and `imageSrc`. Images take precedence,
use a fixed 16-pixel circular crop, and fall back to the supplied icon or a user
icon on load failure. Consumers own image URLs; galleries use local example
PNGs with identical bytes on both platforms. Media appears in options and the
committed selection; an editable combobox hides committed media while searching.
Media is decorative, while the required text label supplies search and accessible
naming. Option content contains no extra interactive controls.

Checks for this extension: targeted native and browser interaction tests for
clearing, focus, query cancellation, reset enablement and image fallback;
paired layouts including clear targets and enlarged text; and `pnpm verify`.

## Verification and acceptance

Run Web interaction tests and Flutter widget tests for naming, disabled and
read-only state, mixed state, selection, search/cancel, removal and reset.
Compare paired gallery layouts at phone, tablet and desktop widths, all three
densities and enlarged text, including control text alignment. Finish with
`pnpm verify` on the integrated state. Native device and screen-reader testing
are outside the available browser test environment; human visual acceptance is
separate from passing automated checks. No commit is part of this slice.

Verified on 2026-09-16: `pnpm verify` passed on the integrated implementation,
including 10 token tests, 127 UI tests, 16 Widgetbook tests, static checks and
both gallery builds. The additional Storybook TypeScript check and Web/Flutter
browser interaction checks passed.

The final browser comparison used the built Storybook and Flutter release
at widths 375, 700 and 1024, Dense/Standard/Spacious, text scales 100%, 125%,
150%, 175% and 200%, and pointer/touch input: 90 paired configurations passed,
including opened selection options. All 270 input paint and glyph comparisons
passed; the largest measured glyph-center difference was 0.425 logical pixels.
Option rows share the rounded line-height rule used by field labels and helpers.

Human visual acceptance and native device/screen-reader validation remain open.
Table/DataTable are excluded from this delivery.

### Clear and media extension: not ready for acceptance

The extension has a passing integrated `pnpm verify` (10 token tests, 135 UI
tests, 17 Widgetbook tests, analysis, formatting and both builds). Web browser
clear/reset/media tests pass. The layout comparison passed 90 configurations
including clear targets, with 270 input paint/glyph checks and a maximum glyph
center difference of 0.425px. Subsequent changes only adjusted clear focus and
icon color; final browser smoke checks cover the updated build separately.

Required browser check `node apps/storybook/src/forms-extensions-flutter.test.mjs`
still fails at the `focusReady('Search items')` assertion after clicking Clear
search. The value is empty, but browser DOM focus moves to `flutter-view` and
immediate keyboard input is lost. Native focus assertions alone did not detect
this. Field names and duplicate clear-button semantics have been corrected.
Two focused corrections did not resolve DOM focus restoration: a real editable
focus transition and bridging the clear button's semantics focus action to its
Flutter FocusNode. Further corrections are paused under the repository's
two-failed-corrections rule pending human direction; the remaining assumption
is how Flutter Web reconnects its editable DOM input after a disappearing
semantics button takes browser focus. Do not mark this extension accepted.

An independent Windows incremental-build issue removed font/avatar outputs
when build paths changed drive-letter case. The generated Flutter build cache
was reset and the regular `pnpm verify` build restored them. Browser parity now
checks the font manifest, Inter font and gallery avatars before measurement.
Use the root pnpm build commands consistently; do not compensate fallback fonts
by changing component typography.

## References

- [WAI-ARIA combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/)
- [Carbon text input](https://carbondesignsystem.com/components/text-input/usage/)
- Bullets: workspace-filter.tsx and its input/select wrappers; use the restrained
  presentation and responsive composition, without its domain query model.
