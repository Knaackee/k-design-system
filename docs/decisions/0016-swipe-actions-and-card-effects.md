# 0016 – Swipe actions on list rows and KCard effects

Status: accepted (2026-11-11)

## Context

Apps built hand-made swipe rows and decorative card borders. Each looked
different per platform and broke under reduced motion, keyboard use and
text scaling.

## Decision

**Swipe actions** – `KListItem(leadingActions:, trailingActions:)` with
`KSwipeAction { id, label, icon, tone, fullSwipe, onSelect }`. The style
decides the behaviour; the app passes only the actions:

- `apple`: buttons behind the row (`component.swipeAction.width`), a short
  swipe opens them, a swipe past `fullSwipeThreshold` runs the `fullSwipe`
  action (iOS Mail).
- `material`: one coloured layer per side with the first action; past
  `revealThreshold` the icon grows and releasing runs it (Material 3
  swipe to dismiss). The app shows the undo snackbar.
- `linear` and keyboard: the same actions inline at the row end on hover or
  focus. Screen readers get them as custom actions in every style.

**KCard** – optional header (`leading`, `title`, `description`, `menu` as a
"…" trigger on the corner), footer `actions`, and `border`: `pulse` (needs
input), `spin` (working), `aurora` (AI input active), `flame` (critical),
`dashed` (drop zone, draft), `shimmer` (loading), `success` (one pulse).
`borderColor`, `borderColors` and `borderDuration` override the
`component.cardBorder.*` tokens per card. One animated border per screen;
every effect is static under reduced motion.

## Consequences

- Web and Flutter share tokens and are measured by the geometry parity gate
  (`card-header`, `list-swipe`).
- Flutter outlined list groups now place the hairline around the rows, like
  the Web border (rows no longer lose a pixel under it).
- Fixtures: Storybook `Data display/Swipe and card effects`, Widgetbook
  `Card/card-header`, `card-borders`, `card-border-playground`,
  `List/list-swipe`.
