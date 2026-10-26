import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final width in [360.0, 768.0, 1280.0]) {
    testWidgets('file hierarchy stays aligned at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      Future<void> showTree(bool siblingFolder) => tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(configuration: KDesignConfiguration.mobileApp),
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: KFileTree(
                nodes: [
                  const KFileNode(id: 'root', name: 'Root.txt'),
                  KFileNode(
                    id: 'folder',
                    name: 'Folder',
                    folder: true,
                    children: [
                      const KFileNode(id: 'child', name: 'Child.txt'),
                      if (siblingFolder)
                        const KFileNode(
                          id: 'nested',
                          name: 'Nested',
                          folder: true,
                          children: [KFileNode(id: 'leaf', name: 'Leaf.txt')],
                        ),
                    ],
                  ),
                ],
                expandedIds: const {'folder', 'nested'},
                onSelect: (_) {},
                onExpandedChange: (_) {},
              ),
            ),
          ),
        ),
      );
      await showTree(true);
      double x(String label) => tester.getTopLeft(find.text(label)).dx;
      expect(x('Root.txt'), x('Folder'));
      expect(x('Child.txt'), x('Nested'));
      expect(x('Child.txt'), greaterThan(x('Folder')));
      expect(x('Leaf.txt') - x('Child.txt'), x('Child.txt') - x('Folder'));
      final childPosition = x('Child.txt');
      await showTree(false);
      expect(x('Child.txt'), childPosition);
      expect(tester.takeException(), isNull);
    });
  }
}
