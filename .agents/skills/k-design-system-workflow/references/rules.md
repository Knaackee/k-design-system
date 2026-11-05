# Hard rules (Decision 0010)

Rules marked **gate** are checked by `tooling/check-ui-rules.mjs` and debug
assertions. The others are review rules.

## Cards — gate

- A card never contains another card (`KCard` asserts in debug on Flutter and
  logs on Web).
- Inside a card: separators, a grouped list, a `KStack` section, or a subtle
  surface without border for tiles (`KSurface(tone: subtle, border: none)`).
- One deliberate inset per card. Title, fields and actions share the inset
  edge.

## Leading visuals — gate

- Icons, checkboxes, radios, status dots and small avatars beside text sit on
  the optical centre of the **first text line**.
- Flutter: `Row(crossAxisAlignment: start)` + `KLeading(size, textVariant)`.
  Web: `.k-leading` (uses `1lh`) or the component's built-in alignment.
- Media tiles and avatars at least two lines tall may centre on the block.
- A trailing control (switch, chevron, button) in a row may centre.

## Icons — gate

- Text-adjacent icons: 16 (small/label), 20 (body), 24 (headings, toolbars).
- 12 only for glyphs inside a control (checkbox tick). 32/48 for display
  (empty states, markers). Nothing else.

## Spacing — gate

- Tokens only in library code; consumer/gallery literals only on the 4 px grid
  (2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64).
- Roles: `control` gap within a group, `action` gap before actions, `section`
  gap between groups, `layoutGutter` for page edges, `cardPadding` inside cards.
- Phones: gutter 16, section gap 24, card inset 16. Do not re-create these
  numbers; they come from the resolved window class.

## Typography — gate (size), review (roles)

- Minimum 11 px. Use `KText` variants, never ad-hoc sizes.
- At most three sizes per screen (title, body, small) plus weight.
- Phones use the `mobile` ramp (H1 28/34, body and inputs 16). It is chosen
  by the resolver; do not force `standard` on phones.

## Text scaling — review + phone gate

- System text scale is capped per role: headings 2.0, controls and body 3.0.
  From 1.3× rows stack (Flutter automatically; Web via `setKTextScale`).
- Every screen must work at 1.3 (common Android default) without clipping
  and up to 3.0 with scrolling. Both phone gates fail at any scale up to 3.0.
  Pages scroll; fixed-height containers hold only single-line, truncatable
  text. Stages and previews use `minHeight`, never a fixed `height`.
- Text + trailing value/action rows: from 1.3× the trailing part moves under
  the text (Flutter `MediaQuery.textScalerOf(context).scale(1) >= 1.3`, Web
  `[data-text-large]`). Action rows wrap (`Wrap`, `KInline(wrap: true)`).
- Headers of dialogs and full-screen sheets scroll with the content at large
  text; chart axes show fewer ticks instead of shrinking them.
- Long words break instead of overflowing (Flutter does this natively; Web
  `.k-text` uses `overflow-wrap: break-word`).

## Wrapping — review + phone gate

- A row with a label and a value, badge or button must wrap or flex:
  `KInline(wrap: true)`, `Flexible`, or stack below 440 px.
- Titles truncate with an ellipsis; numbers, prices and dates never truncate.
- Badges never shrink titles; on compact windows they move to the next line.

## Narrow windows — phone gate (Web and Flutter)

- Every component must fit 360 px on both platforms. A wide widget (board,
  table, timeline) scrolls inside its own container; the page never scrolls
  sideways. A grid or flex parent of such a widget needs `min-width: 0` /
  `minmax(0, 1fr)` on Web. Components with many items degrade
  (pagination → "page / count", toolbars → overflow menu, chips → wrap).

## Lists — review

- Items of the same kind are rows in one grouped list, not one card each.
- Row anatomy: leading (optional) · title · subtitle/meta · trailing.
  Minimum height 56 for touch, 40 for pointer.
- Empty group: a single action row "+ Add …", not a sentence plus a button.

## Navigation — review

- Phone main navigation: bottom tabs (≤ 5) or drawer; contextual details in a
  bottom sheet; desktop keeps sidebar and secondary navigation visible.
- Back affordance names the parent ("‹ Portfolios"), never just "Back".
- Section switching is rows, tabs or a segmented control — never a dropdown.

## Forms — review

- Group fields under short section headings; pair short numeric/date fields
  side by side; units inside the field as suffix.
- Required errors appear at the field, scrolled into view on submit.
- Sticky footer with primary action in sheets; discard confirmation for dirty
  forms. A dependency that does not exist yet offers "Create …" inline.

## Status — review

- Status is text + colour (badge), never colour alone. Dates are relative or
  locale-formatted, never ISO strings.
