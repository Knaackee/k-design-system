---
name: k-design-system-workflow
description: Build, review or migrate UI in an application that consumes K Design System (Web/React or Flutter) through a Git submodule. Use for any screen, component composition, spacing/typography decision, token change or design-system update — including "make this look right on phones", density/text-size problems and translating a design mock into K components.
---

# K Design System workflow

## The one idea

**A screen is a composition of existing K components, resolved for the device
it runs on, aligned to one grid, and proven on a real phone size before
anyone reviews it.**

**Defaults first.** Out of the box a K app should look like Apple or Google
built it: the platform-native style (Decision 0014) sets spacing, sizes,
shapes, type and motion. Pass props for content, events and state only. A
different look is a token or style change in one place, never per-screen
values.

**Every surface, not only screens.** A migration or review covers every
screen **and** every sheet, dialog, menu and form the app opens. Start with
the inventory (Workflow step 1b); a surface without evidence is not done.

Twelve ways it fails (each has a rule in `references/rules.md`):

- **Card in a card.** A bordered box inside a bordered box. Inside a card use
  separators, a grouped list or a section; siblings are siblings.
- **Floating icon.** A leading icon centred on a two-line text block instead of
  sitting on the first line. Use `KLeading` (Flutter) / `.k-leading` (Web).
- **Blown-up phone.** Desktop or "spacious" spacing and heading sizes on a
  390 pt screen; content one card per screen. Adaptive resolution fixes this —
  never hand-pick a preset per platform.
- **Cramped desktop.** Phone layout stretched to 1400 px: one column of full-
  width rows, no secondary pane.
- **Raw values.** `16`, `EdgeInsets.all(18)`, `font-size: 13px`, an icon at
  `size: 18`. Tokens and roles only; the grid is 4 px.
- **Dropdown as navigation.** A select that switches page sections. Sections
  are `KListItem` rows that open pages, tabs, or a `KSegmentedControl` for
  2–5 views.
- **Hand-made navigation.** A text back link, a local tab bar or a disabled
  back gesture. Use `KAppShell`, `KPageHeader` / `KBackButton`; keep system
  gestures on (Decision 0012).
- **Raw motion.** `Duration(milliseconds: 300)`, `Curves.easeOut`,
  `transition: .2s ease`. Pick a motion role; the app's style decides
  (Decision 0011).
- **Noisy feedback.** Sound or haptics on by default, as the only feedback,
  or on scroll, hover and typing (Decision 0013).
- **Hand-built rows and pages.** A `KCard` with a title, a badge and a
  chevron instead of `KListItem` (media tile: `mediaIcon`); a
  `SingleChildScrollView` page instead of `KPage`, so a sign-in form runs
  across a whole iPad (Decision 0015).
- **Appearance in app code.** Icon `strokeWidth`, `KAdaptiveOverrides` for
  style/density/type scale, control heights or radii set per screen. The
  style preset decides them (Decision 0015).
- **Desktop forms on a phone.** Radio buttons for two options (use
  `KSegmentedControl`), a calendar button beside a date field, one full
  select per row inside a list (use a row with a value and a menu).

## Workflow

Most quality is decided before code. Write the composition map first.

1. **Locate and update.** Resolve the library via `.gitmodules` /
   `vendor/k-design-system`. Read its `AGENTS.md`, public exports and
   `docs/component-catalog.md`. Compare the pin with `origin/main`;
   fast-forward only a clean checkout. After a pin update read
   `CHANGELOG.md` (Unreleased); coming from a pin before November 2026,
   follow `docs/integration/upgrade-2026-11.md` first.
   1b. **Inventory.** List every route, sheet, dialog, menu and form the app
   opens (search for `KAdaptiveDialog.show`, `KBottomSheet.show`,
   `KPageSheet`, `showDialog`, `Navigator.push`, routes). Keep the list in
   the handover; each entry gets a screenshot pair (before/after) or a
   reason.
2. **Adaptive setup (once per app).** Flutter: wrap the app in
   `KAdaptiveTheme`. Web: `applyKAdaptive(document.documentElement)`. Do not
   pass `KDesignConfiguration.mobileApp` "because it is a phone app" — the
   resolver derives window class, input and type ramp. Top-level navigation
   is one `KAppShell`; the motion style and whether sound/haptics exist are
   one app-level decision each. See `references/adaptive.md`.
3. **Pick the closest reference.** Choose by user intent from the table in
   `docs/integration/ui-composition.md` and open its Storybook story /
   Widgetbook use case. Copy its structure (sections, list vs card, header,
   actions), not its demo text or pixel values. If none fits, say so and build
   from the patterns in `references/patterns.md`.
4. **Composition map.** Before coding, write:
   `screen -> reference -> K components -> layout roles (KStack/KInline gap
control|action|section) -> text roles (KText variants) -> leading visuals`.
   Every requested control maps to a public K component; native HTML,
   Material or Cupertino controls are not substitutes.
5. **Build.** Parents own sibling spacing; components own their insets. One
   card inset. Leading icons through `KLeading`. Long labels wrap (Flexible /
   `wrap: true`), numbers and prices never truncate.
6. **Gate.** Run the checks in "Before handover". Fix the largest visible
   fault first: overflow, then hierarchy (card nesting, alignment), then
   rhythm (spacing), then polish.
7. **Hand over** with the evidence block below.

## Recurring faults — check every time

