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
- Never set `strokeWidth`. The style's `size.iconStroke` draws the same
  screen stroke at every size (Apple and linear 1.5, Material 1.75), so a
  16 px and a 24 px icon look equally heavy next to text (Decision 0015;
  `check-consumer-ui` › icon-stroke).

## Defaults — gate (Decision 0015)

- App code passes content, events and state. Style, density, type scale,
  motion, control heights, radii and icon strokes come from the resolved
  style; `KAdaptiveOverrides` for them only for a product decision the
  person made (`check-consumer-ui` › appearance-override).
- A look that does not fit without an override is a library gap: report it
  with a screenshot instead of patching it in the app.

## Touch targets — review + tests (Decision 0015)

- Touch input raises every control to the style's touch height: Apple 44 pt
  (HIG minimum hit region), Material 40 dp buttons and 56 dp fields inside
  a 48 dp target. A full-width button is the screen's call to action:
  centred label, 50 pt on iOS.
- Do not shrink controls back (no `minHeight`, `height`, dense density on a
  phone). On a tablet or desktop with a pointer the density's own heights
  apply.

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
- Titles wrap by default and never break inside a word. Truncate with "…"
  only where the person asked for one line (`titleMaxLines: 1`), e.g. a
  list of names; numbers, prices and dates never truncate.
- A list row's value sits beside the title when both fit on one line and
  moves under it otherwise (iOS value cell); Material rows always show it
  under the title. Do not cap or truncate the value to force one line.
- Badges never shrink titles; on compact windows they move to the next line.

## Narrow windows — phone gate (Web and Flutter)

- Every component must fit 360 px on both platforms. A wide widget (board,
  table, timeline) scrolls inside its own container; the page never scrolls
  sideways. A grid or flex parent of such a widget needs `min-width: 0` /
  `minmax(0, 1fr)` on Web. Components with many items degrade
  (pagination → "page / count", toolbars → overflow menu, chips → wrap).

## Lists — review

- Items of the same kind are rows in one grouped list, not one card each.
- Use `KList` + `KListItem`: leading (optional, on the first title line) ·
  title · description · value (beside the title when it fits, else under
  it) · trailing badge · chevron when the row navigates. A row is at least
  the hit target tall. A row that opens something is one button: no second
  control inside it.
- Objects (a portfolio, a building, a folder) use `mediaIcon`: an icon on a
  tonal tile; the row then centres tile, badge and chevron on the copy. Never
  a `KCard` with a chevron (`check-consumer-ui` › hand-built-row).
- A choice per row (a role per person) is a row with the value and a menu,
  not a full select field inside the row.

## Pages — review (Decision 0015)

- Every screen body is a `KPage`: gutter, safe areas, readable width and
  section spacing. Sign-in, onboarding and single forms use
  `KPage(width: form)` (520, centred vertically); everything else the page
  width (960). Never a bare scroll view (`check-consumer-ui` › bare-page).
- On phones `KAppShell` adds the bar that covers the status bar once content
  scrolls under it and takes the page title from `KPageHeader`; do not add
  a second app bar.
- Segmented control (`KSegmentedControl`): 2–5 options that switch a view
  or mode in place; not for navigation or actions. From 1.3× text three or
  more segments stack.
- Empty group: a single action row "+ Add …", not a sentence plus a button.

## Navigation — review + gesture tests (Decision 0012, Apple HIG)

Applies to iPhone/iPad and, by the parity rule, to mobile Web and the
tablet/desktop layouts. Android keeps its system back; do not build a custom
one.

**Back**

- Use `KBackButton` at the leading edge of the top bar: the chevron alone,
  never the word "Back"/"Zurück" or a text button. Its `label` names the
  destination for assistive technology ("Back to Portfolios").
- Back gestures stay on: leading-edge swipe and, as in iOS 26, a swipe
  anywhere in the content (Flutter: installed by `kDesignTheme` via
  `KPageTransitionsBuilder`). Never disable them. The only exception is a
  screen with unsaved changes: `PopScope(canPop: !dirty,
onPopInvokedWithResult: …)` and ask before discarding.
- Horizontal gestures in content (carousel, slider, map, swipe row) are
  fine: they win where they start. Do not put horizontal swipe actions
  across a whole screen; they would replace back navigation.

**Top level**

- iPhone: tab bar at the bottom, at most five tabs, each with a one-word
  label; for navigation only, never actions. Never hide or disable a tab;
  explain an empty section inside it. No "More" tab. Badges only for
  critical information. Each tab keeps its own navigation stack.
- The tab bar stays visible while navigating inside a tab; only modals
  cover it. It may minimise on scroll when it carries an accessory.
- iPad / tablet / desktop: tab bar at the top that can turn into a sidebar,
  or a sidebar (visible by default, hideable). Sidebar: at most two levels;
  deeper hierarchies get a split view (sidebar → list → detail).
