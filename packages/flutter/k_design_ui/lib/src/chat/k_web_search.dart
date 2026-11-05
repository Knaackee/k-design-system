import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_display.dart';
import '../primitives/k_animated_icon.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';

enum KWebSearchState { running, succeeded, failed }

enum KWebSearchLoadingIndicator { shimmer, animatedIcon }

class KWebSearchResult {
  const KWebSearchResult({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.faviconUrl,
  });
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? faviconUrl;

  String get domain {
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isEmpty ? url : host.replaceFirst(RegExp(r'^www\.'), '');
  }
}

/// All user-facing copy belongs to the consumer, including pluralization.
class KWebSearchLabels {
  const KWebSearchLabels({
    required this.title,
    required this.running,
    required this.empty,
    required this.failed,
    required this.sourceCount,
  });
  final String title;
  final String running;
  final String empty;
  final String failed;
  final String Function(int count) sourceCount;
}

typedef KWebSearchFaviconBuilder =
    Widget Function(BuildContext context, KWebSearchResult result, double size);

/// Presentation only: consumers supply search state and own source navigation.
class KWebSearch extends StatefulWidget {
  const KWebSearch({
    required this.id,
    required this.state,
    required this.labels,
    this.query,
    this.results = const [],
    this.error,
    this.expanded,
    this.defaultExpanded = false,
    this.loadingIndicator = KWebSearchLoadingIndicator.shimmer,
    this.onExpandedChanged,
    this.onSourceActivate,
    this.faviconBuilder,
    super.key,
  });
  final String id;
  final String? query;
  final KWebSearchState state;
  final List<KWebSearchResult> results;
  final String? error;
  final KWebSearchLabels labels;
  final bool? expanded;
  final bool defaultExpanded;
  final KWebSearchLoadingIndicator loadingIndicator;
  final ValueChanged<bool>? onExpandedChanged;
  final ValueChanged<KWebSearchResult>? onSourceActivate;
  final KWebSearchFaviconBuilder? faviconBuilder;

  @override
  State<KWebSearch> createState() => _KWebSearchState();
}

