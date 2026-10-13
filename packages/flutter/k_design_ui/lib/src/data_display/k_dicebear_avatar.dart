import 'dart:collection';
import 'dart:convert';

import 'package:dicebear_core/dicebear_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../basic_display.dart';
import 'k_dicebear_catalog.g.dart';
import 'k_dicebear_motion.dart';

export 'k_dicebear_catalog.g.dart'
    show kDiceBearAnimatedStyleIds, kDiceBearStyleIds;

final Map<String, Future<Style>> _styleCache = {};
final LinkedHashMap<String, Future<String>> _svgCache = LinkedHashMap();
final LinkedHashMap<String, KDiceBearMotionScene> _motionSceneCache =
    LinkedHashMap();
const int _maximumCachedSvgs = 256;
const int _maximumCachedMotionScenes = 128;

/// Loads and validates one approved DiceBear style definition on demand.
Future<Style> loadKDiceBearStyle(String styleId) {
  final assetPath = kDiceBearStyleAssetPaths[styleId];
  if (assetPath == null) {
    return Future.error(
      ArgumentError.value(styleId, 'styleId', 'Unsupported DiceBear style'),
    );
  }

  return _styleCache.putIfAbsent(styleId, () async {
    try {
      return Style.parse(await rootBundle.loadString(assetPath));
    } catch (_) {
      _styleCache.remove(styleId);
      rethrow;
    }
  });
}

/// Returns the complete option schema exposed by the selected style.
Future<Map<String, Object?>> getKDiceBearOptions(String styleId) async =>
    OptionsDescriptor(await loadKDiceBearStyle(styleId)).toJson();

/// License and attribution data embedded in an approved style definition.
class KDiceBearStyleMetadata {
  const KDiceBearStyleMetadata({
    required this.sourceName,
    required this.sourceUrl,
    required this.creatorName,
    required this.creatorUrl,
    required this.licenseName,
    required this.licenseUrl,
    required this.licenseText,
  });

  final String? sourceName;
  final String? sourceUrl;
  final String? creatorName;
  final String? creatorUrl;
  final String? licenseName;
  final String? licenseUrl;
  final String? licenseText;
}

/// Returns the complete attribution and license metadata for a style.
Future<KDiceBearStyleMetadata> getKDiceBearMetadata(String styleId) async {
  final meta = (await loadKDiceBearStyle(styleId)).meta;
  return KDiceBearStyleMetadata(
    sourceName: meta.source().name(),
    sourceUrl: meta.source().url(),
    creatorName: meta.creator().name(),
    creatorUrl: meta.creator().url(),
    licenseName: meta.license().name(),
    licenseUrl: meta.license().url(),
    licenseText: meta.license().text(),
  );
}

/// Renders a deterministic SVG locally and memoizes it by style, seed, and options.
Future<String> renderKDiceBearAvatarSvg({
  required String styleId,
  required String seed,
  Map<String, Object?> options = const {},
}) {
  final optionsSnapshot = (_canonicalJsonValue(options) as Map)
      .cast<String, Object?>();
  final key = jsonEncode([styleId, seed, optionsSnapshot]);
  final cached = _svgCache.remove(key);
  if (cached != null) {
    _svgCache[key] = cached;
    return cached;
  }
  late final Future<String> rendered;
  rendered = (() async {
    try {
      final style = await loadKDiceBearStyle(styleId);
      return Avatar(style, {
        ...optionsSnapshot,
        'seed': seed,
        'idRandomization': false,
      }).svg;
    } catch (_) {
      if (identical(_svgCache[key], rendered)) _svgCache.remove(key);
      rethrow;
    }
  })();
  _svgCache[key] = rendered;
  if (_svgCache.length > _maximumCachedSvgs) {
    _svgCache.remove(_svgCache.keys.first);
  }
  return rendered;
}

/// A locally rendered DiceBear avatar in the standard [KAvatar] frame.
class KDiceBearAvatar extends StatelessWidget {
  const KDiceBearAvatar({
    required this.styleId,
    required this.seed,
    required this.alt,
    this.options = const {},
    this.size = KAvatarSize.standard,
    this.dimension,
    this.fallback,
    this.errorBuilder,
    this.badge,
    this.motionPaused = false,
    super.key,
  }) : assert(
         dimension == null || (dimension > 0 && dimension < double.infinity),
         'dimension must be a positive finite number',
       );

  final String styleId;
  final String seed;
  final String alt;
  final Map<String, Object?> options;
  final KAvatarSize size;

  /// Overrides the token size for gallery and product-specific compositions.
  final double? dimension;
  final Widget? fallback;
  final Widget Function(BuildContext context, Object error, StackTrace? stack)?
  errorBuilder;
  final Widget? badge;

  /// Freezes or resumes opt-in DiceBear animation at its current frame.
  ///
  /// Motion also stops when the platform requests reduced motion or an ancestor
  /// [TickerMode] is disabled. Styles without an `animationVariant` do not tick.
  final bool motionPaused;

  @override
  Widget build(BuildContext context) {
    final avatar = FutureBuilder<KDiceBearMotionScene>(
      future: _renderKDiceBearMotionScene(
        styleId: styleId,
        seed: seed,
        options: options,
      ),
      builder: (context, snapshot) => Semantics(
        image: true,
        label: alt,
        child: ExcludeSemantics(
          child: KAvatar(
            alt: alt,
            size: size,
            badge: badge,
            fallback: switch (snapshot) {
              AsyncSnapshot<KDiceBearMotionScene>(hasData: true) =>
                KDiceBearMotion(
                  scene: snapshot.requireData,
                  paused: motionPaused,
                ),
              AsyncSnapshot<KDiceBearMotionScene>(hasError: true)
                  when errorBuilder != null =>
                errorBuilder!(context, snapshot.error!, snapshot.stackTrace),
              _ => fallback,
            },
          ),
        ),
      ),
    );
    final requestedDimension = dimension;
    if (requestedDimension == null) return avatar;
    return SizedBox.square(
      dimension: requestedDimension,
      child: FittedBox(fit: BoxFit.fill, child: avatar),
    );
  }
}

Future<KDiceBearMotionScene> _renderKDiceBearMotionScene({
  required String styleId,
  required String seed,
  required Map<String, Object?> options,
}) async {
  final svg = await renderKDiceBearAvatarSvg(
    styleId: styleId,
    seed: seed,
    options: options,
  );
  final cached = _motionSceneCache.remove(svg);
  if (cached != null) {
    _motionSceneCache[svg] = cached;
    return cached;
  }
  final scene = KDiceBearMotionScene.parse(svg);
  _motionSceneCache[svg] = scene;
  if (_motionSceneCache.length > _maximumCachedMotionScenes) {
    _motionSceneCache.remove(_motionSceneCache.keys.first);
  }
  return scene;
}

Object? _canonicalJsonValue(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalJsonValue(value[key]),
    };
  }
  if (value is List) {
    return [for (final item in value) _canonicalJsonValue(item)];
  }
  return value;
}
