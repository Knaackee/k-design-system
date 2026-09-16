import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_widgetbook/gallery_navigation.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  test(
    'sorts new categories, nested folders and examples without changing URLs',
    () {
      WidgetbookUseCase fixture(String name) =>
          WidgetbookUseCase(name: name, builder: (_) => const SizedBox());
      final button = WidgetbookFolder(
        name: 'Button',
        children: [
          fixture('button-variants'),
          fixture('button-primary'),
          fixture('button-states'),
        ],
      );
      final primitives = WidgetbookCategory(
        name: 'Primitives',
        children: [
          WidgetbookFolder(
            name: 'Typography',
            children: [fixture('typography-scale')],
          ),
          button,
        ],
      );
      final nodes = <WidgetbookNode>[
        primitives,
        WidgetbookCategory(name: 'Patterns', children: [fixture('example')]),
      ];
      final paths = nodes
          .expand((node) => node.leaves)
          .map((node) => node.path)
          .toSet();
      sortGalleryNodes(nodes);
      expect(nodes.map((node) => node.name), ['Patterns', 'Primitives']);
      expect(primitives.children!.map((node) => node.name), [
        'Button',
        'Typography',
      ]);
      expect(button.children!.map((node) => node.name), [
        'button-primary',
        'button-states',
        'button-variants',
      ]);
      expect(
        nodes.expand((node) => node.leaves).map((node) => node.path).toSet(),
        paths,
      );
    },
  );
}
