import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_icon.dart';

enum KGlassQuality { auto, liquid, frosted, solid }

enum KMobileAppBarVisibility { portraitMobile, always }

enum KMobileAppBarVariant {
  floatingGlass,
  fixed,
  fixedLine,
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
    this.maxWidth,
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
  final double? maxWidth;

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

  // Tab bar symbols keep one size at every text size, as on iOS.
  @override
  Widget build(BuildContext context) =>
      KIconFixedScope(child: Builder(builder: _build));

  Widget _build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (widget.visibility == KMobileAppBarVisibility.portraitMobile &&
        media.orientation != Orientation.portrait) {
      return const SizedBox.shrink();
    }

    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    // Material style: the M3 navigation bar is an opaque tonal surface with a
    // pill indicator behind the icon (Decision 0014).
    final m3 =
        widget.variant == KMobileAppBarVariant.labeled &&
        KAdaptive.maybeOf(context)?.style == KStyle.material;
    final quality = m3 ? KGlassQuality.solid : _resolveQuality(context);
    _reportResolvedQuality(quality);
    final isFixed = switch (widget.variant) {
      KMobileAppBarVariant.fixed ||
      KMobileAppBarVariant.fixedLine ||
      KMobileAppBarVariant.action ||
      KMobileAppBarVariant.labeled ||
      KMobileAppBarVariant.contextual => true,
      _ => false,
    };
    final radius = isFixed
        ? BorderRadius.vertical(
            top: Radius.circular(
              tokens.componentMobileAppBarContainerRadiusFixed,
            ),
          )
        : BorderRadius.circular(
            tokens.componentMobileAppBarContainerRadiusFloating,
          );
    final splitIndex = (widget.items.length / 2).ceil();
    final isDock = widget.variant == KMobileAppBarVariant.floatingDock;
    final inlinePadding = isDock
        ? tokens.spaceControlGap
        : tokens.componentMobileAppBarContainerPaddingInline;
    final blockPadding = isDock
        ? tokens.spaceCompact
        : tokens.componentMobileAppBarContainerPaddingBlock;
    final before = widget.primaryAction == null
        ? widget.items
        : widget.items.take(splitIndex).toList(growable: false);
    final after = widget.primaryAction == null
        ? const <KMobileAppBarItem>[]
        : widget.items.skip(splitIndex).toList(growable: false);

