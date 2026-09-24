import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KGlassQuality { auto, liquid, frosted, solid }

enum KMobileAppBarVisibility { portraitMobile, always }

enum KMobileAppBarVariant {
  floatingGlass,
  fixed,
  action,
  floatingDock,
  labeled,
  collapsible,
  contextual,
}

enum KMobileAppBarLabelVisibility { never, selected, always }

typedef KGlassQualityResolver = KGlassQuality Function(BuildContext context);

@immutable
class KMobileAppBarItemState {
  const KMobileAppBarItemState({required this.selected});

  final bool selected;
}

typedef KMobileAppBarItemBuilder =
    Widget Function(
      BuildContext context,
      KMobileAppBarItem item,
      KMobileAppBarItemState state,
    );

/// Builds the optional native liquid-glass surface around [child].
///
/// Keep the renderer outside the core UI package so Web consumers and
/// Widgetbook can use the same component with the frosted fallback.
typedef KGlassSurfaceBuilder =
    Widget Function(
      BuildContext context,
      Widget child,
      BorderRadius borderRadius,
    );

@immutable
class KMobileAppBarItem {
  const KMobileAppBarItem({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
    this.enabled = true,
  });

  final String id;
  final String label;
  final Widget icon;
  final Widget? selectedIcon;
  final Widget? badge;
  final bool enabled;
}

class KMobileAppBar extends StatefulWidget {
  const KMobileAppBar({
    required this.items,
    required this.selectedId,
    required this.onSelectionChanged,
    this.primaryAction,
    this.variant = KMobileAppBarVariant.floatingGlass,
    this.labelVisibility,
    this.collapsed = false,
    this.contextualContent,
    this.itemBuilder,
    this.quality = KGlassQuality.auto,
    this.visibility = KMobileAppBarVisibility.portraitMobile,
    this.qualityResolver,
    this.liquidSurfaceBuilder,
    this.onResolvedQualityChanged,
    this.semanticLabel = 'Primary navigation',
    this.maxWidth = 430,
    super.key,
  });

  final List<KMobileAppBarItem> items;
  final String selectedId;
  final ValueChanged<String> onSelectionChanged;
  final Widget? primaryAction;
  final KMobileAppBarVariant variant;
  final KMobileAppBarLabelVisibility? labelVisibility;
  final bool collapsed;
  final Widget? contextualContent;
  final KMobileAppBarItemBuilder? itemBuilder;
  final KGlassQuality quality;
  final KMobileAppBarVisibility visibility;
  final KGlassQualityResolver? qualityResolver;
  final KGlassSurfaceBuilder? liquidSurfaceBuilder;
  final ValueChanged<KGlassQuality>? onResolvedQualityChanged;
  final String semanticLabel;
  final double maxWidth;

  @override
  State<KMobileAppBar> createState() => _KMobileAppBarState();
}

class _KMobileAppBarState extends State<KMobileAppBar> {
  KGlassQuality? _lastResolvedQuality;

  KGlassQuality _resolveQuality(BuildContext context) {
    final requested = widget.qualityResolver?.call(context) ?? widget.quality;
    if (requested == KGlassQuality.solid) return requested;
    if (MediaQuery.highContrastOf(context)) return KGlassQuality.solid;
    if (requested == KGlassQuality.frosted) return requested;
    if (widget.liquidSurfaceBuilder != null &&
        ImageFilter.isShaderFilterSupported) {
      return KGlassQuality.liquid;
    }
    return KGlassQuality.frosted;
  }

