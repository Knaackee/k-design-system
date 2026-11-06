# Changelog

All notable changes to supported K Design System releases will be documented in
this file. The project follows semantic versioning once the first supported
version is tagged.

## Unreleased

- Platform-native defaults reach every component (Decision 0015): touch
  heights (Apple 44 pt controls, 50 pt full-width buttons with a centred
  label; Material 40 dp buttons and 56 dp fields), one icon stroke per style
  at every size, list values beside the title when they fit and under it
  otherwise, `KListItem.mediaIcon`, measured breadcrumbs and
  `KPageHeader.backHistory` / `KBackButton.history`, one sheet drag model
  (`KSheetDrag`: drag from a list at its top, no jump back on dismissal),
  `KPage` with readable page and form widths, a scroll bar under the status
  bar that takes the page title, Android fade-forwards transitions, press
  feedback, the Material 3 segmented button and a labelled tablet sidebar.
  The scrolled top bar keeps back and actions (text actions in a More
  menu); text-adjacent icons grow with the text up to 2×
  (`text.scaleMax.icon`, `kIconScale`, `KIconFixedScope`).
- Phone top bar holds back and actions at all times (no duplicates, one
  More menu); primary action as extended FAB (Material) or bar icon
  (Apple), `KAppShell.primaryActionPlacement`. Keyboard-only focus rings
  (`kFocusVisible`). `KListItem(menu:)` and `KListItem(switchValue:)`,
  `KOnboarding` with a fixed footer. `check-consumer-ui`: `split-row`,
  `hand-built-steps`.
  `check-consumer-ui` reports `icon-stroke`, `appearance-override`,
  `hand-built-row` and `bare-page`.

- Added the `material` style (Material 3 Expressive) and made the default
  platform-native: Android gets `material` with expressive motion, iPhone and
  iPad `apple`, desktops `linear`. `apple` gains squircle group corners, a
  44 pt round back button and content under the floating glass tab bar.
  `material` uses an opaque M3 navigation bar with a pill indicator
  (`component.mobileAppBar.destination.indicatorWidth/Height`).
- Added style presets (Decision 0014): `linear` and `apple`; without
  configuration iPhone and iPad get `apple`, other platforms `linear`
  (iOS ramp 17/34, 44 pt rows, inset grouped lists, sentence-case section
  headers, capsule buttons, round back button, floating glass tab bar, system
  font on Apple devices). `KList` draws its grouped surface with `title` and
  `footer`; `KListItem.value` for text values. The App shell caps the page
  width, the sidebar shows a clear active state. Tab bar labels keep their
  size at large text. Review sheet tools: `tooling/contact-sheet.mjs` and the
  Widgetbook screenshot test.
- The `raw-motion` rule of `tooling/check-ui-rules.mjs` now also checks
  consumer apps (files outside this repository), not only library packages.
- Docs: upgrade guide for consumer apps (`docs/integration/upgrade-2026-11.md`),
  a routing skill entry for hosts instead of copying the skill
  (`docs/integration/host-skill.md`), an "Ask or decide" section in the
  workflow skill, and a corrected component catalog.
- Added `KAppShell` (tab bar, sidebar rail or sidebar by the shell's own
  width), `KPageHeader` (large title on phones, actions under the title from
  1.3× text), `KSegmentedControl` (2–5 options, radio-group semantics,
  stacks from 1.3× text) and `KList` / `KListItem` (grouped rows, leading on
  the first line, trailing under the copy from 1.3× text) on Web and
  Flutter, with fixtures in both galleries (Decision 0012).
- Added haptics (Decision 0013): `KHapticCue` (`selection`, `light`,
  `medium`, `heavy`, `success`, `warning`, `error`), `KHapticController`
  (off by default, drops cues closer than 60 ms, silent in the background)
  and `KHapticsProvider` on Web and Flutter. Flutter maps to
  `HapticFeedback`, Web to `navigator.vibrate` (`isSupported` is false on
  Safari). `KSwitch`, `KThemeSwitcher` and `KLanguageSwitcher` play a cue when
  a provider is present. Sound and haptics rules in the skill.
- Added Apple navigation (Decision 0012): `KBackButton` on Web and Flutter
  (chevron only, accessible label names the destination; mirrors in RTL);
  `KPageTransitionsBuilder`, installed by `kDesignTheme` for iOS/macOS, adds
  the iOS 26 back swipe from anywhere in the content next to the edge swipe
  (horizontal content keeps its own gestures; `PopScope` is honoured).
  Navigation rules for tab bars, sidebars, top bars and sheets in the skill.
- `KBottomSheet` swipe-to-dismiss and Cancel now go through
  `Navigator.maybePop`, so a `PopScope` for unsaved changes can ask first
  (previously the swipe closed the sheet unconditionally).