    final borderSide = BorderSide(
      width: tokens.borderWidthDefault,
      color: Color.alphaBlend(
        tokens.colorGlassHighlight,
        tokens.colorBorderStrong.withValues(
          alpha: tokens.componentMobileAppBarOpacityBorder,
        ),
      ),
    );
    final content = Container(
      constraints: BoxConstraints(
        minHeight:
            widget.variant == KMobileAppBarVariant.labeled &&
                widget.labelVisibility != KMobileAppBarLabelVisibility.never
            ? tokens.componentMobileAppBarContainerLabeledMinHeight
            : isDock
            ? tokens.sizeAppBarFixed
            : tokens.componentMobileAppBarContainerMinHeight,
      ),
      padding: EdgeInsets.fromLTRB(
        inlinePadding,
        blockPadding,
        inlinePadding,
        blockPadding + (isFixed ? media.padding.bottom : 0),
      ),
      decoration: BoxDecoration(
        color: quality == KGlassQuality.solid
            ? tokens.colorSurfaceRaised
            : null,
        border: m3
            ? null
            : isFixed
            ? Border(top: borderSide)
            : Border.fromBorderSide(borderSide),
        borderRadius: m3 ? null : radius,
        boxShadow: m3
            ? null
            : isFixed
            ? tokens.componentMobileAppBarContainerElevation
            : tokens.elevationOverlay,
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
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          tokens.componentMobileAppBarContainerPaddingBlock,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth:
                            tokens.componentMobileAppBarDestinationMinHeight,
                        minHeight:
                            tokens.componentMobileAppBarDestinationMinHeight,
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
      duration: tokens.motion(KMotionRole.control).settle,
      curve: tokens.motion(KMotionRole.control).curve,
      offset: widget.collapsed ? const Offset(0, 1.25) : Offset.zero,
      child: AnimatedOpacity(
        duration: tokens.componentMobileAppBarMotionStandard,
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
        top: false,
        bottom: !isFixed,
        minimum: isFixed
            ? EdgeInsets.zero
            : EdgeInsets.fromLTRB(
                tokens.componentMobileAppBarContainerFloatingInset,
                0,
                tokens.componentMobileAppBarContainerFloatingInset,
                tokens.componentMobileAppBarContainerBottomInset,
              ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isFixed
                  ? double.infinity
                  : widget.variant == KMobileAppBarVariant.floatingDock
                  ? clampDouble(
                      widget.items.length *
                              tokens
                                  .componentMobileAppBarDestinationColumnWidth +
                          2 * inlinePadding +
                          2 * tokens.borderWidthDefault +
                          (widget.primaryAction == null
                              ? 0
                              : tokens.componentMobileAppBarDestinationMinHeight +
                                    2 *
                                        tokens
                                            .componentMobileAppBarContainerPaddingBlock),
                      0,
                      tokens.componentMobileAppBarContainerDockMaxWidth,
                    )
                  : widget.maxWidth ??
                        tokens.componentMobileAppBarContainerMaxWidth,
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
          filter: ImageFilter.blur(
            sigmaX: tokens.componentMobileAppBarGlassNativeBlur,
            sigmaY: tokens.componentMobileAppBarGlassNativeBlur,
          ),
          child: ColoredBox(
            color: tokens.colorSurfaceRaised.withValues(
              alpha: tokens.componentMobileAppBarOpacitySurface,
            ),
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
            lineIndicator: parent.variant == KMobileAppBarVariant.fixedLine,
            pillIndicator:
                parent.variant == KMobileAppBarVariant.labeled &&
                KAdaptive.maybeOf(context)?.style == KStyle.material,
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
    required this.lineIndicator,
    required this.pillIndicator,
    required this.onTap,
  });

  final KMobileAppBarItem item;
  final bool selected;
  final bool showLabel;
  final KMobileAppBarItemBuilder? itemBuilder;
  final bool lineIndicator;

  /// Material 3: the selection pill preserves padding around larger icons.
  final bool pillIndicator;
  final VoidCallback onTap;

  Widget _pill(KDesignTokens tokens, Widget icon) {
    if (!pillIndicator) return icon;
    final motion = tokens.motion(KMotionRole.control);
    return AnimatedContainer(
      duration: motion.settle,
      curve: motion.curve,
      width: tokens.componentMobileAppBarDestinationIndicatorWidth,
      constraints: BoxConstraints(
        minHeight: tokens.componentMobileAppBarDestinationIndicatorHeight,
      ),
      padding: EdgeInsets.symmetric(
        vertical:
            (tokens.componentMobileAppBarDestinationIndicatorHeight -
                tokens.componentMobileAppBarDestinationIconSize) /
            2,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? tokens.colorBrandPrimaryBackground
            : Colors.transparent,
        borderRadius: BorderRadius.circular(tokens.radiusFull),
      ),
      child: icon,
    );
  }

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
          opacity: item.enabled
              ? 1
              : tokens.componentMobileAppBarOpacityInactive,
          child: Material(
            color: selected && !lineIndicator && !pillIndicator
                ? tokens.colorSurfaceSubtle.withValues(
                    alpha: tokens.componentMobileAppBarOpacityRaised,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              tokens.componentMobileAppBarDestinationRadiusDefault,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: item.enabled ? onTap : null,
              customBorder: const StadiumBorder(),
              overlayColor: WidgetStatePropertyAll(
                tokens.colorSurfaceSubtle.withValues(
                  alpha: tokens.componentMobileAppBarOpacityMuted,
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: tokens.componentMobileAppBarDestinationMinWidth,
                  minHeight: showLabel
                      ? tokens.componentMobileAppBarDestinationLabeledMinHeight
                      : tokens.componentMobileAppBarDestinationMinHeight,
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
                            if (selected && lineIndicator)
                              Positioned(
                                top: 0,
                                child: Container(
                                  width: tokens
                                      .componentMobileAppBarDestinationIconSize,
                                  height: tokens.borderWidthStrong,
                                  decoration: BoxDecoration(
                                    color: tokens.colorTextPrimary,
                                    borderRadius: BorderRadius.circular(
                                      tokens.radiusFull,
                                    ),
                                  ),
                                ),
                              ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconTheme(
                                  data: IconThemeData(
                                    size: tokens
                                        .componentMobileAppBarDestinationIconSize,
                                    color: selected
                                        ? tokens.colorTextPrimary
                                        : tokens.colorTextMuted,
                                  ),
                                  child: _pill(
                                    tokens,
                                    selected
                                        ? (item.selectedIcon ?? item.icon)
                                        : item.icon,
                                  ),
                                ),
                                if (showLabel) ...[
                                  SizedBox(
                                    height: tokens
                                        .componentMobileAppBarDestinationLabelGap,
                                  ),
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    // Tab bar labels keep their size at
                                    // large text, like iOS and the Web bar;
                                    // the item's tooltip and semantics label
                                    // carry the full name.
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      color: selected
                                          ? tokens.colorTextPrimary
                                          : tokens.colorTextMuted,
                                      fontFamily: tokens.fontFamily,
                                      fontSize: tokens
                                          .componentMobileAppBarLabelFontSize,
                                      fontWeight: pillIndicator && !selected
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                      height: tokens.fontTightHeight,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (item.badge != null)
                              Positioned(
                                top: tokens
                                    .componentMobileAppBarBadgeOffsetBlock,
                                left:
                                    constraints.maxWidth / 2 +
                                    tokens
                                        .componentMobileAppBarBadgeOffsetInline,
                                child: Container(
                                  constraints: BoxConstraints(
                                    minWidth:
                                        tokens.componentMobileAppBarBadgeSize,
                                    minHeight:
                                        tokens.componentMobileAppBarBadgeSize,
                                  ),
                                  height: tokens.componentMobileAppBarBadgeSize,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: tokens
                                        .componentMobileAppBarBadgePaddingInline,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: tokens.colorStatusErrorAccent,
                                    border: Border.all(
                                      color: tokens.colorSurfaceRaised,
                                      width: tokens
                                          .componentMobileAppBarBadgeStrokeWidth,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      tokens.componentMobileAppBarBadgeRadius,
                                    ),
                                  ),
                                  child: DefaultTextStyle(
                                    style: TextStyle(
                                      color: tokens.colorStatusErrorForeground,
                                      fontFamily: tokens.fontFamily,
                                      fontSize: tokens
                                          .componentMobileAppBarLabelFontSize,
                                      fontWeight: FontWeight.w700,
                                      height: tokens.fontTightHeight,
                                    ),
                                    // Fixed like the label, so a count
                                    // never outgrows its badge.
                                    child: MediaQuery.withNoTextScaling(
                                      child: item.badge!,
                                    ),
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