| Fault                                                  | Rule                         |
| ------------------------------------------------------ | ---------------------------- |
| Nested `KCard` / bordered surface inside a card        | rules.md › Cards             |
| Icon/checkbox/dot centred on multi-line text           | rules.md › Leading visuals   |
| Icon size 14, 15, 18, 22, 28 …                         | rules.md › Icons             |
| Literal insets, gaps or font sizes                     | rules.md › Spacing           |
| Row of label + value/badge that overflows at 1.3× text | rules.md › Wrapping          |
| Page that only fits at 1.0× text (no scroll)           | rules.md › Text scaling      |
| Pagination, toolbars or chips exceeding 360 px         | rules.md › Narrow windows    |
| One card per list item                                 | rules.md › Lists             |
| Status shown by colour only                            | rules.md › Status            |
| Text back link, local tab bar, disabled back gesture   | rules.md › Navigation        |
| Literal duration/curve, bounce on an exit              | rules.md › Motion            |
| Sound/haptics on by default or as the only feedback    | rules.md › Sound and haptics |
| Card used as a list row, scroll view used as a page    | rules.md › Lists, Pages      |
| `strokeWidth`, density or style set in app code        | rules.md › Defaults          |
| Control under 44 pt on iOS, 48 dp target on Android    | rules.md › Touch targets     |
| Breadcrumb on a phone, back button without its path    | rules.md › Navigation        |
| Sheet that cannot be dragged from its list             | rules.md › Sheets            |

`references/teaching.md` has a wrong/right pair for each fault.

## Before handover

```bash
# from the consumer repository
node vendor/k-design-system/tooling/check-ui-rules.mjs <changed paths>
node vendor/k-design-system/tooling/check-consumer-ui.mjs src   # Flutter: lib
```

`check-consumer-ui` reports `icon-stroke`, `appearance-override`,
`hand-built-row` and `bare-page` besides native controls and raw spacing.
Every finding is fixed or carries a `k-ui-rules-ignore` comment with a
reason the person accepted.

Then verify on phone sizes, not only desktop:

- Flutter: run the app (or a widget test through `KAdaptiveTheme`) at
  360×740 and 393×852 with system text 1.0, 1.3, 2.0 and 3.0 on iOS and
  Android. No RenderFlex overflow, no clipped required text, actions
  reachable.
- Web: Storybook/browser at 360 and 393 px with `(pointer: coarse)` emulation
  and the same text scales. Inputs are 16 px (no iOS zoom).
- Tablet and window widths: resize across 600 and 840 (shell tab bar ↔ rail
  ↔ sidebar) on iPad/Android tablet or a browser window.
- Device-only behaviour, on real hardware: iOS back swipe from the middle of
  the screen, sheet swipe with unsaved changes, haptics, reduce motion.
- Platform views (maps, video, web views) do not render in widget tests: use
  the component's builder/stand-in seam there, as the library fixtures do,
  and check the real view on a device.
- Library changes additionally pass `pnpm gate:phone-flutter`,
  `pnpm gate:phone-web` and `pnpm gate:geometry`, and the story review in
  both galleries.

A passing gate is necessary, not sufficient: human gallery acceptance remains
required for new reusable components.

## Evidence block (paste into the handover)

```
Revision: <library pin>
Reference used: <story/use-case id> — changed: <what>
Components: <reused> / added: <none|names + gallery ids>
Layout roles: <gaps, insets, text roles>
Inventory: <n> screens, <n> sheets/dialogs, <n> menus — all with evidence | missing: <list>
Checked: phone 360/393 · tablet · text 1.0/1.3/2.0/3.0 · iOS/Android · light/dark · reduce motion · <journeys>
Motion style / sound / haptics: <apple|expressive|reduced> / <off|setting> / <off|setting>
Rule gate: <output summary>
Not checked: <platforms, states>
```

## Ask or decide

Ask before acting when the answer changes what the product is or what other
apps get; decide yourself when the rules already answer it. Ask once, with the
options and your recommendation, and keep working on everything else.

**Ask the person:**

- Product decisions: the style preset (`linear`, `apple`, `material`); motion style other than `apple`; whether sound or
  haptics exist at all (an explicit request is that decision: add them behind
  a setting, still off until the person turns them on); which 2–5 destinations go into the tab bar; what a
  destructive action deletes; wording of legal, pricing or consent text.
- Anything that changes the library for every app: a new or changed public
  component, prop, token name or default; a host override versus a shared
  default when it could be either; platform behaviour (gestures, back
  handling).
- A reference story or rule that contradicts the request, or a mock that
  breaks a rule (nested cards, raw values, a text back link). Say which rule
  and offer the compliant version.
- Commit, push, merge, pin updates and anything else outside the working
  tree, unless the person already asked for it.

**Decide yourself (and name the choice in the handover):**

- Which K component and reference to use, the composition map, layout and
  text roles, gaps and insets from the token roles.
- Stacking, wrapping and scrolling at large text and narrow widths.
- Which motion role an animation uses; which haptic cue fits, once haptics
  are on.
- Fixing a rule-gate finding, an overflow or an accessibility label.
- Proposing (not building) a missing library component.

If the person is not available, take the most conservative option (library
default, feature off, existing component), note it under "Not checked" and
continue.

The library's own `AGENTS.md` and `pnpm verify` apply to work inside
`vendor/k-design-system` only; in a host app the checks above are the
handover.

## Ownership

Host owns product data, navigation, events and theme overrides. Library owns
reusable components and shared defaults. Missing reusable behaviour belongs in
the library (feature branch, matching Web/Flutter fixtures, gallery
acceptance) — never a local copy or a private-selector patch. Commit, push,
merge and pin updates keep their separate authorisation requirements.
