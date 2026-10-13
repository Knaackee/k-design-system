import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class DiceBearAvatarFixture extends StatelessWidget {
  const DiceBearAvatarFixture({
    required this.styleId,
    required this.seed,
    this.options = const {},
    this.size = KAvatarSize.large,
    this.motionPaused = false,
    super.key,
  });

  final String styleId;
  final String seed;
  final Map<String, Object?> options;
  final KAvatarSize size;
  final bool motionPaused;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLayoutGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KDiceBearAvatar(
            styleId: styleId,
            seed: seed,
            options: options,
            alt: '$styleId: $seed',
            size: size,
            dimension: 160,
            motionPaused: motionPaused,
            errorBuilder: (_, error, _) => Tooltip(
              message: error.toString(),
              child: const KIcon(KIconName.circleAlert, label: 'Avatar error'),
            ),
          ),
          SizedBox(height: tokens.spaceLayoutSectionGap),
          Wrap(
            spacing: tokens.spaceContentActionGap,
            runSpacing: tokens.spaceContentActionGap,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              for (final avatarSize in KAvatarSize.values)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KDiceBearAvatar(
                      styleId: styleId,
                      seed: seed,
                      options: options,
                      alt: '$styleId: $seed (${avatarSize.name})',
                      size: avatarSize,
                      motionPaused: motionPaused,
                    ),
                    SizedBox(height: tokens.spaceTight),
                    KText(
                      '${avatarSize.name}${avatarSize == size ? ' · selected' : ''}',
                      variant: KTextVariant.label,
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: tokens.spaceLayoutSectionGap),
          KText(styleId, variant: KTextVariant.heading5),
          SizedBox(height: tokens.spaceControlGap),
          _StyleDetails(styleId: styleId),
          SizedBox(height: tokens.spaceContentActionGap),
          const KText(
            'Animated styles use DiceBear keyframes with native motion. '
            'Glass and Marbles render without their SVG blur filters.',
            variant: KTextVariant.bodySmall,
          ),
        ],
      ),
    );
  }
}

class DiceBearAvatarCatalogueFixture extends StatelessWidget {
  const DiceBearAvatarCatalogueFixture({
    this.seed = 'K Design System',
    super.key,
  });

  final String seed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLayoutGutter),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: tokens.spaceLayoutSectionGap,
          runSpacing: tokens.spaceLayoutSectionGap,
          children: [
            for (final styleId in kDiceBearStyleIds)
              SizedBox(
                width: constraints.maxWidth < 520 ? constraints.maxWidth : 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KDiceBearAvatar(
                      styleId: styleId,
                      seed: seed,
                      alt: '$styleId: $seed',
                      dimension: 96,
                    ),
                    SizedBox(height: tokens.spaceControlGap),
                    KText(styleId),
                    _StyleAttribution(styleId: styleId),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StyleDetails extends StatelessWidget {
  const _StyleDetails({required this.styleId});

  final String styleId;

  @override
  Widget build(BuildContext context) => FutureBuilder<_StyleDetailsData>(
    future: _loadStyleDetails(styleId),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text('Unable to load: ${snapshot.error}');
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final data = snapshot.requireData;
      final meta = data.metadata;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _metadataLink(meta.sourceName, meta.sourceUrl),
              const KText('by'),
              _metadataLink(meta.creatorName, meta.creatorUrl),
              const KText('·'),
              _metadataLink(meta.licenseName, meta.licenseUrl),
            ],
          ),
          if (meta.licenseName == 'CC BY 4.0')
            const KText(
              'Generated remix; retain attribution when using this artwork.',
              variant: KTextVariant.label,
            ),
          if (meta.licenseText != null)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('${meta.licenseName} license text'),
              children: [SelectableText(meta.licenseText!)],
            ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Available DiceBear options'),
            children: [
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(data.options),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _StyleAttribution extends StatelessWidget {
  const _StyleAttribution({required this.styleId});

  final String styleId;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: getKDiceBearMetadata(styleId),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox(height: 16);
      final meta = snapshot.requireData;
      return KText(
        '${meta.sourceName} by ${meta.creatorName} · ${meta.licenseName}',
        variant: KTextVariant.bodySmall,
      );
    },
  );
}

typedef _StyleDetailsData = ({
  KDiceBearStyleMetadata metadata,
  Map<String, Object?> options,
});

Future<_StyleDetailsData> _loadStyleDetails(String styleId) async => (
  metadata: await getKDiceBearMetadata(styleId),
  options: await getKDiceBearOptions(styleId),
);

Widget _metadataLink(String? label, String? url) => Tooltip(
  message: url ?? '',
  child: KLink(
    label: label ?? 'Unknown',
    external: url != null,
    onPressed: url == null ? null : () => unawaited(launchUrl(Uri.parse(url))),
  ),
);

Map<String, Object?> parseDiceBearOptions(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw const FormatException('Options must be a JSON object.');
  }
  return decoded.cast<String, Object?>();
}
