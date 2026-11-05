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

**Top bar**

- Title under 15 characters, never the app name; a large title that
  collapses on scroll on phones.
- Leading: back (and sidebar toggle). Trailing: the most important actions,
  at most three groups, one prominent primary action (Done/Save) at the
  trailing edge, the rest in a More menu. Symbols instead of text, without
  borders; text only for actions without a clear symbol ("Edit").

**Sheets**

- For a short, scoped task; long or multi-step work gets a full-screen view.
- One sheet at a time: close the first before opening a second.
- Cancel (or Close) leading, Done trailing; never Done alone, never Back,
  Cancel and Done together. In a multi-step sheet, step 2+ shows Back
  instead of Cancel.
- Swipe down dismisses; with unsaved changes ask first (`PopScope`).
  Resizable sheets show a grabber; consider the medium detent for
  progressive disclosure. On iPad use the centred page/form sheet.

**Web**

- Same structure. Browser back is the back gesture: every screen that has a
  back button has its own history entry and URL (the app's router owns it;
  the design system does not route). `KBackButton` defaults to
  `history.back()`.

## Forms — review

- Group fields under short section headings; pair short numeric/date fields
  side by side; units inside the field as suffix.
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
