# Hero detail sheets

Additive detail-sheet composition for an edge-to-edge map or image, floating
actions, scrolling body and fixed actions. Existing overlay defaults are unchanged.

## Web

`KResponsiveDrawer` accepts `hero`, `floatingActions`, `heroOverlays`, `footer`
and `inline`. Keep `title` for the accessible dialog name; a hero hides the
ordinary header. The system supplies the close action. With `inline`, the host
reserves `--k-layout-drawer-width` in its layout rather than covering the list.

Optional `detents={["half", "full"]}` and `initialDetent` enable phone snapping.
At the full detent the hero collapses and its media is inert; floating controls
remain available. The handle also toggles detents with a keyboard or tap.

## Flutter

`KAdaptiveSheet(title:, hero:, floatingActions:, heroOverlays:, footer:,
onClose:, child:, inline:)` uses `KBottomSheet`/`KSheetDrag` on phones and
`KSideSheet` on wider layouts. Open with `KAdaptiveSheet.show(context:,
builder:)`; for an in-flow tablet pane use `inline: true` and reserve the
`layoutDrawerWidth` token in the host layout. Passing no `onClose` disables
the close control and drag dismissal; route-level busy/back handling belongs
to the host.

The hero uses the 240-pixel layout token, body and footer use card insets.
Footers stay outside the body scroll and become independently scrollable if
they exceed half of the available height. This keeps actions reachable with
large text and error messages. Flutter detents are not implemented yet; its
default hero layout matches the Web layout without detents.

`KButton(tone: KButtonTone.destructive)` / `KButton tone="destructive"` provides
the filled error action. Existing button tone defaults remain unchanged.

Flutter `KDataTableSingleRow(selected: true)` uses the brand-tinted selection
surface and exposes the selected semantic state. `KListItem(tone:
KListItemTone.destructive)` colors its title and built-in leading icon with
the error token while leaving supporting text muted. Custom leading widgets
retain their own colors; prefer `leadingIcon` for destructive row actions.

## Review examples and evidence

- Storybook: `overlays-bookingdetails--booking-details`; optional Web detents
  have a separate example.
- Widgetbook: `Overlays / BottomSheet / booking-details`.
- Flutter `hero_sheet_test.dart`: phone/tablet, light/dark,
  100/130/200/300-percent text, fixed-footer scrolling, close, inline width,
  and a short viewport with a tall error footer.
- Visual device acceptance is performed by the consuming app; widget tests
  do not establish pixel-perfect real-device parity.
