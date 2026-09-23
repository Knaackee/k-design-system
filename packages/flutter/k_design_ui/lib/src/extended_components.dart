import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'actions/k_icon_button.dart';
import 'overlays/k_overlays.dart';
import 'primitives/k_button.dart';
import 'primitives/k_icon.dart';

class KKbd extends StatelessWidget {
  const KKbd({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
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
              children: [
                ?label,
                const Spacer(),
                valueLabel ??
                    Text(
                      normalized == null
                          ? ''
                          : '${(normalized * 100).round()}%',
                    ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(t.radiusFull),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 6,
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
    this.height = 16,
    this.circle = false,
    super.key,
  });
  final double width;
  final double height;
  final bool circle;
  @override
  State<KSkeleton> createState() => _KSkeletonState();
}

class _KSkeletonState extends State<KSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

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
          height: widget.height,
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
  const KSpinner({this.label = 'Loading', this.size = 18, super.key});
  final String label;
  final double size;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: label,
      child: SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: t.colorActionPrimaryBackground,
          backgroundColor: t.colorBorderDefault,
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
    super.key,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
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
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: SizedBox(
            width: 40,
            height: t.sizeHitTarget.clamp(22, double.infinity),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 22,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: value
                      ? t.colorActionPrimaryBackground
                      : t.colorSurfaceSubtle,
                  border: Border.all(
                    color: value
                        ? t.colorActionPrimaryBackground
                        : t.colorBorderDefault,
                  ),
                  borderRadius: BorderRadius.circular(t.radiusFull),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: t.colorSurfaceRaised,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Color(0x29000000), blurRadius: 2),
                      ],
                    ),
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
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        overlayColor: t.colorActionPrimaryBackground.withValues(alpha: .12),
        trackHeight: 6,
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
  const _KSliderThumbShape({required this.fill, required this.border});
  final Color fill;
  final Color border;
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(18, 18);
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
      ..drawCircle(center, 9, Paint()..color = fill)
      ..drawCircle(
        center,
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
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
                      width: 38,
                      height: 42,
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
                        width: 24,
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
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final visible =
        pageCount <= 7
              ? List.generate(pageCount, (i) => i + 1)
              : <int>{
                  1,
                  for (
                    var i = page - siblingCount;
                    i <= page + siblingCount;
                    i++
                  )
                    if (i > 1 && i < pageCount) i,
                  pageCount,
                }.toList()
          ..sort();
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
                width: 28,
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
                          height: 1,
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
    super.key,
  });
  final List<KTabItem> items;
  final String value;
  final ValueChanged<String> onChanged;
  final String label;
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
            padding: const EdgeInsets.all(4),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: TextButton.icon(
                          icon: item.icon == null
                              ? const SizedBox.shrink()
                              : KIcon(item.icon!, size: 16),
                          label: item.label,
                          style: TextButton.styleFrom(
                            minimumSize: Size(0, t.sizeHitTarget),
                            backgroundColor: item.id == value
                                ? t.colorSurfaceRaised
                                : Colors.transparent,
                            foregroundColor: item.id == value
                                ? t.colorTextPrimary
                                : t.colorTextMuted,
                          ),
                          onPressed: item.enabled
                              ? () => onChanged(item.id)
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: t.spaceControlGap),
        current.content,
      ],
    );
  }
}

