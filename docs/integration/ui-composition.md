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

## Consumer checks

Run `node vendor/k-design-system/tooling/check-consumer-ui.mjs src` (Flutter: `lib`).
Pass only the new/migrated boundary, never the library's own implementation.
The lightweight scanner flags obvious bypasses and raw spacing for review. It is
not an AST verifier and cannot prove accessibility or visual quality. Findings
must be corrected or explicitly reviewed; do not hide them with blanket ignores.

## Sources

- [Carbon spacing](https://www.carbondesignsystem.com/building-blocks/foundations/spacing/overview)
- [Atlassian spacing](https://atlassian.design/foundations/spacing)
