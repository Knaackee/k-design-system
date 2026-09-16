# Shared composition and density

`KStack` arranges children vertically; `KInline` arranges them horizontally.
Both default to `gap="control"` and `align="start"`. Flutter uses
`KLayoutGap` and `KLayoutAlign` enums. Children retain their natural size;
`align="stretch"` explicitly fills the cross axis. `KInline.wrap` defaults to
false. Wrapping uses the same gap between items and rows; combining wrapping
with stretch throws on both platforms.

| Semantic role                  | Dense | Standard | Spacious |
| ------------------------------ | ----: | -------: | -------: |
| control gap                    |     4 |        8 |       12 |
| action gap                     |     8 |       16 |       24 |
| section gap                    |    16 |       32 |       48 |
| card inset                     |    12 |       16 |       24 |
| control inline inset           |     8 |       12 |       16 |
| visible control minimum height |    32 |       36 |       44 |

Values are CSS pixels / Flutter logical pixels. Standard is the default.
Text can grow with accessibility scaling. Touch targets remain independent.

```tsx
<KCard>
  <KStack gap="action">
    <KStack>
      <KText variant="heading4">Project settings</KText>
      <KText variant="bodySmall">Configure your workspace.</KText>
    </KStack>
    <KButton>Configure</KButton>
  </KStack>
</KCard>
```

```dart
KCard(
  child: KStack(
    gap: KLayoutGap.action,
    children: [
      const KStack(children: [
        KText('Project settings', variant: KTextVariant.heading4),
        KText('Configure your workspace.', variant: KTextVariant.bodySmall),
      ]),
      KButton(label: 'Configure', onPressed: () {}),
    ],
  ),
)
```

Parents own sibling gaps; Text and Button add no outside margins. Card owns its
inset. For external customization, override `--k-space-control-gap`,
`--k-space-content-action-gap`, and `--k-space-layout-section-gap` on a Web
consumer scope, or provide a `KDesignTokens.copyWith(...)` theme extension after
resolving Flutter configuration. Live token changes update existing layouts.
Neither implementation imports gallery code.

## Pre-release migration

Remove `KPresentation`, the `presentation` configuration argument and Web
`data-presentation`. There is no compatibility override. Old Productive/Expressive
URL parameters are inert. Select Dense, Standard or Spacious instead.
Dashboard remains Dense; Desktop remains Standard; Mobile remains Spacious.
Marketing now uses Spacious, Standard type scale and Pointer input.
Brand, color mode, type scale, input mode, window class and accessibility text
scaling remain independent.

See [Decision 0003](../decisions/0003-unified-density-composition.md) and the
matching `layout-composition`, `card-variants`, and `surface-tones` fixtures.
