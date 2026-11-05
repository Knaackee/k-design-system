# Upgrading a consumer app to the November 2026 release

For apps that already use K Design System through `vendor/k-design-system`.
Covers Decisions 0010–0013 and the new navigation components. Work through the
steps in order; each ends in something you can check.

## 1. Update the pin

```bash
git -C vendor/k-design-system fetch origin
git -C vendor/k-design-system checkout <accepted main commit>
pnpm install            # Web
flutter pub get         # Flutter
```

Read `CHANGELOG.md` (Unreleased) and the skill
`.agents/skills/k-design-system-workflow/SKILL.md` in the new pin before
changing code.

If the host repository contains a copied `k-design-system-workflow` skill
directory, delete it and install the routing entry from
[host-skill.md](host-skill.md). The copy holds the old rules and agents load
it automatically.

## 2. Breaking changes — fix these first

| Change                                                                                                           | What to do                                                                                                                                                                                                                        |
| ---------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Adaptive axes resolve at runtime (0010)                                                                          | Flutter: wrap the app in `KAdaptiveTheme` (in `MaterialApp.builder`); stop passing `KDesignConfiguration.mobileApp`. Web: call `applyKAdaptive(document.documentElement)` once; forward an in-app text size with `setKTextScale`. |
| `font.microSize`, `font.microLabelSize` removed                                                                  | Use `font.caption2Size` (11 px).                                                                                                                                                                                                  |
| Spacing snapped to a 4 px grid                                                                                   | Check custom layouts that relied on 5, 6, 10 or 14 px.                                                                                                                                                                            |
| `desktopApp` uses the standard type ramp                                                                         | Dense admin screens opt into `dashboard` explicitly.                                                                                                                                                                              |
| Web layout children never exceed their parent; text in `KInline` shrinks                                         | Layouts that relied on overflow now wrap. Check toolbars, rows with long labels and tables at 360 px.                                                                                                                             |
| Back control is the chevron alone (0012)                                                                         | Replace text back links ("‹ Portfolios") with `KBackButton(label: 'Back to Portfolios')` or `KPageHeader(backLabel: …)`.                                                                                                          |
| `KBottomSheet` swipe and Cancel go through `Navigator.maybePop`                                                  | A sheet with unsaved changes needs a `PopScope` that asks before closing; otherwise nothing changes.                                                                                                                              |
| Library transitions use motion roles (0011); default style `apple` is calmer (320–500 ms for control/enter/page) | Remove app-side duration/curve overrides of library components. Own animations use roles (see 4).                                                                                                                                 |

## 3. Replace local copies with the new components

| Local pattern                                                                     | Replace with                                                                                   |
| --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Bottom tab bar on phones + sidebar on desktop                                     | `KAppShell` (tab bar < 600, rail 600–839, sidebar ≥ 840 by its own width; 2–5 destinations)    |
| Screen title with back link and buttons                                           | `KPageHeader` (large title on phones, at most three actions, one of them primary)              |
| Toggle buttons / tabs that switch a view in place                                 | `KSegmentedControl` (2–5 options); a `select` that switches page sections becomes rows or tabs |
| Rows built from `KInline`, a card per item, or `KSettingsRow` used for navigation | `KList` + `KListItem` on one `KSurface`; `KSettingsRow` stays for settings with a control      |

The app keeps its router: `KAppShell.onSelected` and `KPageHeader.onBack`
report, the app navigates. On Flutter iOS/macOS `kDesignTheme` installs
`KPageTransitionsBuilder`; if the app sets its own `pageTransitionsTheme`,
use `KPageTransitionsBuilder()` for iOS and macOS there too, or the content
back swipe is lost.

## 4. Style, motion, sound and haptics

- Style preset (Decision 0014): iPhone and iPad get `apple`, Android
  `material`, desktops `linear` automatically. Override only to deviate, once via `KAdaptiveOverrides(style:)` /
  `applyKAdaptive(root, { style })`. Remove local spacing, row heights,
  radii and font sizes that imitated a style; the preset owns them.

- Motion style: one decision per app (`apple` default, `expressive`,
  `reduced`) through `KAdaptiveOverrides(motion:)` / `applyKAdaptive(root,
{ motion })`. The system reduce-motion setting always wins.
- Own animations: `tokens.motion(KMotionRole.enter)` (`.settle`, `.curve`,
  `.spring`) on Flutter; `var(--k-motion-enter-settle)
var(--k-motion-enter-easing)` or `kMotion('enter', el)` on Web. The rule
  gate rejects literal durations and curves (`raw-motion`).
- Sound and haptics are off by default. Add `KSoundProvider` /
  `KHapticsProvider` only if the product wants them, behind a setting the
  person controls (`KSoundToggle`, a `KSwitch`). With a provider, built-in
  controls play their cues automatically: sound in `KThemeSwitcher` and
  `KLanguageSwitcher`; haptics in those two plus `KSwitch`,
  `KSegmentedControl` and `KAppShell`. Never the only feedback; never for scroll,
  hover or typing. Web vibration does not exist on Safari (iPhone, Mac).

## 5. Verify

Run the rule checks from the consumer repository:

```bash
node vendor/k-design-system/tooling/check-ui-rules.mjs <changed paths>
node vendor/k-design-system/tooling/check-consumer-ui.mjs src   # Flutter: lib
```

Then the device matrix. Each row at text size 100 %, 130 %, 200 % and 300 %,
light and dark:

| Device                           | Check in addition                                                                             |
| -------------------------------- | --------------------------------------------------------------------------------------------- |
| iPhone (small and large)         | Back swipe from the middle of the screen; sheet with unsaved changes asks; haptics if enabled |
| iPad portrait and landscape      | Shell switches rail ↔ sidebar; split view / Stage Manager at narrow widths shows the tab bar  |
| Android phone (360 dp wide)      | System back and predictive back unchanged; haptics if enabled                                 |
| Android tablet                   | Same as iPad                                                                                  |
| Desktop browsers incl. Safari    | Keyboard: segmented control arrows, list rows, focus rings; window resize across 600 / 840    |
| Any device with reduce motion on | Only fades, no movement                                                                       |

No overflow, no clipped required text, every action reachable. Paste the
evidence block from the skill into the handover.

## Reference fixtures

Same IDs in Storybook and Widgetbook: `Navigation/AppShell/app-shell`,
`Navigation/PageHeader/page-header`,
`Navigation/SegmentedControl/segmented-control`, `Data display/List/list`,
`Navigation/BackButton/back-button`, `Primitives/Motion/motion-roles`,
`Patterns/Haptics/haptics-review`, `Review/GeometryParity`.
