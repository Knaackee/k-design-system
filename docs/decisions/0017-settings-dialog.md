# 0017 – Settings dialog, save bar and avatar picker

Status: accepted (2026-11-12)

## Context

Apps configured one object (an agent, a resource, a workspace) in a modal
with five or more tabs squeezed into one row, one save button per section,
a second dialog on top for name and look, status messages as plain text and
cards nested inside cards. On phones the same modal became a bottom sheet
with even less room for the tabs.

## Decision

**`KSettingsDialog`** (Flutter) / **`KSettingsDialog`** and
**`KSettingsDialogPanel`** (Web) take sections
`{ id, title, group, icon, description, summary, status, dirty, content }`:

- From 600 px wide: a dialog of `component.settingsDialog.width` ×
  `height` with a header (leading, title, subtitle, `headerAction`, close),
  a sidebar navigation (`navWidth`, grouped, icon, status or unsaved
  marker) and the open section (`contentPadding`).
- Below 600 px: a 90 % bottom sheet. The first page lists the sections in
  grouped `KList`s with their `summary`; a section opens as a page with
  „Back“ in the header.
- `status` (`warning`, `error`) marks a section; the section explains the
  problem with a `KAlert` and its action. `dirty` shows an accent marker.
- One `footer` for all sections, normally `KSaveBar`.

**`KSaveBar`** – „All changes saved“ or „N unsaved changes“, Discard and
Save. Below 360 px or from 1.3× text the state sits above the buttons.

**`KAvatarPicker`** – shape tiles (`tileWidth`) with app-drawn icons and
colour swatches (`swatchSize`). The app shows the result in the header.

**`KSettingsRow` in a `KList`** takes the list's row inset, so settings
groups are lists with hairlines instead of cards in cards.

## Consequences

- Rows inside sections use `KList` + `KSettingsRow`, problems `KAlert` with
  `action`, technical details `KDisclosure`. No per-section save buttons,
  no dialog on top of the dialog.
- Geometry parity covers `save-bar`, `avatar-picker` and `settings-group`.
- Fixture `settings-dialog` (Storybook and Widgetbook) is the reference.
