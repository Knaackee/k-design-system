---
name: k-design-system-workflow
description: Build, review or migrate UI in an application that consumes K Design System (Web/React or Flutter) through a Git submodule. Use for any screen, component composition, spacing/typography decision, token change or design-system update — including "make this look right on phones", density/text-size problems and translating a design mock into K components.
---

# K Design System workflow

## The one idea

**A screen is a composition of existing K components, resolved for the device
it runs on, aligned to one grid, and proven on a real phone size before
anyone reviews it.**

Six ways it fails (each has a rule in `references/rules.md`):

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
  are rows that open pages, tabs, or a segmented control for 2–4 views.

## Workflow

Most quality is decided before code. Write the composition map first.

1. **Locate and update.** Resolve the library via `.gitmodules` /
   `vendor/k-design-system`. Read its `AGENTS.md`, public exports and
   `docs/component-catalog.md`. Compare the pin with `origin/main`;
   fast-forward only a clean checkout.
2. **Adaptive setup (once per app).** Flutter: wrap the app in
   `KAdaptiveTheme`. Web: `applyKAdaptive(document.documentElement)`. Do not
   pass `KDesignConfiguration.mobileApp` "because it is a phone app" — the
   resolver derives window class, input and type ramp. See
   `references/adaptive.md`.
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

| Fault                                                  | Rule                       |
| ------------------------------------------------------ | -------------------------- |
| Nested `KCard` / bordered surface inside a card        | rules.md › Cards           |
| Icon/checkbox/dot centred on multi-line text           | rules.md › Leading visuals |
| Icon size 14, 15, 18, 22, 28 …                         | rules.md › Icons           |
| Literal insets, gaps or font sizes                     | rules.md › Spacing         |
| Row of label + value/badge that overflows at 1.3× text | rules.md › Wrapping        |
| Page that only fits at 1.0× text (no scroll)           | rules.md › Text scaling    |
| Pagination, toolbars or chips exceeding 360 px         | rules.md › Narrow windows  |
| One card per list item                                 | rules.md › Lists           |
| Status shown by colour only                            | rules.md › Status          |

`references/teaching.md` has a wrong/right pair for each fault.

## Before handover

```bash
# from the consumer repository
node vendor/k-design-system/tooling/check-ui-rules.mjs <changed paths>
node vendor/k-design-system/tooling/check-consumer-ui.mjs src   # Flutter: lib
```

Then verify on phone sizes, not only desktop:

- Flutter: run the app (or a widget test through `KAdaptiveTheme`) at
  360×740 and 393×852 with system text 1.0, 1.3, 2.0 and 3.0 on iOS and
  Android. No RenderFlex overflow, no clipped required text, actions
  reachable.
- Web: Storybook/browser at 360 and 393 px with `(pointer: coarse)` emulation
  and the same text scales. Inputs are 16 px (no iOS zoom).
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
Checked: phone 360/393 · text 1.0/1.3/2.0 · iOS/Android · light/dark · <journeys>
Rule gate: <output summary>
Not checked: <platforms, states>
```

## Ownership

Host owns product data, navigation, events and theme overrides. Library owns
reusable components and shared defaults. Missing reusable behaviour belongs in
the library (feature branch, matching Web/Flutter fixtures, gallery
acceptance) — never a local copy or a private-selector patch. Commit, push,
merge and pin updates keep their separate authorisation requirements.
