import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_style.dart';
import 'package:k_design_widgetbook/map_fixture.dart';

void main() {
  testWidgets('map session survives a light-dark fixture remount and resets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = MapFixtureSession()
      ..center = const KMapCenter(longitude: 13.4, latitude: 52.52)
      ..zoom = 15
      ..settings = const KMapSettings(showPois: false)
      ..tokenOverrides['background'] = '#123456';
    late Map<String, dynamic> renderedStyle;

    Widget fixture(Brightness brightness) => MaterialApp(
      theme: kDesignTheme(brightness: brightness),
      home: Scaffold(
        body: KeyedSubtree(
          key: ValueKey(brightness),
          child: MapFixture(
            session: session,
            mapBuilder:
                ({
                  required session,
                  required style,
                  required height,
                  required onViewChange,
                }) {
                  renderedStyle = jsonDecode(style) as Map<String, dynamic>;
                  return SizedBox(height: height);
                },
          ),
        ),
      ),
    );

    await tester.pumpWidget(fixture(Brightness.light));
    final lightStyle = jsonEncode(renderedStyle);
    expect(lightStyle, contains('#123456'));
    expect(
      lightStyle,
      contains(KMapTokens.fromTokens(KDesignTokens.orbitLight).water),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(fixture(Brightness.dark));
    final darkStyle = jsonEncode(renderedStyle);
    expect(darkStyle, contains('#123456'));
    expect(
      darkStyle,
      contains(KMapTokens.fromTokens(KDesignTokens.orbitDark).water),
    );
    expect(session.center, const KMapCenter(longitude: 13.4, latitude: 52.52));
    expect(session.zoom, 15);
    expect(session.settings.showPois, isFalse);
    expect(session.tokenOverrides['background'], '#123456');

    session.reset();
    expect(
      session.center,
      const KMapCenter(longitude: 13.388, latitude: 52.517),
    );
    expect(session.zoom, 14);
    expect(session.settings, const KMapSettings());
    expect(session.tokenOverrides, isEmpty);
  });
}
