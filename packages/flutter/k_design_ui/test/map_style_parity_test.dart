import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_map_style.dart';

void main() {
  final fixtures =
      jsonDecode(File('test/fixtures/map-style-parity.json').readAsStringSync())
          as Map<String, dynamic>;

  test('matches the Web style builder for light and dark token defaults', () {
    expect(
      _canonicalize(createKMapStyle(tokens: kDesignTokens())),
      _canonicalize(fixtures['lightDefault']),
    );
    expect(
      _canonicalize(
        createKMapStyle(tokens: kDesignTokens(brightness: Brightness.dark)),
      ),
      _canonicalize(fixtures['darkDefault']),
    );
  });

  test(
    'matches Web for comprehensive settings, source, and token overrides',
    () {
      final style = createKMapStyle(
        tokens: kDesignTokens(),
        settings: const KMapSettings(
          lang: 'en',
          roadWidthScale: 1.35,
          casingScale: 0.7,
          labelScale: 1.2,
          haloWidth: 2.1,
          showLanduse: false,
          showBuildings: false,
          buildingMinZoom: 16,
          showRail: false,
          showPaths: false,
          showPois: false,
          poiMinZoom: 17,
          poiMaxRank: 7,
          poiDotScale: 1.6,
          roadLabelMinZoom: 14.5,
          showQuarterLabels: false,
        ),
        sources: const KMapSources(
          tiles: 'https://example.test/tiles.json',
          glyphs: 'https://example.test/fonts/{fontstack}/{range}.pbf',
          attribution: 'Example attribution',
        ),
        tokenOverrides: const {
          'background': '#010203',
          'road': '#ABCDEF',
          'tunnelOpacity': 0.72,
          'fontRegular': ['Example Regular', 'Fallback Regular'],
          'fontBold': ['Example Bold'],
          'fontItalic': ['Example Italic'],
        },
      );
      expect(_canonicalize(style), _canonicalize(fixtures['custom']));
    },
  );

  test('map token metadata resolves every generated-token-backed value', () {
    final tokens = KMapTokens.fromTokens(kDesignTokens());
    expect(kMapTokenMetadata, hasLength(tokens.toMap().length));
    expect({
      for (final metadata in kMapTokenMetadata)
        metadata.key: metadata.valueFrom(tokens),
    }, tokens.toMap());
  });

  test('normalizes editor text overrides and rejects invalid opacity', () {
    final tokens = KMapTokens.fromTokens(kDesignTokens()).withOverrides(const {
      'tunnelOpacity': '0.75',
      'fontRegular': 'Example Regular, Fallback Regular',
    });
    expect(tokens.tunnelOpacity, 0.75);
    expect(tokens.fontRegular, ['Example Regular', 'Fallback Regular']);
    expect(
      () => tokens.withOverrides(const {'tunnelOpacity': double.infinity}),
      throwsArgumentError,
    );
    expect(
      () => tokens.withOverrides(const {'tunnelOpacity': 1.1}),
      throwsArgumentError,
    );
  });
}

Object? _canonicalize(Object? value) {
  if (value case final String text
      when RegExp(r'^#[0-9a-fA-F]{6,8}$').hasMatch(text)) {
    return text.toUpperCase();
  }
  if (value is List) return value.map(_canonicalize).toList();
  if (value is Map) {
    return value.map((key, item) => MapEntry(key, _canonicalize(item)));
  }
  return value;
}
