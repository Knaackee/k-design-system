import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  const evidence = String.fromEnvironment('REFRESH_EVIDENCE_DIR');
  for (final size in [
    const Size(360, 740),
    const Size(393, 852),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 1.3, 2.0, 3.0]) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'refresh stays below shell controls $size text $scale $brightness',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
            tester.view.viewPadding = const FakeViewPadding(
              top: 59,
              bottom: 34,
            );
            addTearDown(tester.view.reset);
            final capture = GlobalKey();
            if (evidence.isNotEmpty) {
              await tester.runAsync(() async {
                final font = ByteData.sublistView(
                  await File('C:/Windows/Fonts/segoeui.ttf').readAsBytes(),
                );
                for (final family in [
                  'Roboto',
                  'CupertinoSystemText',
                  'CupertinoSystemDisplay',
                  '.SF UI Text',
                  '.SF UI Display',
                ]) {
                  await (FontLoader(
                    family,
                  )..addFont(Future.value(font))).load();
                }
              });
            }
            final refresh = Completer<void>();
            var calls = 0;
            await tester.pumpWidget(
              RepaintBoundary(
                key: capture,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: kDesignTheme(brightness: brightness),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: KAdaptiveTheme(child: child!),
                  ),
                  home: Scaffold(
                    body: KAppShell(
                      selectedId: 'list',
                      onSelected: (_) {},
                      destinations: const [
                        KAppDestination(
                          id: 'list',
                          label: 'List',
                          icon: KIconName.list,
                        ),
                        KAppDestination(
                          id: 'settings',
                          label: 'Settings',
                          icon: KIconName.settings,
                        ),
                      ],
                      child: KPage(
                        onRefresh: () {
                          calls++;
                          return refresh.future;
                        },
                        children: [
                          KPageHeader(
                            title: 'Objects',
                            actions: [
                              KButton(
                                label: 'Add',
                                leading: const KIcon(KIconName.plus),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          KList(
                            children: [
                              for (var i = 0; i < 20; i++)
                                KListItem(title: 'Object $i', onPressed: () {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final page = find.byType(KPage);
            final visibleTop = MediaQuery.paddingOf(tester.element(page)).top;
            await tester.drag(
              find.descendant(of: page, matching: find.byType(Scrollable)),
              const Offset(0, 500),
            );
            for (var frame = 0; frame < 60; frame++) {
              await tester.pump(const Duration(milliseconds: 16));
            }
            expect(calls, 1);
            final indicator =
                Theme.of(tester.element(page)).platform == TargetPlatform.iOS
                ? find.byType(CupertinoActivityIndicator)
                : find.byType(RefreshProgressIndicator);
            expect(indicator, findsOneWidget);
            expect(
              tester.getRect(indicator).top,
              greaterThanOrEqualTo(visibleTop),
              reason: 'The active spinner must clear the status and action bar',
            );
            if (evidence.isNotEmpty &&
                size.width == 393 &&
                scale == 1 &&
                Theme.of(tester.element(page)).platform == TargetPlatform.iOS) {
              await tester.runAsync(() async {
                final boundary =
                    capture.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  '$evidence/refresh-ios-${brightness.name}.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            refresh.complete();
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
          variant: TargetPlatformVariant({
            TargetPlatform.iOS,
            TargetPlatform.android,
          }),
        );
      }
    }
  }
}
