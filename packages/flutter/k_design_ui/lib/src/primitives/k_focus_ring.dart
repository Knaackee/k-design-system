import 'package:flutter/widgets.dart';

/// Whether a focus ring shows for [states] (Decision 0015).
///
/// Only keyboard and switch access show the ring, as `:focus-visible` on
/// the Web: after a tap, focus that returns to a trigger (a menu closes)
/// stays invisible.
bool kFocusVisible(Set<WidgetState> states) =>
    states.contains(WidgetState.focused) &&
    FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
