import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('failed omit stays open and can be retried after busy state', (
    tester,
  ) async {
    final first = Completer<void>();
    var attempts = 0;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KAvatarEditor(
            images: const [],
            onClose: () => closed = true,
            onApply: (_, _) {},
            onOmit: () {
              attempts++;
              return attempts == 1 ? first.future : Future<void>.value();
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Use no image'));
    await tester.pump();
    expect(closed, isFalse);
    expect(
      tester
          .widget<KButton>(find.widgetWithText(KButton, 'Use no image'))
          .onPressed,
      isNull,
    );
    first.completeError(StateError('fixture failure'));
    await tester.pumpAndSettle();
    expect(find.text(const KAvatarEditorLabels().error), findsOneWidget);
    expect(closed, isFalse);
    await tester.tap(find.text('Use no image'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });

  testWidgets('empty source picker is compact on a phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => KButton(
              label: 'Open',
              onPressed: () => KAdaptiveDialog.show<void>(
                context: context,
                builder: (context) => KAvatarEditor(
                  images: const [],
                  onClose: () => Navigator.of(context).pop(),
                  onApply: (_, _) {},
                  onOmit: () {},
                  onChoose: () async => null,
                  onCamera: () async => null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final sheet = find.byType(KBottomSheet);
    expect(tester.getSize(sheet).height, lessThan(380));
    expect(find.text('Choose image').hitTestable(), findsOneWidget);
    expect(find.text('Take photo').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Use no image'));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
  });

  testWidgets('oversized selection is rejected before crop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KAvatarEditor(
            images: const [],
            maxFileBytes: 2,
            onClose: () {},
            onApply: (_, _) {},
            onOmit: () {},
            onChoose: () async => KAvatarEditorFile(
              bytes: Uint8List(3),
              mimeType: 'image/png',
              name: 'too-big.png',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose image'));
    await tester.pumpAndSettle();
    expect(find.text(const KAvatarEditorLabels().invalidFile), findsOneWidget);
    expect(find.byType(KImageCropper), findsNothing);
  });
}
