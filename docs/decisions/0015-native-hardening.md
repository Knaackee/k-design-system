# 0015 — Platform-native defaults reach every component

Status: accepted (November 2026)

## Context

Decision 0014 made the style preset platform-native, but only a few
components read it (list, page header, back button, app shell, tab bar).
Fields, buttons, sheets, breadcrumbs and icons kept the desktop look, so an
app migrated without overrides still looked like a web dashboard on phones:
36 px controls on iOS, heavy icons next to light text, desktop forms in
sheets, breadcrumbs that wasted two thirds of the width, and sheets that did
not follow the finger from their list or jumped back on dismissal.

## Decision

The style preset and the input mode decide appearance in every component;
app code passes content, events and state.

1. **Touch heights.** With touch input controls rise to the style's touch
   height (`size.controlTouch`: Apple 44 pt, the HIG minimum hit region;
   Material 40 dp), fields to `size.fieldTouch` (Material 56 dp) and a
   full-width button to `size.prominentTouch` (iOS 50 pt) with a centred
   label. Pointer input keeps the density heights.
2. **Icon stroke.** `size.iconStroke` is a screen stroke (Apple and linear
   1.5, Material 1.75) applied at every icon size (Lucide absolute stroke),
   so icons match the weight of adjacent text. Apps do not set
   `strokeWidth`.
3. **List rows.** A value sits beside the title when both fit on one line
   and moves under it otherwise (iOS `prefersSideBySideTextAndSecondaryText`);
   Material rows always show it as supporting text. Words are never broken.
   `mediaIcon` adds a tonal media tile and centres the row on it.
4. **Breadcrumbs** measure their width: all trailing levels that fit stay
   visible, the rest go into the menu (Adobe Spectrum); only the last label
   is shortened. On phones the back button carries the path
   (`backHistory`, long press), as the iOS back button does.
5. **Sheets** share one drag model (`KSheetDrag`): the sheet follows the
   finger from handle, header and from a list at its top; past a quarter of
   its height or on a fling it closes through `maybePop` and leaves from the
   release position; held back by `PopScope`, it settles back.
6. **Pages.** `KPage` gives every screen gutter, safe areas, a readable
   width (`layout.pageWidth`, `layout.formWidth` for sign-in and single
   forms) and section spacing. On phones `KAppShell` adds a bar that covers
   the status bar once content scrolls under it and takes the page title
   when the large title has scrolled away.
7. **Motion and shape.** Android pages use the Material 3 fade-forwards
   transition (predictive back); Apple buttons scale to 96 % while pressed;
   Material buttons morph to a squarer shape. `material` shows the M3
   segmented button (outlined pill, tonal selection with a check). Tablets
   in `apple` and `material` show a labelled sidebar instead of the
   icon-only rail.
8. **Scrolled top bar.** The bar keeps the page header's back control and
   actions while the header is scrolled away (iOS navigation bar): icon
   actions stay, text buttons and further actions move into a More menu.
9. **Icons grow with text.** Text-adjacent icons (16–24) scale with the
   system text size up to `text.scaleMax.icon` (2×), as SF Symbols do;
   tab bar symbols, glyphs inside fields and display icons keep their size.
10. **Gates.** `check-consumer-ui` reports `icon-stroke`,
    `appearance-override`, `hand-built-row` and `bare-page`. The workflow
    skill requires an inventory of every screen, sheet, dialog and menu with
    evidence.

## Consequences

- Phone layouts get taller controls; the phone gates and tests cover 100 to
  300 % text with them.
- `KBreadcrumb.iconStrokeWidth` is deprecated; `KIcon.strokeWidth` stays
  for library internals but is reported in app code.
- `KAdaptiveDialog` sheets no longer use `DraggableScrollableSheet`.
