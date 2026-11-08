import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

export 'feedback/k_notifications.dart';
export 'overlays/k_popover.dart';

import 'actions/k_icon_button.dart';
import 'feedback/k_haptics.dart';
import 'overlays/k_overlays.dart';
import 'overlays/k_popover.dart';
import 'primitives/k_button.dart';
import 'primitives/k_icon.dart';
import 'primitives/k_text.dart';

class KKbd extends StatelessWidget {
  const KKbd({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      constraints: BoxConstraints(
        minWidth: t.componentKbdMinSize,
        minHeight: t.componentKbdMinSize,
      ),
      padding: EdgeInsets.symmetric(horizontal: t.componentKbdPaddingInline),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.colorSurfaceSubtle,
        border: Border.all(color: t.colorBorderDefault),
        borderRadius: BorderRadius.circular(t.radiusControl),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: t.fontFamily,
          fontSize: t.fontBodySmallSize,
          fontWeight: FontWeight.w600,
          color: t.colorTextMuted,
        ),
        child: child,
      ),
    );
  }
}

class KKbdGroup extends StatelessWidget {
  const KKbdGroup({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Wrap(
      spacing: t.componentKbdGroupGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class KProgress extends StatelessWidget {
  const KProgress({
    this.value,
    this.max = 100,
    this.label,
    this.valueLabel,
    super.key,
  });
  final double? value;
  final double max;
  final Widget? label;
  final Widget? valueLabel;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final normalized = value == null ? null : (value! / max).clamp(0.0, 1.0);
    return Semantics(
      label: label is Text ? (label as Text).data : null,
      value: normalized == null ? null : '${(normalized * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null || valueLabel != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Long labels wrap instead of pushing the value off-screen.
                Expanded(child: label ?? const SizedBox.shrink()),
                SizedBox(width: t.spaceControlGap),
                valueLabel ??
                    Text(
                      normalized == null
                          ? ''
                          : '${(normalized * 100).round()}%',
                    ),
              ],
            ),
            SizedBox(height: t.componentProgressMetaGap),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(t.radiusFull),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: t.componentProgressTrackSize,
              color: t.colorActionPrimaryBackground,
              backgroundColor: t.colorSurfaceSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class KSkeleton extends StatefulWidget {
  const KSkeleton({
    this.width = double.infinity,
    this.height,
    this.circle = false,
    super.key,
  });
  final double width;
  final double? height;
  final bool circle;
  @override
  State<KSkeleton> createState() => _KSkeletonState();
}

class _KSkeletonState extends State<KSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = Theme.of(context).extension<KDesignTokens>()!;
    if (_controller.duration != t.componentSkeletonAnimationDuration) {
      _controller.duration = t.componentSkeletonAnimationDuration;
    }
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height ?? t.componentSkeletonDefaultSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              widget.circle ? t.radiusFull : t.radiusControl,
            ),
            gradient: MediaQuery.disableAnimationsOf(context)
                ? LinearGradient(
                    colors: [t.colorSurfaceSubtle, t.colorSurfaceSubtle],
                  )
                : LinearGradient(
                    begin: Alignment(-3 + _controller.value * 6, 0),
                    end: Alignment(-1 + _controller.value * 6, 0),
                    colors: [
                      t.colorSurfaceSubtle,
                      t.colorSurfaceRaised,
                      t.colorSurfaceSubtle,
                    ],
                    stops: const [0, .5, 1],
                  ),
          ),
        ),
      ),
    );
  }
}

class KSpinner extends StatelessWidget {
  const KSpinner({this.label = 'Loading', this.size, super.key});
  final String label;
  final double? size;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: label,
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox.square(
          dimension: size ?? t.componentSpinnerDefaultSize,
          child: CircularProgressIndicator(
            strokeWidth: t.componentSpinnerStrokeWidth,
            color: t.colorActionPrimaryBackground,
            backgroundColor: t.colorBorderDefault,
          ),
        ),
      ),
    );
  }
}

