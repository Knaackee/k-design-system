import 'package:widgetbook/widgetbook.dart';

/// Match Storybook: compare names case-insensitively at every tree level.
/// Sort in place so Widgetbook's parent links and fixture paths stay intact.
List<WidgetbookNode> sortGalleryNodes(List<WidgetbookNode> nodes) {
  nodes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  for (final node in nodes) {
    final children = node.children;
    if (children != null) sortGalleryNodes(children);
  }
  return nodes;
}
