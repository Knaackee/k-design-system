# Timeline and Gantt

`KTimeline` and `KGantt` are controlled planning components available from the
public Web and Flutter UI packages. The consumer owns canonical records,
selection, expanded groups and date windows. Dragging and resizing emit proposals;
the component changes only after the consumer supplies accepted records back.

Both platforms use stable string IDs and date-only, half-open ranges: `start` is
included and `end` is excluded. A missing end represents a point or milestone.
Temporary interaction previews never become application data by themselves.

## Web

Import the component and model types from the package root. Import the package
stylesheet once at the application root.

```tsx
import "@k-design-system/ui/styles.css";
import { KTimeline, type KTimelineItem } from "@k-design-system/ui";

<KTimeline
  items={items satisfies readonly KTimelineItem[]}
  groups={groups}
  selectedId={selectedId}
  onSelect={setSelectedId}
  onItemOpen={openDetails}
  onPropose={acceptOrRejectProposal}
  window={visibleWindow}
  onWindowChange={setVisibleWindow}
  today="2026-09-25"
/>;
```

## Flutter

```dart
KTimeline(
  items: items,
  groups: groups,
  selectedId: selectedId,
  onSelect: selectItem,
  onItemOpen: openDetails,
  onPropose: acceptOrRejectProposal,
  windowStart: windowStart,
  windowEnd: windowEnd,
  onWindowChange: setWindow,
  today: DateTime(2026, 9, 25),
)
```

Compact views distinguish scrolling, short activation and long-press editing.
Keyboard and date-field alternatives remain necessary when a host builds a full
editing screen around either component.
