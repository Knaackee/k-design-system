# Mandatory UI composition contract

Read this before changing consumer UI. Applies to new and explicitly migrated
areas; record the migration boundary rather than silently replacing legacy UI.

## Choose components before styling

Inspect public exports and the component catalog at the pinned revision. Map each
requested control to an existing K component before implementation. Use KCheckbox,
KRadioGroup, KSelect/KCombobox, KButton and the existing K overlay components.
Do not substitute HTML form controls, Material/Cupertino controls or upstream UI
library imports in consumer code. Native internals inside library wrappers are
allowed. Structural HTML and Flutter Row/Column remain allowed.

If a contract is missing, extend the library and obtain gallery acceptance before
consumer integration. Do not recreate a reusable control locally or reach into
private package paths. Product routing, data and state remain in the application.

### Screen selection and reference compositions

Choose by user intent before choosing presentation. These Storybook examples are
consumer compositions, not routing/data APIs. Inspect source and public exports at
the pinned revision. Web-only drafts are not approved Flutter parity references.

| Intent                   | Composition                                             | Storybook story ID                            |
| ------------------------ | ------------------------------------------------------- | --------------------------------------------- |
| App navigation and cards | KSidebar, side KResponsiveDrawer, KBreadcrumb, KCard    | app-shells-settings-app--workspace            |
| Preferences              | KSettingsPage, KSettingsSection, KSettingsRow, K fields | app-shells-settings-app--workspace (Settings) |
| Guided setup             | KProgressDots, KField, KInput, KButton                  | app-shells-settings-app--onboarding           |
| Form submission          | KField, KInput, KSelect, KCheckbox, grouped actions     | app-shells-settings-app--form-page            |
| Search, filter, details  | KSearchField, KSelect, list actions, detail navigation  | app-shells-settings-app--list-detail          |
| First use                | KCard with explanation and a working creation action    | app-shells-settings-app--empty-workspace      |

Before implementation, record the selected reference and component mapping.
Reuse the composition, not demo text, fixed dimensions or private CSS selectors.
Texts, items, validation, routes and backend actions belong to the host. A demo
callback must not imply persistence, notifications or authentication that it lacks.

### Observable acceptance checklist

- Navigation: every destination, active item and return action agree. Mobile main
  navigation is a side drawer; contextual details may use a bottom sheet.
- Forms: invalid submission explains the problem; correction succeeds; cancel
  returns predictably. Preserve draft values or explicitly define discard behavior.
- Lists: search and filters compose; empty results can be cleared; opening and
  returning from details preserves context where the product requires it.
- Layout: one card inset, shared title/field/action edges, distinct page gutter
  and section gaps. Use semantic roles; do not copy pixel values from screenshots.
- Accessibility: visible focus, meaningful labels, keyboard operation and touch
  targets. Larger type and density must not hide actions or truncate required text.
- Review matrix: desktop and short phone viewport; pointer and touch; light/dark;
  dense/standard/spacious and increased text scale. Inspect opened overlays too.
- Record each actual checked journey and state, failures and untested platforms.
  Static checks catch likely bypasses; only interaction and visual review establish
  usability. Human gallery acceptance remains separate from automated checks.

## Spacing ownership and hierarchy

- A component owns its internal spacing; its parent owns space between siblings.
- Use KStack/KInline: `control` for related controls, `action` for action groups,
  `section` for separate sections. Resolve values through the active density.
- Keep labels/help text close to their field. Use larger separation between groups
  than within groups. Do not add a second label if the control already supplies it.
- A card has one deliberate content inset. Inspect the component contract: do not
  assume KSurface provides content padding. Apply an existing semantic token at
  the composition boundary if required; never stack accidental nested insets.
- Align section titles, fields and action areas to shared content edges. Separate
  heading, body and secondary text using KText roles rather than arbitrary sizes.
- Page gutters, card insets and inter-card gaps are distinct responsibilities.
  Use existing semantic tokens, not copied demo pixels or a new local scale.
- Do not override private component selectors. Missing spacing roles require a
  library decision, not repeated hard-coded fixes in applications.
- Density changes spacing and control sizing centrally; do not shrink touch
  targets or override density locally to make a screenshot fit.

## Equivalent composition examples

These fragments use consumer-supplied field/action widgets composed from public
K components; they intentionally introduce no new data model or navigation.

```tsx
<KStack gap="section" align="stretch">
  <KStack gap="control" align="stretch">
    {profileFields}
  </KStack>
  <KStack gap="control" align="stretch">
    {notificationFields}
  </KStack>
  <KInline gap="action" wrap>
    {actions}
  </KInline>
</KStack>
```

```dart
KStack(gap: KLayoutGap.section, align: KLayoutAlign.stretch, children: [
  KStack(gap: KLayoutGap.control, children: profileFields),
  KStack(gap: KLayoutGap.control, children: notificationFields),
  KInline(gap: KLayoutGap.action, wrap: true, children: actions),
])
```

Wrong: native Checkbox plus manual label and repeated pixel padding around every
ancestor. Right: KCheckbox with its public label/state/events, inside a tokenized
layout. Wrong: CSS targeting a K component's internal input. Right: public props,
host token overrides, or an accepted library extension.

## Responsive and visual acceptance

Verify mobile and desktop, light/dark and dense/standard/spacious; include long
labels, errors, disabled states, keyboard focus and text scaling. Check wrapping,
scroll access, card insets, shared alignment and pointer/touch targets. Use matching
content on Web and Flutter. Do not claim visual review from a build alone.

Report: pinned revision; components reused; layout/token roles; host override
location; inspected viewports/states; automated results; any unverified platform.
New reusable components still require human gallery acceptance.

Overlay choice follows purpose, not viewport alone:

- Primary app navigation opened by a hamburger remains a side drawer on phones.
  Compose KSidebar inside KResponsiveDrawer with side="left" and breakpoint={0}.
  Do not substitute KBottomSheet for primary navigation.
- Contextual details may use KResponsiveDrawer with its normal breakpoint: side
  panel on larger screens, bottom sheet on phones. KDialog is adaptive too.
- A wrapper that already decides presentation must not delegate its fixed-side
  branch to another adaptive wrapper. Keep one responsive decision owner.
- Verify the opened overlay, not only its trigger: correct edge and full-height
  side presentation, visible close action, backdrop/Escape dismissal, focus return,
  selection closes mobile navigation, and desktop navigation remains available.

## Consumer checks

Run `node vendor/k-design-system/tooling/check-consumer-ui.mjs src` (Flutter: `lib`).
Pass only the new/migrated boundary, never the library's own implementation.
The lightweight scanner flags obvious bypasses and raw spacing for review. It is
not an AST verifier and cannot prove accessibility or visual quality. Findings
must be corrected or explicitly reviewed; do not hide them with blanket ignores.

## Sources

- [Carbon spacing](https://www.carbondesignsystem.com/building-blocks/foundations/spacing/overview)
- [Atlassian spacing](https://atlassian.design/foundations/spacing)
