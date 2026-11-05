# Adaptive setup

The library resolves density, type ramp, input mode and window class from the
running environment (Decision 0010). Apps set it up once.

## Flutter

```dart
MaterialApp(
  builder: (context, child) => KAdaptiveTheme(
    brand: KBrand.orbit,
    // Pin axes only for a product reason, e.g. a data-dense admin screen:
    // overrides: const KAdaptiveOverrides(density: KDensity.dense),
    child: child!,
  ),
  home: const AppShell(),
);
```

- `KAdaptiveTheme` re-resolves when the window resizes (tablets, split view),
  applies the theme and caps system text scaling.
- Read the resolved axes with `KAdaptive.maybeOf(context)` to choose layouts
  (e.g. list-detail on `expanded`+), not `Platform.isIOS` or device names.
- Tests: wrap the widget under test in `KAdaptiveTheme` and set
  `tester.view.physicalSize` to 360×740 / 393×852.

## Web

```ts
import { applyKAdaptive } from "@k-design-system/ui";

const dispose = applyKAdaptive(document.documentElement);
// or for an embedded app root:
applyKAdaptive(rootElement, { density: "dense" });
```

- Uses the element's width and `(pointer: coarse)`; keeps `data-*` attributes
  in sync on resize.
- Apply an accessibility text size with `setKTextScale(root, scale)`: it sets
  `--k-text-scale` (capped per role) and `data-text-large` from 1.3× so rows
  stack like on Flutter.

## Motion style

```dart
KAdaptiveTheme(
  overrides: const KAdaptiveOverrides(motion: KMotionStyle.expressive),
  child: child!,
)
```

```ts
applyKAdaptive(document.documentElement, { motion: "expressive" });
```

`apple` is the default. The platform reduce-motion setting always resolves to
`reduced`. Ask the user which style a product wants before changing it.

## Parity rule

Tablet = desktop, mobile Web = mobile app. Only the window class picks the
type ramp; touch vs pointer only changes hit targets. A data-dense desktop
screen may opt into `KDesignConfiguration.dashboard` (dense + compact ramp) —
state the reason in the handover.

## What resolves to what

| Window (px) | Input | Type ramp | Gutter | Section gap |
| ----------- | ----- | --------- | ------ | ----------- |
| < 600       | any   | mobile    | 16     | 24          |
| 600–839     | any   | standard  | 24     | 32*         |
| 840+        | any   | standard  | 32–64  | 32*         |

\* standard density; dense 16, spacious 48.