- Added configurable motion (Decision 0011): roles `feedback`, `control`,
  `enter`, `exit`, `page`, `attention` as springs (duration, bounce,
  distance) in three styles `apple` (default), `expressive` and `reduced`.
  Web gets `data-motion`, `--k-motion-<role>-settle/-easing` (the spring as
  `linear()`) and `kMotion()`; Flutter gets `KMotionStyle`, `KMotionRole`,
  `tokens.motion(role)` with `.settle`, `.curve` and `.spring`. The system
  reduce-motion setting always wins; an app-chosen `reduced` style also sets
  `disableAnimations` on Flutter. Both galleries have a motion switch and the
  shared fixture `Primitives/Motion/motion-roles`.
- All library transitions use motion roles; new gate rule `raw-motion`.
- Fixed `--k-motion-slow`, which three chat animations referenced but no
  token defined.
- Final visual acceptance and the release tag remain pending.
- **Breaking (Decision 0010):** adaptive axes now resolve at runtime from the
  available window and platform (`applyKAdaptive`, `resolveKAdaptive`,
  `KAdaptiveTheme`, `resolveKAdaptiveConfiguration`). Galleries default to the
  same resolution. Migration: Flutter apps wrap their app in `KAdaptiveTheme`
  instead of passing `KDesignConfiguration.mobileApp`; Web apps call
  `applyKAdaptive(document.documentElement)`.
- **Breaking:** `KDesignConfiguration.mobileApp` is Standard density with the
  new `mobile` type ramp (H1 28/34, body and controls 16) instead of Spacious.
- **Breaking:** removed `font.microSize` and `font.microLabelSize` (8/9 px);
  use `font.caption2Size` (11 px). Off-grid spacing roles snap to the 4 px grid.
- Added per-role system text-scale caps (`text.scaleMax.*`): headings 2.0,
  controls and body 3.0; settings rows stack from 1.3x (`setKTextScale` on
  Web). The type ramp follows the window class only (tablet = desktop). Fixed balanced headings measuring with an unclamped
  text scaler.
- Added phone gates for both galleries (Widgetbook knob use cases included;
  `pnpm gate:phone-web` for Storybook) and a Web/Flutter geometry parity gate
  (`pnpm gate:geometry`, reference story `Review/GeometryParity`).
- Fixed Web/Flutter differences found by the parity gate: checkbox/radio row
  height on pointer devices, and Flutter badge, alert and navigation text using
  the unscaled optical size at large text sizes.
- Web `.k-text` breaks long words like Flutter; `KProgress` meta wraps;
  `KShowcaseGrid` foreground scrolls at large text; activity legend wraps.
- Both phone gates now fail at every text scale up to 3.0 and have no
  exception list; Web stories that do not load fail too.
- Faster gates: the Flutter phone gate runs as six shard processes in
  parallel (`pnpm gate:phone-flutter`, part of `pnpm verify`; about 6 min
  instead of 14 on two cores, and no longer killed for memory); the Web phone
  gate loads each story once per phone size and steps the text scale in
  place (about 9 min instead of 20).
- Web layout (breaking for layouts that relied on overflow): `.k-layout` and
  its children are capped at the parent width; text, truncated content and
  nested layouts in a `KInline` shrink like Flutter `Flexible`; size
  containers (`KUsageDetails`, `KSortableTree`, `KShowcaseGrid`,
  `KPagination`) take the full width; implicit grid columns of components are
  `minmax(0, 1fr)`; component text breaks long words; `KBadge` wraps instead
  of overflowing; `KButton`'s hit area bleeds vertically only (icon buttons
  in both axes); `KPopover` and integration admin actions stay in bounds.
- Flutter large-text layouts: `KCarousel` slide height scales with the system text size;
  `KCatalogEditorDialog` scrolls its header with the form; `KDataTable`
  single-column trailing, `KOfferOverview` price and `KWebSearch` status move
  under the title from 1.3x; `KQuestionnaire` actions wrap.
- Added opt-in follow-up submission during active chat responses on Web and
  Flutter, preserving the stop action and submission controls.
- Made standard presentation cards compact with accessible icon actions while
  preserving full content and cover-card actions.
- Added expanded select popups with optional option descriptions on Web and
  Flutter, bounded by the viewport.

## 1.0.0-rc.1 - 2026-09-25

- Established public Web and Flutter package boundaries for the first release
  candidate, including Timeline and Gantt.
- Added standalone Web and Flutter consumer examples with host-owned token
  overrides and state/event integration.
- Added Web ESM, package-content and tree-shaking verification.
- Added the supported Git-submodule integration and migration workflow.
- Added a reusable consumer-agent skill with explicit token-ownership gating.

No supported release has been published from this changelog yet.