- `KAppShell` implements this from its own width: tab bar below 600, sidebar
  rail 600–839, full sidebar from 840; 2–5 destinations.

**Breadcrumbs (Decision 0015)**

- Breadcrumbs measure the width: as many trailing levels as fit stay
  visible, the rest go into the menu (with their icons); only the last label
  is shortened with "…". Pass the trail as `KPageHeader(breadcrumb:)`.
- Phones show no breadcrumb: the back button carries the path. Always pass
  `backHistory` (root first, with icons); a long press opens it, as on iOS.

**Top bar**

- Title under 15 characters, never the app name; a large title that
  collapses on scroll on phones (`KAppShell` does this with `KPageHeader`).
- Leading: back (and sidebar toggle). Trailing: the most important actions,
  at most three groups, one prominent primary action (Done/Save) at the
  trailing edge, the rest in a More menu. Symbols instead of text, without
  borders; text only for actions without a clear symbol ("Edit").
- `KPageHeader` implements this: back and actions on top with a large title
  below on phones, one row from 600, actions under the title from 1.3×
  text; at most three actions.

**Sheets**

- For a short, scoped task; long or multi-step work gets a full-screen view.
- One sheet at a time: close the first before opening a second.
- Cancel (or Close) leading, Done trailing; never Done alone, never Back,
  Cancel and Done together. In a multi-step sheet, step 2+ shows Back
  instead of Cancel.
- Swipe down dismisses; with unsaved changes ask first (`PopScope`).
  Resizable sheets show a grabber; consider the medium detent for
  progressive disclosure. On iPad use the centred page/form sheet.
- Open sheets only through `KAdaptiveDialog.show`, `KBottomSheet.show` or
  `KPageSheet`: they share one drag model (`KSheetDrag`). The sheet follows
  the finger from handle, header and from a list at its top, closes past a
  quarter or on a fling, and leaves from where it was released. A custom
  sheet wraps its content in `KSheetDrag`.

**Web**

- Same structure. Browser back is the back gesture: every screen that has a
  back button has its own history entry and URL (the app's router owns it;
  the design system does not route). `KBackButton` defaults to
  `history.back()`.

## Forms — review

- Group fields under short section headings; pair short numeric/date fields
  side by side; units inside the field as suffix.
- Two to five exclusive options: `KSegmentedControl` (Material shows the M3
  segmented button), not a radio group. Dates use the date field with its
  own picker trigger inside the field, never a separate calendar button.
- Every dialog and sheet is migrated with the screen that opens it; check the
  inventory.
- Required errors appear at the field, scrolled into view on submit.
- Sticky footer with primary action in sheets; discard confirmation for dirty
  forms. A dependency that does not exist yet offers "Create …" inline.

## Motion — gate (Decision 0011)

- Animate with a role, never a duration or curve: `feedback` (press/hover),
  `control` (toggle, expand, reorder), `enter`, `exit`, `page`, `attention`.
  Web: `transition: opacity var(--k-motion-enter-settle)
var(--k-motion-enter-easing)`. Flutter: `final m = t.motion(KMotionRole.enter)`
  then `duration: m.settle, curve: m.curve` (or `m.spring` for physics).
- Multiply travelled offsets with the role's distance
  (`--k-motion-<role>-distance`, `m.distance`): reduced motion fades only.
- Exits are shorter than entries and never bounce. Bounce belongs to
  spatial motion, never to colour or opacity alone.
- The style (`apple` default, `expressive`, `reduced`) is chosen once per app
  via the adaptive overrides; the system reduce-motion setting always wins.
- Loops and script-driven choreography may use their own timing with a
  `k-ui-rules-ignore raw-motion: <reason>` comment.

## Sound and haptics — review (Decision 0013)

- Both are **off by default**. Turning them on is the person's choice (an
  app setting with `KSoundToggle` or a `KSwitch`); an agent building an app
  asks whether the product wants them at all before wiring any cue.
- Never the only feedback: every cue accompanies a visible change, and the
  interaction works the same when muted or on a device without haptics.
- Respect the system: Flutter haptics follow iOS System Haptics and Android
  touch feedback; sound uses the ambient/sonification channel and stops in
  the background. Web vibration does not exist on Safari (iOS, macOS) —
  never promise haptics there.
- Use them sparingly, for a deliberate act and its outcome: selection
  changes (`selection`), a toggle or drop landing (`light`), the result of an
  action the person started (`success`, `warning`, `error`). Never for
  scrolling, hover, typing, focus, timers or anything that repeats quickly
  (controllers drop cues closer than 60 ms).
- Built-in controls play cues only through a provider (`KSoundProvider`,
  `KHapticsProvider`): `KSwitch`, `KThemeSwitcher`, `KLanguageSwitcher`.
  Without a provider they are silent.

## Status — review

- Status is text + colour (badge), never colour alone. Dates are relative or
  locale-formatted, never ISO strings.
