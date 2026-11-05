# Wrong / right pairs

Use these to diagnose. The wrong halves are never starting points.

## Card in a card

```dart
// Wrong: KPI tiles as cards inside a card.
KCard(child: Wrap(children: [for (final k in kpis) KCard(child: KpiTile(k))]))

// Right: tiles are subtle surfaces; the outer card owns the border.
KCard(child: Wrap(children: [
  for (final k in kpis)
    KSurface(tone: KSurfaceTone.subtle, border: KSurfaceBorder.none,
        child: Padding(padding: EdgeInsets.all(t.spaceControlInsetInline),
            child: KpiTile(k))),
]))
```

## Floating icon

```dart
// Wrong: the icon centres on title + subtitle.
Row(children: [KIcon(KIconName.user), Expanded(child: Column(children: [title, subtitle]))])

// Right: the icon sits on the title line.
Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
  KLeading.icon(KIconName.user, textVariant: KTextVariant.label),
  SizedBox(width: t.spaceControlGap),
  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [title, subtitle])),
])
```

## Blown-up phone

```dart
// Wrong: chosen per platform at build time.
theme: kDesignTheme(configuration: KDesignConfiguration.mobileApp)

// Right: resolved from the window; tablets and split view adapt too.
builder: (context, child) => KAdaptiveTheme(child: child!)
```

## Row that overflows at 1.3× text

```dart
// Wrong
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [KText('Systemanweisung'), KText('137 Zeichen')])

// Right
KInline(gap: KLayoutGap.control, wrap: true,
    children: [KText('Systemanweisung'), KText('137 Zeichen')])
```

## Raw values

```dart
// Wrong
Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 4), child: header)
KIcon(KIconName.user, size: 18)

// Right
Padding(padding: EdgeInsets.fromLTRB(t.spaceControlGap, t.spaceControlGap,
    t.spaceControlGap, t.spaceTight), child: header)
KIcon(KIconName.user, size: 20)
```

## One card per list item

```tsx
// Wrong
{
  items.map((i) => <KCard key={i.id}>{i.name}</KCard>);
}

// Right: one grouped list
<KSurface radius="card">
  <KList>
    {items.map((i) => (
      <KListItem key={i.id} title={i.name} onClick={() => open(i.id)} />
    ))}
  </KList>
</KSurface>;
```

## Dropdown as navigation

```dart
// Wrong: a select that swaps the page body between "Planung" and "Kennungen".
// Right: section rows on the detail page that open their own pages,
// or a KSegmentedControl (two to five options) for peer views of the same
// content.
```
