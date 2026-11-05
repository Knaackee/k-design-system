# Decision 0012 — Navigation following Apple's guidelines

> Status: proposed (implemented on `feat/navigation-apple`, pending gallery acceptance)
> Date: 5 November 2026
> Sources: Apple Human Interface Guidelines — Toolbars, Tab bars, Sidebars,
> Sheets (2025–2026, Liquid Glass); iOS 26 `UINavigationController`
> `interactiveContentPopGestureRecognizer`

## Problem

On iPhone, apps built with the system had no reliable way back: Flutter only
offers a 20 pt edge swipe, iOS 26 system apps accept a back swipe from the
whole content area, and our own rule asked for a text back link
("‹ Portfolios"), which Apple's guidelines now advise against. Navigation
rules for tab bars, sidebars, top bars and sheets were not written down.
Android needs nothing from us: its system back and predictive back belong to
the platform.

## Decision

1. **Back control:** `KBackButton` (Web and Flutter), the back chevron alone at
   the leading edge; its accessible label names the destination. It mirrors
   in right-to-left layouts, pops with `Navigator.maybePop` (respects
   `PopScope`) and calls `history.back()` on Web.
2. **Back gesture (Flutter iOS/macOS):** `KPageTransitionsBuilder`, installed by
   `kDesignTheme`, keeps the Cupertino transition and adds the iOS 26
   content-area back swipe next to the leading-edge swipe. Horizontal
   gestures inside the page win where they start (they are deeper in the hit
   test and claim the drag first); the swipe honours
   `ModalRoute.popGestureEnabled` (first route, full-screen dialogs,
   `PopScope(canPop: false)`). `KPageTransitionsBuilder(contentSwipe: false)`
   restores edge-only behaviour.
3. **Rules** (skill `rules.md` → Navigation): tab bar limits and behaviour,
   iPad tab bar ↔ sidebar, sidebar depth, top bar title and action groups,
   sheet buttons, one sheet at a time, swipe-to-dismiss with a confirmation
   for unsaved changes, browser back on Web.
4. **No routing:** the design system ships controls, transitions and rules;
   apps keep their router.
5. **Components** (added on `feat/core-components`): `KAppShell` (tab bar
   below 600, sidebar rail 600–839, sidebar from 840, decided by the shell's
   own width; 2–5 destinations), `KPageHeader` (back + actions on top and a
   large title on phones, one row from 600, actions under the title from
   1.3× text, at most three actions), `KSegmentedControl` (2–5 options,
   radio-group semantics, sliding selection with the `control` motion role,
   stacked from 1.3× text with three or more options) and `KList` /
   `KListItem` (grouped rows, leading on the first line, trailing at most
   half the row and under the copy from 1.3× text, chevron for navigation).
   Web and Flutter share the structure and thresholds; the selection
   changes play the `selection` haptic when a `KHapticsProvider` is present.

## Consequences

- Breaking for the review rule "back names the parent": back is now the
  chevron with an accessible destination label.
- `KPageTransitionsBuilder` reads the route's transition controller through a
  protected member, as the framework's own Cupertino gesture does; a Flutter
  update could require an adjustment. Tests cover middle swipe, edge swipe,
  spring-back, horizontal content and `PopScope`.
- The page transition lives in `k_design_tokens` next to `kDesignTheme`,
  because the theme installs it.
- New public API: `KAppShell`, `KAppDestination`, `KPageHeader`,
  `KSegmentedControl`, `KSegment`, `KList`, `KListItem` on both platforms.
  `KSettingsRow` stays for settings with a control; `KListItem` is for
  navigation and read-only rows.