class _KWebSearchState extends State<KWebSearch>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.defaultExpanded;
  late final AnimationController _loading = AnimationController(vsync: this);

  void configureLoading() {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final duration = t.motionSkeleton * 2;
    if (_loading.duration != duration) _loading.duration = duration;
    if (widget.state == KWebSearchState.running &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!_loading.isAnimating) _loading.repeat();
    } else {
      _loading.stop();
      _loading.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    configureLoading();
  }

  @override
  void dispose() {
    _loading.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KWebSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _expanded = widget.defaultExpanded;
    configureLoading();
  }

  Widget favicon(KWebSearchResult result, double size) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child:
          widget.faviconBuilder?.call(context, result, size) ??
          FittedBox(
            child: KAvatar(
              alt: result.domain,
              size: KAvatarSize.small,
              image: widgetSafeImage(result.faviconUrl),
              fallback: const KIcon(KIconName.globe),
            ),
          ),
    ),
  );

  ImageProvider<Object>? widgetSafeImage(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    return uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty
        ? NetworkImage(url!)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final expanded = widget.expanded ?? _expanded;
    final muted = TextStyle(color: t.colorTextMuted);
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    final status = switch (widget.state) {
      KWebSearchState.running =>
        widget.results.isEmpty
            ? widget.labels.running
            : widget.labels.sourceCount(widget.results.length),
      KWebSearchState.failed => widget.labels.failed,
      KWebSearchState.succeeded => widget.labels.sourceCount(
        widget.results.length,
      ),
    };
    Widget title = KText(
      widget.labels.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontWeight: t.fontLabelWeight),
    );
    if (widget.state == KWebSearchState.running &&
        widget.loadingIndicator == KWebSearchLoadingIndicator.shimmer &&
        !MediaQuery.disableAnimationsOf(context)) {
      title = AnimatedBuilder(
        animation: _loading,
        child: title,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-3 + (_loading.value * 2 % 1) * 6, -.3),
            end: Alignment(-1 + (_loading.value * 2 % 1) * 6, .3),
            colors: [t.colorTextMuted, t.colorTextPrimary, t.colorTextMuted],
            stops: const [.35, .5, .65],
          ).createShader(bounds),
          child: child,
        ),
      );
    }
    final icons = widget.results.take(3).toList();
    final iconSize = t.sizeIconDefault * 2 / 3;
    final stackSize = t.sizeIconDefault * .75;
    final stackStep = t.sizeIconDefault * .5;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : t.motionStandard;
    void toggle() {
      if (widget.expanded == null) setState(() => _expanded = !expanded);
      widget.onExpandedChanged?.call(!expanded);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: t.sizeHitTarget),
            child: InkWell(
              onTap: toggle,
              borderRadius: BorderRadius.circular(t.radiusControl),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: t.spaceControlGap),
                child: Row(
                  children: [
                    widget.state == KWebSearchState.running &&
                            widget.loadingIndicator ==
                                KWebSearchLoadingIndicator.animatedIcon
                        ? AnimatedBuilder(
                            animation: _loading,
                            builder: (context, _) => KAnimatedIcon(
                              _loading.value < .5
                                  ? KIconName.search
                                  : KIconName.loaderCircle,
                              size: iconSize,
                              color: t.colorTextMuted,
                            ),
                          )
                        : KIcon(
                            KIconName.search,
                            size: iconSize,
                            color: t.colorTextMuted,
                          ),
                    SizedBox(width: t.spaceControlGap),
                    Expanded(
                      // From 1.3x the status moves under the title so the
                      // title keeps the row (Decision 0010).
                      child: largeText
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) => Row(
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: constraints.maxWidth,
                                        ),
                                        child: title,
                                      ),
                                      if (widget.query?.isNotEmpty == true &&
                                          constraints.maxWidth >
                                              MediaQuery.textScalerOf(
                                                    context,
                                                  ).scale(t.fontBodySize) *
                                                  9) ...[
                                        SizedBox(width: t.spaceControlGap),
                                        Expanded(
                                          child: KText(
                                            widget.query!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: muted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                KText(
                                  status,
                                  variant: KTextVariant.caption,
                                  style: muted,
                                ),
                              ],
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) => Row(
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth,
                                    ),
                                    child: title,
                                  ),
                                  if (widget.query?.isNotEmpty == true &&
                                      constraints.maxWidth >
                                          MediaQuery.textScalerOf(
                                                context,
                                              ).scale(t.fontBodySize) *
                                              9) ...[
                                    SizedBox(width: t.spaceControlGap),
                                    Expanded(
                                      child: KText(
                                        widget.query!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: muted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                    SizedBox(width: t.spaceControlGap),
                    if (icons.isNotEmpty) ...[
                      SizedBox(
                        width: stackSize + (icons.length - 1) * stackStep,
                        height: stackSize,
                        child: Stack(
                          children: [
                            for (var i = 0; i < icons.length; i++)
                              PositionedDirectional(
                                start: i * stackStep,
                                child: favicon(icons[i], stackSize),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: t.spaceControlGap),
                    ],
                    if (!largeText) ...[
                      KText(
                        status,
                        variant: KTextVariant.caption,
                        style: muted,
                      ),
                      SizedBox(width: t.spaceControlGap),
                    ],
                    AnimatedRotation(
                      turns: expanded ? .25 : 0,
                      duration: duration,
                      child: KIcon(
                        KIconName.chevronRight,
                        size: iconSize,
                        color: t.colorTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: iconSize + t.spaceControlGap,
              top: t.spaceControlGap / 2,
              bottom: t.spaceControlGap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < widget.results.length; i++) ...[
                  if (i > 0) SizedBox(height: t.spaceLayoutGutter),
                  source(widget.results[i], t),
                ],
                if (widget.state == KWebSearchState.failed ||
                    widget.results.isEmpty) ...[
                  if (widget.results.isNotEmpty)
                    SizedBox(height: t.spaceLayoutGutter),
                  Semantics(
                    liveRegion: true,
                    child: KText(switch (widget.state) {
                      KWebSearchState.running =>
                        widget.results.isEmpty
                            ? widget.labels.running
                            : widget.labels.sourceCount(widget.results.length),
                      KWebSearchState.failed =>
                        widget.error ?? widget.labels.failed,
                      KWebSearchState.succeeded => widget.labels.empty,
                    }, style: muted),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget source(KWebSearchResult result, KDesignTokens t) => Semantics(
    link: widget.onSourceActivate != null,
    child: InkWell(
      onTap: widget.onSourceActivate == null
          ? null
          : () => widget.onSourceActivate!(result),
      borderRadius: BorderRadius.circular(t.radiusControl),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: t.sizeHitTarget),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            favicon(result, t.sizeIconDefault),
            SizedBox(width: t.spaceControlInsetInline),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KText(
                    result.title,
                    style: TextStyle(fontWeight: t.fontLabelWeight),
                  ),
                  KText(
                    result.domain,
                    variant: KTextVariant.caption,
                    style: TextStyle(color: t.colorTextMuted),
                  ),
                  if (result.description?.isNotEmpty == true) ...[
                    SizedBox(height: t.spaceControlGap / 2),
                    KText(
                      result.description!,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