class KSwitch extends StatelessWidget {
  const KSwitch({
    required this.value,
    required this.onChanged,
    required this.label,
    this.showLabel = true,
    super.key,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  /// Shows [label] beside the track. Defaults to true for Flutter/Web API parity.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: label,
      toggled: value,
      child: MouseRegion(
        cursor: onChanged == null
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null
              ? null
              : () {
                  kHaptic(context, KHapticCue.light);
                  onChanged!(!value);
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: t.componentSwitchTrackWidth,
                height: t.sizeHitTarget.clamp(
                  t.componentSwitchTrackHeight,
                  double.infinity,
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: t.motion(KMotionRole.control).settle,
                    curve: t.motion(KMotionRole.control).curve,
                    width: t.componentSwitchTrackWidth,
                    height: t.componentSwitchTrackHeight,
                    padding: EdgeInsets.all(t.componentSwitchTrackInset),
                    decoration: BoxDecoration(
                      color: value
                          ? t.componentSwitchActiveTrack
                          : t.componentSwitchInactiveTrack,
                      border: Border.all(
                        color: value
                            ? t.componentSwitchActiveTrack
                            : t.componentSwitchInactiveBorder,
                      ),
                      borderRadius: BorderRadius.circular(t.radiusFull),
                    ),
                    child: AnimatedAlign(
                      duration: t.motion(KMotionRole.control).settle,
                      curve: t.motion(KMotionRole.control).curve,
                      alignment: value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: t.componentSwitchThumbSize,
                        height: t.componentSwitchThumbSize,
                        decoration: BoxDecoration(
                          color: value
                              ? t.componentSwitchActiveThumb
                              : t.componentSwitchInactiveThumb,
                          shape: BoxShape.circle,
                          boxShadow: t.componentSwitchNativeThumbElevation,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showLabel) ...[
                SizedBox(width: t.spaceControlGap),
                Flexible(
                  child: ExcludeSemantics(
                    child: KText(
                      label,
                      variant: KTextVariant.label,
                      style: TextStyle(
                        color: onChanged == null
                            ? t.colorTextMuted
                            : t.colorTextPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class KSlider extends StatelessWidget {
  const KSlider({
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.valueLabel,
    super.key,
  });
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final String Function(double value)? valueLabel;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: t.colorActionPrimaryBackground,
        inactiveTrackColor: t.colorSurfaceSubtle,
        thumbColor: t.colorSurfaceRaised,
        thumbShape: _KSliderThumbShape(
          fill: t.colorSurfaceRaised,
          border: t.colorActionPrimaryBackground,
          size: t.componentSliderThumbSize,
          strokeWidth: t.componentSliderThumbStrokeWidth,
        ),
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: t.componentSliderOverlaySize / 2,
        ),
        overlayColor: t.colorActionPrimaryBackground.withValues(
          alpha: t.componentSliderOverlayOpacity,
        ),
        trackHeight: t.componentSliderTrackSize,
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        semanticFormatterCallback: valueLabel,
        label: valueLabel?.call(value),
        onChanged: onChanged,
      ),
    );
  }
}

class _KSliderThumbShape extends SliderComponentShape {
  const _KSliderThumbShape({
    required this.fill,
    required this.border,
    required this.size,
    required this.strokeWidth,
  });
  final Color fill;
  final Color border;
  final double size;
  final double strokeWidth;
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.square(size);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas
      ..drawCircle(center, size / 2, Paint()..color = fill)
      ..drawCircle(
        center,
        (size - strokeWidth) / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = border,
      );
  }
}

class KInputOtp extends StatefulWidget {
  const KInputOtp({
    required this.value,
    required this.onChanged,
    required this.label,
    this.length = 6,
    this.separatorAfter = const [3],
    this.numeric = true,
    this.enabled = true,
    this.invalid = false,
    super.key,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final int length;
  final List<int> separatorAfter;
  final bool numeric;
  final bool enabled;
  final bool invalid;
  @override
  State<KInputOtp> createState() => _KInputOtpState();
}

class _KInputOtpState extends State<KInputOtp> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_handleFocusChange);
  }

  void _handleFocusChange() => setState(() {});

  @override
  void didUpdateWidget(KInputOtp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_handleFocusChange);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: widget.label,
      textField: true,
      child: GestureDetector(
        onTap: widget.enabled ? _focus.requestFocus : null,
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.length,
                (index) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: t.componentOtpSlotWidth,
                      height: t.componentOtpSlotHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.colorSurfaceRaised,
                        border: Border.all(
                          color: widget.invalid
                              ? t.colorStatusErrorBorder
                              : _focus.hasFocus && index == widget.value.length
                              ? t.colorBorderFocus
                              : t.colorBorderDefault,
                        ),
                        borderRadius: BorderRadius.circular(t.radiusControl),
                      ),
                      child: Text(
                        index < widget.value.length ? widget.value[index] : '',
                        style: TextStyle(
                          fontFamily: t.fontFamily,
                          fontWeight: FontWeight.w600,
                          color: t.colorTextPrimary,
                        ),
                      ),
                    ),
                    if (widget.separatorAfter.contains(index + 1) &&
                        index + 1 < widget.length)
                      SizedBox(
                        width: t.componentOtpSeparatorWidth,
                        child: Center(
                          child: Text(
                            '−',
                            style: TextStyle(color: t.colorTextMuted),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: .001,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  maxLength: widget.length,
                  keyboardType: widget.numeric
                      ? TextInputType.number
                      : TextInputType.text,
                  inputFormatters: [
                    if (widget.numeric) FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: widget.onChanged,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KPagination extends StatelessWidget {
  const KPagination({
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    this.label = 'Pagination',
    this.previousLabel = 'Previous page',
    this.nextLabel = 'Next page',
    this.siblingCount = 1,
    super.key,
  });
  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final String label;
  final String previousLabel;
  final String nextLabel;
  final int siblingCount;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Decision 0010: on narrow windows drop sibling pages, then fall back
      // to "page / count" between the arrows instead of overflowing.
      final t = Theme.of(context).extension<KDesignTokens>()!;
      final slot = t.sizeHitTarget;
      for (final siblings in {siblingCount, 0}) {
        final count = _visible(siblings).length;
        final width =
            (count + 2) * slot + 2 * t.componentPaginationEllipsisWidth;
        if (!constraints.hasBoundedWidth || width <= constraints.maxWidth) {
          return _pages(context, t, _visible(siblings));
        }
      }
      return _summary(context, t);
    },
  );

  List<int> _visible(int siblings) =>
      (pageCount <= 7 && siblings == siblingCount
            ? List.generate(pageCount, (i) => i + 1)
            : <int>{
                1,
                for (var i = page - siblings; i <= page + siblings; i++)
                  if (i > 1 && i < pageCount) i,
                pageCount,
              }.toList())
        ..sort();

  Widget _summary(BuildContext context, KDesignTokens t) => Semantics(
    label: label,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KIconButton(
          icon: KIconName.chevronLeft,
          label: previousLabel,
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: t.spaceControlGap),
          child: Text(
            '$page / $pageCount',
            style: TextStyle(
              fontFamily: t.fontFamily,
              fontSize: t.fontControlSize,
              fontWeight: t.fontControlWeight,
              color: t.colorTextPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        KIconButton(
          icon: KIconName.chevronRight,
          label: nextLabel,
          onPressed: page < pageCount ? () => onPageChanged(page + 1) : null,
        ),
      ],
    ),
  );

  Widget _pages(BuildContext context, KDesignTokens t, List<int> visible) {
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KIconButton(
            icon: KIconName.chevronLeft,
            label: previousLabel,
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          ),
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0 && visible[i] - visible[i - 1] > 1)
              SizedBox(
                width: t.componentPaginationEllipsisWidth,
                child: Center(
                  child: Text('…', style: TextStyle(color: t.colorTextMuted)),
                ),
              ),
            Semantics(
              selected: visible[i] == page,
              button: true,
              label: '${visible[i]}',
              child: SizedBox.square(
                dimension: t.sizeHitTarget,
                child: Material(
                  color: visible[i] == page
                      ? t.colorActionPrimaryBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(t.radiusControl),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onPageChanged(visible[i]),
                    child: Center(
                      child: Text(
                        '${visible[i]}',
                        style: TextStyle(
                          fontFamily: t.fontFamily,
                          fontSize: t.fontControlSize,
                          height: t.fontTightHeight,
                          fontWeight: t.fontControlWeight,
                          color: visible[i] == page
                              ? t.colorActionPrimaryForeground
                              : t.colorTextMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          KIconButton(
            icon: KIconName.chevronRight,
            label: nextLabel,
            onPressed: page < pageCount ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class KTabItem {
  const KTabItem({
    required this.id,
    required this.label,
    required this.content,
    this.icon,
    this.enabled = true,
  });
  final String id;
  final Widget label;
  final Widget content;
  final KIconName? icon;
  final bool enabled;
}

class KTabs extends StatelessWidget {
  const KTabs({
    required this.items,
    required this.value,
    required this.onChanged,
    this.label = 'Tabs',
    this.expanded = false,
    super.key,
  });
  final List<KTabItem> items;
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  /// Equal-width tabs that fill available space, scrolling for long labels.
  final bool expanded;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final current =
        items.where((item) => item.id == value).firstOrNull ?? items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: label,
          child: Container(
            padding: EdgeInsets.all(t.componentTabsListPadding),
            decoration: BoxDecoration(
              color: t.colorSurfaceSubtle,
              borderRadius: BorderRadius.circular(t.radiusControl),
            ),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: const {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final row = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in items)
                        if (expanded)
                          Expanded(child: _tab(context, item, t))
                        else
                          _tab(context, item, t),
                    ],
                  );
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: expanded
                        ? ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: IntrinsicWidth(child: row),
                          )
                        : row,
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: t.spaceControlGap),
        current.content,
      ],
    );
  }

  Widget _tab(BuildContext context, KTabItem item, KDesignTokens t) => Padding(
    padding: EdgeInsets.only(right: t.spaceTight),
    child: TextButton.icon(
      icon: item.icon == null
          ? const SizedBox.shrink()
          : KIcon(item.icon!, size: 16),
      label: item.label,
      style: TextButton.styleFrom(
        minimumSize: Size(
          0,
          expanded && t.sizeHitTarget < 40 ? 40 : t.sizeHitTarget,
        ),
        backgroundColor: item.id == value
            ? t.colorSurfaceRaised
            : Colors.transparent,
        foregroundColor: item.id == value
            ? t.colorTextPrimary
            : t.colorTextMuted,
      ),
      onPressed: item.enabled ? () => onChanged(item.id) : null,
    ),
  );
}

class KNavigationMenuItem {
  const KNavigationMenuItem({
    required this.id,
    required this.label,
    this.content,
    this.onPressed,
    this.enabled = true,
  });
  final String id;
  final Widget label;
  final Widget? content;
  final VoidCallback? onPressed;
  final bool enabled;
}

class KNavigationMenu extends StatelessWidget {
  const KNavigationMenu({
    required this.items,
    this.label = 'Main navigation',
    super.key,
  });
  final List<KNavigationMenuItem> items;
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: label,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(t.spaceTight),
        decoration: BoxDecoration(
          color: t.colorSurfaceRaised,
          border: Border.all(color: t.colorBorderDefault),
          borderRadius: BorderRadius.circular(t.radiusCard),
        ),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: [
                for (final item in items)
                  item.content == null
                      ? TextButton(
                          onPressed: item.enabled ? item.onPressed : null,
                          child: item.label,
                        )
                      : KPopover(
                          label: item.id,
                          trigger: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: t.spaceControlInsetInline,
                            ),
                            child: Row(
                              children: [
                                item.label,
                                SizedBox(width: t.spaceSmallInset),
                                const KIcon(KIconName.chevronDown, size: 16),
                              ],
                            ),
                          ),
                          content: item.content!,
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KResponsiveDrawer {
  const KResponsiveDrawer._();
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required Widget child,
    Widget? description,
    Widget? actions,
    String? closeLabel,
    bool dismissible = true,
    double breakpoint = 600,
    bool left = false,

    /// Side-drawer composition; bottom sheets keep their existing layout.
    double? sideWidth,
    bool sideContentInset = true,
    bool sideScrollable = true,
    bool sheetExpandBody = false,
    bool sideShowCloseButton = true,
    // Null preserves platform defaults: root for side drawer, nearest for sheet.
    bool? useRootNavigator,
  }) {
    if (MediaQuery.sizeOf(context).width < breakpoint) {
      return KBottomSheet.show<T>(
        context: context,
        title: title,
        description: description,
        actions: actions,
        closeLabel: closeLabel,
        dismissible: dismissible,
        useRootNavigator: useRootNavigator ?? false,
        expandBody: sheetExpandBody,
        child: child,
      );
    }
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator ?? true,
      barrierDismissible: dismissible,
      barrierLabel: closeLabel ?? 'Close',
      barrierColor: (Theme.of(
        context,
      ).extension<KDesignTokens>()!).componentDrawerScrimColor,
      transitionDuration: (Theme.of(
        context,
      ).extension<KDesignTokens>()!).componentDrawerTransitionDuration,
      pageBuilder: (routeContext, _, _) => Align(
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        child: _KResponsiveSideSheet(
          width: sideWidth,
          contentInset: sideContentInset,
          scrollable: sideScrollable,
          title: title,
          description: description,
          actions: actions,
          closeLabel: closeLabel,
          onClose: dismissible && sideShowCloseButton
              ? () => Navigator.of(routeContext).pop()
              : null,
          child: child,
        ),
      ),
    );
  }
}

class _KResponsiveSideSheet extends StatelessWidget {
  const _KResponsiveSideSheet({
    required this.title,
    required this.child,
    this.description,
    this.actions,
    this.closeLabel,
    this.onClose,
    this.width,
    this.contentInset = true,
    this.scrollable = true,
  });
  final Widget title;
  final Widget child;
  final Widget? description;
  final Widget? actions;
  final String? closeLabel;
  final VoidCallback? onClose;
  final double? width;
  final bool contentInset;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      color: t.colorSurfaceRaised,
      elevation: 0,
      child: SafeArea(
        child: SizedBox(
          width: width ?? t.componentResponsiveDrawerWidth,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.spaceLayoutGutter,
                  t.spaceLayoutGutter,
                  contentInset ? t.spaceControlGap : t.spaceLayoutGutter,
                  contentInset ? t.spaceControlGap : t.spaceLayoutGutter,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle(
                            style: TextStyle(
                              fontFamily: t.fontFamily,
                              fontSize: t.fontHeading5Size,
                              height:
                                  t.fontHeading5LineHeight / t.fontHeading5Size,
                              fontWeight: t.fontHeadingWeight,
                              color: t.colorTextPrimary,
                            ),
                            child: title,
                          ),
                          if (description != null) ...[
                            SizedBox(height: t.spaceTight),
                            DefaultTextStyle(
                              style: TextStyle(
                                fontFamily: t.fontFamily,
                                fontSize: t.fontBodySmallSize,
                                color: t.colorTextMuted,
                              ),
                              child: description!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onClose != null)
                      KIconButton(
                        icon: KIconName.x,
                        label:
                            closeLabel ??
                            MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                        onPressed: onClose,
                      ),
                  ],
                ),
              ),
              if (contentInset)
                Divider(
                  height: t.borderWidthDefault,
                  color: t.colorBorderDefault,
                ),
              Expanded(
                child: scrollable
                    ? SingleChildScrollView(
                        padding: contentInset
                            ? EdgeInsets.all(t.spaceLayoutGutter)
                            : EdgeInsets.zero,
                        child: child,
                      )
                    : Padding(
                        padding: contentInset
                            ? EdgeInsets.all(t.spaceLayoutGutter)
                            : EdgeInsets.zero,
                        child: child,
                      ),
              ),
              if (actions != null) ...[
                Divider(
                  height: t.borderWidthDefault,
                  color: t.colorBorderDefault,
                ),
                Padding(
                  padding: EdgeInsets.all(t.spaceLayoutGutter),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: actions!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class KQuestionnaireStep {
  const KQuestionnaireStep({
    required this.id,
    required this.title,
    required this.content,
    this.description,
    this.optional = false,
  });
  final String id;
  final Widget title;
  final Widget? description;
  final Widget content;
  final bool optional;
}

class KQuestionnaire extends StatelessWidget {
  const KQuestionnaire({
    required this.steps,
    required this.step,
    required this.onStepChanged,
    required this.onComplete,
    this.canContinue,
    this.previousLabel = 'Previous',
    this.nextLabel = 'Next',
    this.skipLabel = 'Skip',
    this.completeLabel = 'Complete',
    this.progressLabel,
    super.key,
  });
  final List<KQuestionnaireStep> steps;
  final int step;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onComplete;
  final bool Function(int step)? canContinue;
  final String previousLabel, nextLabel, skipLabel, completeLabel;
  final String Function(int step, int count)? progressLabel;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final current = steps[step.clamp(0, steps.length - 1)];
    return Container(
      padding: EdgeInsets.all(t.spaceLayoutGutter),
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        border: Border.all(color: t.colorBorderDefault),
        borderRadius: BorderRadius.circular(t.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          KProgress(
            value: step + 1,
            max: steps.length.toDouble(),
            label: Text(
              progressLabel?.call(step + 1, steps.length) ??
                  'Question ${step + 1} of ${steps.length}',
            ),
          ),
          SizedBox(height: t.spaceLayoutGutter),
          DefaultTextStyle(
            style: TextStyle(
              fontFamily: t.fontFamily,
              fontSize: t.fontHeading5Size,
              fontWeight: t.fontHeadingWeight,
              color: t.colorTextPrimary,
            ),
            child: current.title,
          ),
          if (current.description != null) ...[
            SizedBox(height: t.spaceTight),
            DefaultTextStyle(
              style: TextStyle(color: t.colorTextMuted),
              child: current.description!,
            ),
          ],
          SizedBox(height: t.spaceLayoutGutter),
          current.content,
          SizedBox(height: t.spaceLayoutGutter),
          // Back on the start edge, forward actions on the end edge; at
          // large text or on narrow screens the forward group wraps below.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: t.spaceControlGap,
            runSpacing: t.spaceControlGap,
            children: [
              KButton(
                variant: KButtonVariant.secondary,
                label: previousLabel,
                onPressed: step > 0 ? () => onStepChanged(step - 1) : null,
              ),
              Wrap(
                spacing: t.spaceControlGap,
                runSpacing: t.spaceControlGap,
                children: [
                  if (current.optional && step < steps.length - 1)
                    KButton(
                      variant: KButtonVariant.secondary,
                      label: skipLabel,
                      onPressed: () => onStepChanged(step + 1),
                    ),
                  KButton(
                    label: step == steps.length - 1 ? completeLabel : nextLabel,
                    onPressed: (canContinue?.call(step) ?? true)
                        ? () => step == steps.length - 1
                              ? onComplete()
                              : onStepChanged(step + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