class KPopover extends StatelessWidget {
  const KPopover({
    required this.trigger,
    required this.content,
    this.label = 'Open popover',
    super.key,
  });
  final Widget trigger;
  final Widget content;
  final String label;
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () async {
          final box = context.findRenderObject()! as RenderBox;
          final offset = box.localToGlobal(Offset.zero);
          final overlay =
              Overlay.of(context).context.findRenderObject()! as RenderBox;
          final anchor = Rect.fromLTWH(
            offset.dx,
            offset.dy,
            box.size.width,
            box.size.height,
          );
          await showMenu<bool>(
            context: context,
            position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
            constraints: BoxConstraints(
              maxWidth: (overlay.size.width - 32).clamp(0, 360),
              maxHeight: (overlay.size.height - 32).clamp(0, 560),
            ),
            items: [
              PopupMenuItem<bool>(
                enabled: false,
                padding: EdgeInsets.zero,
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: tokens.colorTextPrimary,
                    fontFamily: tokens.fontFamily,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: content,
                  ),
                ),
              ),
            ],
          );
        },
        child: trigger,
      ),
    );
  }
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
        padding: const EdgeInsets.all(4),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                item.label,
                                const SizedBox(width: 6),
                                const KIcon(KIconName.chevronDown, size: 14),
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
  }) {
    if (MediaQuery.sizeOf(context).width < breakpoint) {
      return KBottomSheet.show<T>(
        context: context,
        title: title,
        description: description,
        actions: actions,
        closeLabel: closeLabel,
        dismissible: dismissible,
        child: child,
      );
    }
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: closeLabel ?? 'Close',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (routeContext, _, _) => Align(
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        child: _KResponsiveSideSheet(
          title: title,
          description: description,
          actions: actions,
          closeLabel: closeLabel,
          onClose: dismissible ? () => Navigator.of(routeContext).pop() : null,
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
  });
  final Widget title;
  final Widget child;
  final Widget? description;
  final Widget? actions;
  final String? closeLabel;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      color: t.colorSurfaceRaised,
      elevation: 0,
      child: SafeArea(
        child: SizedBox(
          width: 420,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  t.spaceLayoutGutter,
                  t.spaceLayoutGutter,
                  t.spaceControlGap,
                  t.spaceControlGap,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 4),
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
              Divider(height: 1, color: t.colorBorderDefault),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(t.spaceLayoutGutter),
                  child: child,
                ),
              ),
              if (actions != null) ...[
                Divider(height: 1, color: t.colorBorderDefault),
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
            const SizedBox(height: 4),
            DefaultTextStyle(
              style: TextStyle(color: t.colorTextMuted),
              child: current.description!,
            ),
          ],
          SizedBox(height: t.spaceLayoutGutter),
          current.content,
          SizedBox(height: t.spaceLayoutGutter),
          Row(
            children: [
              KButton(
                variant: KButtonVariant.secondary,
                label: previousLabel,
                onPressed: step > 0 ? () => onStepChanged(step - 1) : null,
              ),
              const Spacer(),
              if (current.optional && step < steps.length - 1) ...[
                KButton(
                  variant: KButtonVariant.secondary,
                  label: skipLabel,
                  onPressed: () => onStepChanged(step + 1),
                ),
                const SizedBox(width: 8),
              ],
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
    );
  }
}

enum KToastTone { neutral, success, warning, error }

class KToastController {
  KToastController._(this._entry);
  final OverlayEntry _entry;
  Timer? _timer;
  bool _dismissed = false;
  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    _entry.remove();
  }
}

class KToast extends StatelessWidget {
  const KToast({
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.onDismiss,
    this.dismissLabel = 'Dismiss',
    this.tone = KToastTone.neutral,
    super.key,
  });
  final Widget title;
  final Widget? description, icon, action;
  final VoidCallback? onDismiss;
  final String dismissLabel;
  final KToastTone tone;
  static KToastController show({
    required BuildContext context,
    required Widget title,
    Widget? description,
    Widget? icon,
    Widget? action,
    Duration duration = const Duration(seconds: 4),
    KToastTone tone = KToastTone.neutral,
    String dismissLabel = 'Dismiss',
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    late final KToastController controller;
    entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        right: 16,
        bottom: 16,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(overlayContext).width - 32 > 380
                    ? 380
                    : MediaQuery.sizeOf(overlayContext).width - 32,
              ),
              child: KToast(
                title: title,
                description: description,
                icon: icon,
                action: action,
                tone: tone,
                dismissLabel: dismissLabel,
                onDismiss: controller.dismiss,
              ),
            ),
          ),
        ),
      ),
    );
    controller = KToastController._(entry);
    overlay.insert(entry);
    controller._timer = Timer(duration, controller.dismiss);
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final border = switch (tone) {
      KToastTone.success => t.colorStatusSuccessBorder,
      KToastTone.warning => t.colorStatusWarningBorder,
      KToastTone.error => t.colorStatusErrorBorder,
      _ => t.colorBorderDefault,
    };
    final iconForeground = switch (tone) {
      KToastTone.success => t.colorStatusSuccessForeground,
      KToastTone.warning => t.colorStatusWarningForeground,
      KToastTone.error => t.colorStatusErrorForeground,
      _ => t.colorTextPrimary,
    };
    final iconBackground = switch (tone) {
      KToastTone.success => t.colorStatusSuccessBackground,
      KToastTone.warning => t.colorStatusWarningBackground,
      KToastTone.error => t.colorStatusErrorBackground,
      _ => t.colorSurfaceSubtle,
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(t.radiusCard),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: IconTheme(
                data: IconThemeData(color: iconForeground, size: 18),
                child: icon!,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: t.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: t.colorTextPrimary,
                  ),
                  child: title,
                ),
                if (description != null)
                  DefaultTextStyle(
                    style: TextStyle(
                      fontFamily: t.fontFamily,
                      color: t.colorTextMuted,
                    ),
                    child: description!,
                  ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
          if (onDismiss != null)
            KIconButton(
              icon: KIconName.x,
              label: dismissLabel,
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
