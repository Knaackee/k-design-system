import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../feedback/k_haptics.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';

/// One option of a [KSegmentedControl].
class KSegment<T> {
  const KSegment({required this.value, required this.label, this.icon});
  final T value;
  final String label;
  final KIconName? icon;
}

/// Two to five mutually exclusive options that switch a view or a mode in
/// place (Apple segmented control): a period on a chart, list vs. grid, a
/// role in an invite form. Not for navigation between screens (use tabs or
/// the app shell) and not for actions.
///
/// Segments share the width equally; the selection slides with the
/// `control` motion role. From 1.3× text, three or more segments stack
/// vertically so labels never break mid-word.
class KSegmentedControl<T> extends StatelessWidget {
  const KSegmentedControl({
    required this.segments,
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final List<KSegment<T>> segments;
  final T value;

  /// Null disables the control.
  final ValueChanged<T>? onChanged;

  /// Accessible name of the group (for example "Period").
  final String label;

  @override
  Widget build(BuildContext context) {
    assert(
      segments.length >= 2 && segments.length <= 5,
      'KSegmentedControl takes 2 to 5 segments (Apple HIG); use a select '
      'or tabs for more.',
    );
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final motion = t.motion(KMotionRole.control);
    final index = segments.indexWhere((segment) => segment.value == value);
    final vertical =
        segments.length >= 3 &&
        MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    // Material 3 segmented button: outlined pill, tonal selection with a
    // check mark, dividers between segments (Decision 0015).
    final material = KAdaptive.maybeOf(context)?.style == KStyle.material;
    final inset = material ? 0.0 : t.spaceMicro;
    final radius = BorderRadius.circular(
      material ? t.radiusFull : t.radiusControl,
    );
    final innerRadius = material
        ? BorderRadius.zero
        : BorderRadius.circular(
            (t.radiusControl - inset).clamp(0, t.radiusControl).toDouble(),
          );
    final thumbDecoration = material
        ? BoxDecoration(color: t.colorBrandPrimaryBackground)
        : BoxDecoration(
            color: t.colorSurfaceRaised,
            borderRadius: innerRadius,
            border: Border.all(
              color: t.colorBorderDefault,
              width: t.spaceHairline,
            ),
          );

    Widget segment(int i) => _KSegmentButton(
      segment: segments[i],
      selected: i == index,
      enabled: onChanged != null,
      radius: innerRadius,
      check: material,
      decoration: vertical && i == index ? thumbDecoration : null,
      onPressed: () {
        if (i == index) return;
        kHaptic(context, KHapticCue.selection);
        onChanged!(segments[i].value);
      },
    );

    final Widget content;
    if (vertical) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < segments.length; i++) segment(i)],
      );
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return IntrinsicHeight(
            child: Stack(
              children: [
                if (index >= 0)
                  AnimatedPositionedDirectional(
                    duration: motion.settle,
                    curve: motion.curve,
                    start: width * index,
                    width: width,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(decoration: thumbDecoration),
                  ),
                if (material)
                  for (var i = 1; i < segments.length; i++)
                    PositionedDirectional(
                      start: width * i,
                      width: t.spaceHairline,
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(color: t.colorBorderStrong),
                    ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < segments.length; i++)
                      Expanded(child: segment(i)),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
    return Semantics(
      label: label,
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: material
              ? Border.all(color: t.colorBorderStrong, width: t.spaceHairline)
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: material ? Colors.transparent : t.colorSurfaceSubtle,
            ),
            child: Padding(padding: EdgeInsets.all(inset), child: content),
          ),
        ),
      ),
    );
  }
}

class _KSegmentButton<T> extends StatelessWidget {
  const _KSegmentButton({
    required this.segment,
    required this.selected,
    required this.enabled,
    required this.radius,
    required this.onPressed,
    this.check = false,
    this.decoration,
  });

  final KSegment<T> segment;
  final bool selected;
  final bool enabled;
  final BorderRadius radius;
  final BoxDecoration? decoration;
  final VoidCallback onPressed;

  /// Material: a selected segment without an icon shows a check mark.
  final bool check;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final color = !enabled
        ? t.colorTextMuted
        : selected
        ? t.colorTextPrimary
        : t.colorTextMuted;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      enabled: enabled,
      label: segment.label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onPressed : null,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: t.colorActionGhostHover,
          focusColor: t.colorActionGhostHover,
          child: Container(
            decoration: decoration,
            constraints: BoxConstraints(
              minHeight: t.sizeHitTarget > t.sizeControl
                  ? t.sizeHitTarget - 2 * t.spaceMicro
                  : t.sizeControl - 2 * t.spaceMicro,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: t.spaceControlGap,
              vertical: t.spaceTight,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (segment.icon ?? (check && selected ? KIconName.check : null)
                    case final icon?) ...[
                  KIcon(icon, size: 16, color: color),
                  SizedBox(width: t.spaceTight),
                ],
                Flexible(
                  child: ExcludeSemantics(
                    child: KText(
                      segment.label,
                      variant: KTextVariant.label,
                      align: TextAlign.center,
                      style: TextStyle(color: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
