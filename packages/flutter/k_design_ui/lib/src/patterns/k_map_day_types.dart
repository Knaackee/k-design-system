import 'package:flutter/material.dart';

import '../primitives/k_icon.dart';

enum KMapDayItemKind { stop, travel }

enum KMapDayPresentation { auto, sidebar, sheet }

enum KMapDayPanelLayout { floating, docked }

enum KMapDayPanelState { compact, medium, expanded }

extension KMapDayPanelStateStep on KMapDayPanelState {
  KMapDayPanelState step(int delta) =>
      KMapDayPanelState.values[(index + delta).clamp(0, 2)];
}

@immutable
class KMapDayAction {
  const KMapDayAction({required this.id, required this.label, this.icon});

  final String id;
  final String label;
  final KIconName? icon;
}

@immutable
class KMapDayItem {
  const KMapDayItem({
    required this.id,
    required this.start,
    required this.end,
    required this.title,
    required this.detail,
    required this.icon,
    required this.kind,
    this.routeDescription,
    this.expectedStart,
    this.actions = const [],
  }) : assert(end >= start),
       assert(expectedStart == null || expectedStart >= 0);

  final String id;
  final int start;
  final int end;
  final int? expectedStart;
  final String title;
  final String detail;
  final String? routeDescription;
  final KIconName icon;
  final KMapDayItemKind kind;
  final List<KMapDayAction> actions;
}

@immutable
class KMapDayPanelHeights {
  const KMapDayPanelHeights({
    this.compact = .28,
    this.medium = .62,
    this.expanded = .91,
  }) : assert(compact > 0 && compact < medium),
       assert(medium < expanded && expanded <= 1);

  final double compact;
  final double medium;
  final double expanded;

  double forState(KMapDayPanelState state) => switch (state) {
    KMapDayPanelState.compact => compact,
    KMapDayPanelState.medium => medium,
    KMapDayPanelState.expanded => expanded,
  };
}

@immutable
class KMapDayLabels {
  const KMapDayLabels({
    this.panel = 'Tagesablauf',
    this.resize = 'Höhe des Tagesablaufs',
    this.smaller = 'Ansicht verkleinern',
    this.larger = 'Ansicht vergrößern',
    this.compact = 'Kompakt',
    this.medium = 'Halb geöffnet',
    this.expanded = 'Vollständig geöffnet',
    this.now = 'Jetzt laut Plan',
    this.outside = 'Außerhalb der geplanten Zeiten',
    this.expected = 'Erwartet',
    this.later = 'später',
    this.earlier = 'früher',
    this.minutes = 'Min.',
  });

  final String panel;
  final String resize;
  final String smaller;
  final String larger;
  final String compact;
  final String medium;
  final String expanded;
  final String now;
  final String outside;
  final String expected;
  final String later;
  final String earlier;
  final String minutes;

  String panelState(KMapDayPanelState state) => switch (state) {
    KMapDayPanelState.compact => compact,
    KMapDayPanelState.medium => medium,
    KMapDayPanelState.expanded => expanded,
  };
}

@immutable
class KMapDayMapContext {
  const KMapDayMapContext({
    required this.selectedItemId,
    required this.onItemTap,
  });

  final String? selectedItemId;
  final ValueChanged<String> onItemTap;
}

@immutable
class KMapDayActionEvent {
  const KMapDayActionEvent({required this.itemId, required this.actionId});

  final String itemId;
  final String actionId;
}

typedef KMapDayMapBuilder =
    Widget Function(BuildContext context, KMapDayMapContext mapContext);
typedef KMapDayItemBuilder =
    Widget Function(BuildContext context, KMapDayItem item);
typedef KMapDayTimeFormatter = String Function(int minutes);

/// Product content inside the library-owned scrolling panel and draggable sheet.
@immutable
class KMapDayPanelContext {
  const KMapDayPanelContext({
    required this.isSheet,
    required this.expanded,
    required this.toggleExpanded,
    required this.selectedItemId,
    required this.onItemTap,
  });
  final bool isSheet, expanded;
  final VoidCallback toggleExpanded;
  final String? selectedItemId;
  final ValueChanged<String> onItemTap;
}

typedef KMapDayPanelHeaderBuilder =
    Widget? Function(BuildContext context, KMapDayPanelContext panel);
typedef KMapDayPanelBodyBuilder =
    Widget Function(BuildContext context, KMapDayPanelContext panel);
