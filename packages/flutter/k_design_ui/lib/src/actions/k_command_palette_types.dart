import 'dart:async';

import '../primitives/k_icon.dart';

class KCommandPaletteItem {
  const KCommandPaletteItem({
    required this.id,
    required this.label,
    this.description,
    this.keywords = const [],
    this.icon,
    this.shortcut = const [],
    this.group,
    this.disabled = false,
    this.priority = 0,
    this.closeOnInvoke = true,
    this.children = const [],
    this.metadata,
  });

  final String id;
  final String label;
  final String? description;
  final List<String> keywords;
  final KIconName? icon;
  final List<String> shortcut;
  final String? group;
  final bool disabled;
  final int priority;
  final bool closeOnInvoke;
  final List<KCommandPaletteItem> children;
  final Object? metadata;
}

class KCommandPaletteLabels {
  const KCommandPaletteLabels({
    this.title = 'Commands',
    this.searchPlaceholder = 'Search commands…',
    this.empty = 'No commands found',
    this.loading = 'Loading commands…',
    this.back = 'Back',
    this.close = 'Close command palette',
    this.navigate = 'Navigate',
    this.select = 'Select',
  });

  final String title;
  final String searchPlaceholder;
  final String empty;
  final String loading;
  final String back;
  final String close;
  final String navigate;
  final String select;
}

typedef KCommandPaletteCallback =
    FutureOr<void> Function(KCommandPaletteItem item);
