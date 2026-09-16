# Actions and toolbar

The Rapid slice provides `KIconButton`, `KMenuButton`, `KOverflowMenu` and
`KToolbar` for Web and Flutter. It follows Bullets' compact action layout while
keeping product-specific commands and query state outside the component package.
Human visual acceptance remains separate from automated verification.

## Contract

- Icon buttons require an accessible label and use shared 16px Lucide vectors.
- Menu actions have a stable unique ID, label, callback, optional icon, disabled
  state, destructive tone and optional group separator before the item.
- These are commands, not value selectors. Select/Combobox, checkable entries,
  submenus and context menus are outside this slice.
- Overflow is an icon-only presentation of the same action menu. Applications
  explicitly supply overflow actions; viewport changes do not hide commands.
- Toolbars contain action buttons/menu triggers, wrapping in source order with
  the content-action gap for both rows and columns. Inputs, nested toolbars and
  independently focusable custom controls need a separate navigation contract.
- Toolbar navigation: one Tab stop, Left/Right in reading direction, Home/End,
  disabled-control skipping; Up/Down on a menu trigger opens its menu.
- Menu navigation: Up/Down, Home/End, label-prefix search, Enter/Space, Escape and
  outside dismissal. Selection and Escape restore trigger focus. Disabled actions
  never invoke callbacks. Icon trigger names belong to their button semantics.
- Menus are 240px wide, constrained by an 8px viewport margin at opening. Rows
  use the larger of control size and input-mode hit target. Text can wrap under
  scaling. Menu anchoring uses the trigger's full hit area on both platforms.
- Touch targets grow independently of visible control height: Dense controls stay
  32px tall inside a 48px hit area. Menu rows expose the complete touch target.
- Surfaces, shadows, separators, focus colors, spacing, radii and typography use
  existing tokens. Opening a menu focuses its first enabled entry on both
  platforms, including opening by pointer.

## Implementation and scope limits

Web uses the browser Popover API for the top layer and light dismissal, with
explicit positioning and keyboard handling; Popover support is required and no
legacy-browser fallback is implemented. Flutter uses MenuAnchor/MenuItemButton
and the shared KSurface wrapper. Native APIs remain internal. No new dependencies
or token axes were introduced. The internal menu surface is not a public Popover.

The menu keyboard controller and toolbar cooperate so Material's menu shortcuts
cannot consume horizontal toolbar navigation. The touch target uses Material's
input padding, without imposing the larger height on the painted control.

Raster antialiasing can differ despite matching geometry. Browser viewport tests
cover Flutter Web, not native iOS/Android execution. Native screen readers,
virtual keyboards, safe-area cutouts and long menus near viewport edges still
need device-specific acceptance before release to those environments. Automatic
overflow redistribution and advanced menu interaction are outside this slice.

## Gallery fixtures

| Folder in both galleries | Fixture ID and visible name |
| ------------------------ | --------------------------- |
| Actions / IconButton     | icon-button-actions         |
| Actions / MenuButton     | menu-button-actions         |
| Patterns / Toolbar       | toolbar-actions             |

Both trees use the same case-insensitive alphabetical sorting. Existing gallery
URLs remain stable. Bullets reference paths and subsequent families are recorded
in the [component catalog](../component-catalog.md).

## Verification

Commands for the final integrated state:

- `pnpm verify`: formatting, generated artifacts, tooling tests, Web build and
  types, all Flutter analysis/tests, and both production gallery builds.
- `flutter test test/action_components_test.dart` in the UI package: 14 focused
  tests, including keyboard/focus, disabled actions, outside dismissal, responsive
  layout at 200%, accessible icon-button names and separate touch/paint geometry.
- `node apps/storybook/src/actions.test.mjs`: actual browser interactions and 12
  responsive Web cases at 200% text.
- `node apps/storybook/src/actions-parity.test.mjs`: 36 paired configurations at
  widths 375/700/1024, all three densities, pointer/touch, Orbit Light at 100% and
  Reference Dark at 200%. It compares toolbar hit rectangles and menu rows with a
  0.5px tolerance and captures open/closed screenshots.

Browser scripts require `KDS_PLAYWRIGHT_MODULE` when Playwright is not in the
normal module path; the parity script also requires `KDS_PARITY_OUTPUT`. Evidence
is written there as `results.json`, `differences.json` and paired PNG screenshots.
Direct Codex browser automation was unavailable due to Windows error 206; browser
checks use local headless Edge against the same running gallery servers.

The earlier stopped focus correction was explicitly authorized to continue by
the user. Its missing navigation method, shortcut conflict and the subsequent
semantics/touch defects were corrected and regression-tested. No protected
Plan/ADR bodies were changed. No commit or push is authorized for this slice.

Final verification on 2026-09-16: `pnpm verify` passed. All 14 focused Flutter
checks, Web interaction checks and 12 Web responsive cases passed. All 36 paired
configurations passed the 0.5px geometry tolerance. Shared menu shadows, focus,
separators and touch appearance were inspected in paired screenshots. Evidence is
stored in the session's `actions` visualization directory (`verification.json`,
`results.json`, `differences.json`, `verify.log` and PNGs). Human visual acceptance
and native-device/screen-reader checks remain pending. No commit was made.

Control typography follow-up: user review revealed a one-pixel upward shift in
Flutter button glyphs despite matching outer rectangles. Flutter controls now use
`TextLeadingDistribution.even`, matching CSS half-leading; Web remains unchanged.
The screenshot-based `control-typography.test.mjs` compares actual glyph contrast,
vertical ink centroids and ink height for primary buttons and menu triggers. It
rejects the earlier images (up to 1.098px centroid difference). Run it after
`actions-parity.test.mjs` against the same `KDS_PARITY_OUTPUT` directory. The
regression allows 0.45px centroid difference and one raster pixel of ink-height
variation, accounting for browser/CanvasKit antialiasing rather than hiding a
whole-pixel baseline shift.

The corrected build passed `pnpm verify`, all 36 geometry pairs and 72 glyph
comparisons. An additional Orbit Dark / Dense / 100% case (set
`KDS_PARITY_REVIEW=1` for the geometry capture) passed both geometry and its two
glyph comparisons. Maximum vertical ink-centroid difference across the 74 checks:
0.127px. The original Dense glyph bounds now match at rows 67–76 on both platforms.
Fresh evidence lives in `actions-type-corrected` and `toolbar-review` beside the
earlier `actions` evidence. Exact raster equality is not claimed.