  void _reportResolvedQuality(KGlassQuality quality) {
    if (_lastResolvedQuality == quality) return;
    _lastResolvedQuality = quality;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onResolvedQualityChanged?.call(quality);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (widget.visibility == KMobileAppBarVisibility.portraitMobile &&
        media.orientation != Orientation.portrait) {
      return const SizedBox.shrink();
    }

    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final quality = _resolveQuality(context);
    _reportResolvedQuality(quality);
    final isFixed = switch (widget.variant) {
      KMobileAppBarVariant.fixed ||
      KMobileAppBarVariant.action ||
      KMobileAppBarVariant.labeled ||
      KMobileAppBarVariant.contextual => true,
      _ => false,
    };
    final radius = isFixed
        ? const BorderRadius.vertical(top: Radius.circular(24))
        : BorderRadius.circular(999);
    final splitIndex = (widget.items.length / 2).ceil();
    final before = widget.primaryAction == null
        ? widget.items
        : widget.items.take(splitIndex).toList(growable: false);
    final after = widget.primaryAction == null
        ? const <KMobileAppBarItem>[]
        : widget.items.skip(splitIndex).toList(growable: false);

    final content = Container(
      constraints: BoxConstraints(
        minHeight: widget.variant == KMobileAppBarVariant.labeled ? 78 : 72,
      ),
      padding: EdgeInsets.fromLTRB(
        10,
        7,
        10,
        7 + (isFixed ? media.padding.bottom : 0),
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Color.alphaBlend(
            Colors.white.withValues(alpha: .08),
            tokens.colorBorderStrong.withValues(alpha: .62),
          ),
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .32),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: widget.variant == KMobileAppBarVariant.contextual
          ? SizedBox(width: double.infinity, child: widget.contextualContent)
          : Row(
              children: [
                Expanded(
                  child: _DestinationGroup(items: before, parent: widget),
                ),
                if (widget.primaryAction != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 56,
                        minHeight: 56,
                      ),
                      child: widget.primaryAction,
                    ),
                  ),
                if (after.isNotEmpty)
                  Expanded(
                    child: _DestinationGroup(items: after, parent: widget),
                  ),
              ],
            ),
    );

    final surface = AnimatedSlide(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      offset: widget.collapsed ? const Offset(0, 1.25) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: widget.collapsed ? 0 : 1,
        child: IgnorePointer(
          ignoring: widget.collapsed,
          child: _GlassSurface(
            quality: quality,
            tokens: tokens,
            borderRadius: radius,
            liquidSurfaceBuilder: widget.liquidSurfaceBuilder,
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: SafeArea(
        bottom: !isFixed,
        minimum: isFixed
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isFixed
                  ? double.infinity
                  : widget.variant == KMobileAppBarVariant.floatingDock
                  ? 320
                  : widget.maxWidth,
            ),
            child: surface,
          ),
        ),
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.quality,
    required this.tokens,
    required this.borderRadius,
    required this.liquidSurfaceBuilder,
    required this.child,
  });

  final KGlassQuality quality;
  final KDesignTokens tokens;
  final BorderRadius borderRadius;
  final KGlassSurfaceBuilder? liquidSurfaceBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return switch (quality) {
      KGlassQuality.liquid => liquidSurfaceBuilder!(
        context,
        child,
        borderRadius,
      ),
      KGlassQuality.frosted || KGlassQuality.auto => ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: ColoredBox(
            color: tokens.colorSurfaceRaised.withValues(alpha: .72),
            child: child,
          ),
        ),
      ),
      KGlassQuality.solid => DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.colorSurfaceRaised,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    };
  }
}

class _DestinationGroup extends StatelessWidget {
  const _DestinationGroup({required this.items, required this.parent});

  final List<KMobileAppBarItem> items;
  final KMobileAppBar parent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final item in items)
        Expanded(
          child: _Destination(
            item: item,
            selected: item.id == parent.selectedId,
            showLabel:
                (parent.labelVisibility ??
                        (parent.variant == KMobileAppBarVariant.labeled
                            ? KMobileAppBarLabelVisibility.always
                            : KMobileAppBarLabelVisibility.never)) ==
                    KMobileAppBarLabelVisibility.always ||
                ((parent.labelVisibility ==
                        KMobileAppBarLabelVisibility.selected) &&
                    item.id == parent.selectedId),
            itemBuilder: parent.itemBuilder,
            onTap: () => parent.onSelectionChanged(item.id),
          ),
        ),
    ],
  );
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.itemBuilder,
    required this.onTap,
  });

  final KMobileAppBarItem item;
  final bool selected;
  final bool showLabel;
  final KMobileAppBarItemBuilder? itemBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Opacity(
          opacity: item.enabled ? 1 : .45,
          child: Material(
            color: selected
                ? tokens.colorSurfaceSubtle.withValues(alpha: .82)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: item.enabled ? onTap : null,
              customBorder: const StadiumBorder(),
              overlayColor: WidgetStatePropertyAll(
                tokens.colorSurfaceSubtle.withValues(alpha: .5),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 48,
                  minHeight: showLabel ? 64 : 56,
                ),
                child: itemBuilder != null
                    ? itemBuilder!(
                        context,
                        item,
                        KMobileAppBarItemState(selected: selected),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) => Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconTheme(
                                  data: IconThemeData(
                                    size: 24,
                                    color: selected
                                        ? tokens.colorTextPrimary
                                        : tokens.colorTextMuted,
                                  ),
                                  child: selected
                                      ? (item.selectedIcon ?? item.icon)
                                      : item.icon,
                                ),
                                if (showLabel) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selected
                                          ? tokens.colorTextPrimary
                                          : tokens.colorTextMuted,
                                      fontFamily: tokens.fontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (item.badge != null)
                              Positioned(
                                top: 3,
                                left: constraints.maxWidth / 2 + 6,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  height: 18,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: tokens.colorStatusErrorAccent,
                                    border: Border.all(
                                      color: tokens.colorSurfaceRaised,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: DefaultTextStyle(
                                    style: TextStyle(
                                      color: tokens.colorStatusErrorForeground,
                                      fontFamily: tokens.fontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                                    child: item.badge!,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
