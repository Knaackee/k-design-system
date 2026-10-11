import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'chat_presentation_image.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_text.dart';

export 'chat_presentation_collection.dart';

part 'chat_presentation_timeline.dart';
part 'chat_presentation_cover.dart';

enum KPresentationCardVariant { standard, cover }

class KPresentationImage {
  const KPresentationImage({
    required this.src,
    required this.alt,
    this.thumbnailSrc,
    this.caption,
    this.fit = BoxFit.cover,
  });
  final String src;
  final String alt;
  final String? thumbnailSrc;
  final String? caption;
  final BoxFit fit;
}

class KPresentationAction {
  const KPresentationAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
}

/// Presentation only; consumers own navigation and content permissions.
class KPresentationCard extends StatelessWidget {
  const KPresentationCard({
    required this.title,
    this.description,
    this.eyebrow,
    this.image,
    this.variant = KPresentationCardVariant.standard,
    this.action,
    super.key,
  });
  final String title;
  final String? description;
  final String? eyebrow;
  final KPresentationImage? image;
  final KPresentationCardVariant variant;
  final KPresentationAction? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final cover = variant == KPresentationCardVariant.cover;
    final gap = t.spaceControlGap;
    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        gap * 2,
        cover ? 120 : gap * 2,
        gap * 2,
        gap * 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            _meta(eyebrow!, t, cover: cover),
            SizedBox(height: gap),
          ],
          KText(
            title,
            variant: KTextVariant.heading4,
            style: cover
                ? TextStyle(color: t.componentPresentationCoverForeground)
                : null,
          ),
          if (description != null) ...[
            SizedBox(height: gap),
            KText(
              description!,
              style: TextStyle(
                color: cover
                    ? t.componentPresentationCoverMuted
                    : t.colorTextMuted,
              ),
            ),
          ],
          if (action != null) ...[
            SizedBox(height: gap * 2),
            KButton(
              label: action!.label,
              onPressed: action!.onPressed,
              variant: KButtonVariant.secondary,
              trailing: const KIcon(KIconName.arrowUpRight),
            ),
          ],
        ],
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radiusCard),
      child: _surface(
        cover
            ? Stack(
                children: [
                  Positioned.fill(
                    child: image == null
                        ? SizedBox.shrink()
                        : _image(image!.src, alt: image!.alt, fit: image!.fit),
                  ),
                  _CoverFrame(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color.fromRGBO(0, 0, 0, .84),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [body],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (image != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _image(
                        image!.src,
                        alt: image!.alt,
                        fit: image!.fit,
                      ),
                    ),
                  body,
                ],
              ),
      ),
    );
  }
}

class KPresentationReference extends StatelessWidget {
  const KPresentationReference({
    required this.title,
    required this.metadata,
    required this.onOpen,
    this.icon = KIconName.fileText,
    this.image,
    super.key,
  });
  final String title;
  final String metadata;
  final VoidCallback onOpen;
  final KIconName icon;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final gap = t.spaceControlGap * 1.5;
    return TextButton(
      onPressed: onOpen,
      style: ButtonStyle(
        alignment: AlignmentDirectional.centerStart,
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        padding: WidgetStatePropertyAll(EdgeInsets.all(gap)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? t.colorSurfaceSubtle
              : t.colorSurfaceRaised,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.focused)
                ? t.colorTextPrimary
                : t.colorBorderDefault,
            width: states.contains(WidgetState.focused)
                ? 2
                : t.borderWidthDefault,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusCard),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: t.componentPresentationActionSize,
            height: t.componentPresentationActionSize,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: t.colorSurfaceSubtle,
              borderRadius: BorderRadius.circular(t.radiusControl),
            ),
            child: image == null
                ? Center(child: KIcon(icon, size: 20))
                : _image(image!),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _strong(title, t),
                SizedBox(height: t.spaceControlGap * .5),
                _meta(metadata, t),
              ],
            ),
          ),
          SizedBox(width: gap),
          const KIcon(KIconName.arrowUpRight),
        ],
      ),
    );
  }
}

class KPresentationParty {
  const KPresentationParty({required this.name, this.image, this.detail});
  final String name;
  final String? image;
  final String? detail;
}

class KPresentationComparison extends StatelessWidget {
  const KPresentationComparison({
    required this.label,
    required this.left,
    required this.right,
    required this.value,
    this.detail,
    super.key,
  });
  final String label;
  final KPresentationParty left;
  final KPresentationParty right;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final gap = t.spaceControlGap;
    Widget party(KPresentationParty item) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.image != null) ...[
          SizedBox(
            width: t.componentPresentationWeatherIconSize,
            height: t.componentPresentationWeatherIconSize,
            child: _image(item.image!, fit: BoxFit.contain),
          ),
          SizedBox(height: gap),
        ],
        _strong(item.name, t, align: TextAlign.center),
        if (item.detail != null) ...[
          SizedBox(height: gap),
          _meta(item.detail!, t, align: TextAlign.center),
        ],
      ],
    );
    return _paddedSurface(
      t,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _meta(label, t),
          Padding(
            padding: EdgeInsets.symmetric(vertical: gap * 2),
            child: Row(
              children: [
                Expanded(child: party(left)),
                SizedBox(width: gap),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _value(value, t),
                      if (detail != null) ...[
                        SizedBox(height: gap),
                        _meta(detail!, t, align: TextAlign.center),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: gap),
                Expanded(child: party(right)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KPresentationMetric {
  const KPresentationMetric({required this.label, required this.value});
  final String label;
  final String value;
}

class KPresentationMetrics extends StatelessWidget {
  const KPresentationMetrics({
    required this.label,
    required this.value,
    required this.metrics,
    this.description,
    this.icon,
    super.key,
  });
  final String label;
  final String value;
  final String? description;
  final KIconName? icon;
  final List<KPresentationMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final gap = t.spaceControlGap;
    return _paddedSurface(
      t,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _meta(label, t),
          Padding(
            padding: EdgeInsets.symmetric(vertical: gap),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _value(value, t)),
                if (icon != null) KIcon(icon!, size: 36),
              ],
            ),
          ),
          if (description != null)
            KText(description!, style: TextStyle(color: t.colorTextMuted)),
          SizedBox(height: gap * 2),
          Wrap(
            spacing: gap * 3,
            runSpacing: gap * 3,
            children: [
              for (final metric in metrics)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_meta(metric.label, t), _strong(metric.value, t)],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _surface(Widget child) =>
    KSurface(radius: KSurfaceRadius.card, child: child);
Widget _paddedSurface(KDesignTokens t, Widget child) => _surface(
  Padding(padding: EdgeInsets.all(t.spaceControlGap * 2), child: child),
);
Widget _meta(
  String text,
  KDesignTokens t, {
  bool cover = false,
  TextAlign? align,
}) => KText(
  text,
  variant: KTextVariant.caption,
  align: align,
  style: TextStyle(
    color: cover ? t.componentPresentationCoverMuted : t.colorTextMuted,
  ),
);
Widget _strong(String text, KDesignTokens t, {TextAlign? align}) => KText(
  text,
  align: align,
  style: TextStyle(fontWeight: t.fontHeadingWeight),
);
Widget _value(String text, KDesignTokens t) => KText(
  text,
  align: TextAlign.center,
  variant: KTextVariant.heading1,
  style: TextStyle(
    height: t.componentPresentationTitleLineHeight,
    fontWeight: FontWeight.bold,
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
);
Widget _image(String src, {String? alt, BoxFit fit = BoxFit.cover}) =>
    KPresentationNetworkImage(src: src, alt: alt, fit: fit);
