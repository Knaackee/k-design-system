# Chat bubble / FAB

`KChatBubble` supplies the round content surface. `KFab` adds an upward menu and
optional attention notices. Placement, content and acknowledgement belong to the
consumer; no agent or account data is built into the component.

## Activation

- `press`: the main action toggles the menu.
- `longPress`: short press invokes the main action; long press toggles the menu.
- Secondary mouse click toggles the menu. Keyboard users can use Arrow Up or Shift+F10 and dismiss with Escape.
- `itemGap` controls spacing between menu bubbles and the main trigger. Default: 8 logical pixels on both platforms. Negative and non-finite values are normalized.
- Menu contents are mounted before the first opening and retained when closed, allowing asynchronous avatars to prepare once. Hidden items cannot receive input or accessibility focus. The consumer owns asset caching and should keep item IDs stable.
- Tasks supplies only secondary agents as menu items: the main agent remains the main bubble. Accessible names are preserved without duplicate hover tooltips.

## Attention

Supply notices with `id` and `itemId`. Append a new notice last; it immediately
replaces the current pulse. Outstanding notices then rotate until the consumer
removes them. Selecting a notice emits its identity and invokes the item's action.
No label is required beyond the item's accessible label.

| Web                     | Flutter                  | Default                              |
| ----------------------- | ------------------------ | ------------------------------------ |
| `attentionPeekFraction` | `attentionPeekFraction`  | 0.5 of bubble height; clamped to 0–1 |
| `attentionHoldMs`       | `attentionHoldDuration`  | 324 ms at the highest point          |
| `attentionShowMs`       | `attentionShowDuration`  | 1800 ms for the entire pulse         |
| `attentionPauseMs`      | `attentionPauseDuration` | 7000 ms between pulses               |

The total duration is at least the hold duration plus 600 ms for movement.
The default animation rises for 432 ms, holds for 324 ms, falls for 360 ms,
then bounces with decreasing peaks (36%, 14%, 4% of the configured height).
Both platforms use the same cubic curves and relative phase timings.

Hover/focus holds the notice at its peak for selection. Opening the menu pauses
the attention presentation. Reduced motion shows a stationary peek.

Storybook and Widgetbook expose matching Stern/Herz impulse buttons and controls
for peek height and hold duration. These are design-system demos; Tasks integration
is a separate step after visual acceptance.

## Browser timing regression

Run `flutter test --platform chrome test/fab_test.dart` from the Flutter UI
package as well as the native tests when changing timing. Dart's JavaScript
target evaluates `1 << 62` to zero; using it as a duration clamp limit removed
both the hold and the repetition pause in Widgetbook while native tests passed.
Use a nonnegative minimum check without that bit-shift upper bound.
