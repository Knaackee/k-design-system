import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Drag-to-dismiss for every bottom sheet (Decision 0015).
///
/// - The sheet follows the finger from the handle, the header and from the
///   body: a list inside the sheet hands the drag to the sheet whenever it is
///   at its top, as on iOS and Android.
/// - Released past a quarter of its height or with a downward fling, the
///   sheet asks to close through [onDismiss] (default `Navigator.maybePop`,
///   so a `PopScope` with unsaved changes can hold it). The exit continues
///   from the finger position; a held-back sheet settles back.
class KSheetDrag extends StatefulWidget {
  const KSheetDrag({
    required this.child,
    this.enabled = true,
    this.onDismiss,
    super.key,
  });

  final Widget child;
  final bool enabled;

  /// Called to close; defaults to `Navigator.maybePop`.
  final VoidCallback? onDismiss;

  @override
  State<KSheetDrag> createState() => _KSheetDragState();
}

class _KSheetDragState extends State<KSheetDrag>
    with SingleTickerProviderStateMixin {
  // Flings faster than this close the sheet regardless of the distance.
  static const _flingVelocity = 700.0;
  static const _dismissFraction = .25;

  late final AnimationController _offset;
  bool _closing = false;

  double get offset => _offset.value;

  @override
  void initState() {
    super.initState();
    _offset = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  /// Moves the sheet by [delta] (positive is down) and returns the part of
  /// [delta] the sheet used.
  double drag(double delta) {
    if (_closing || !widget.enabled) return 0;
    final next = math.max(0.0, _offset.value + delta);
    final used = next - _offset.value;
    if (used != 0) {
      _offset.stop();
      _offset.value = next;
    }
    return used;
  }

  /// Ends a drag with [velocity] in logical pixels per second (positive is
  /// down).
  Future<void> release(double velocity) async {
    if (_closing || _offset.value <= 0) return;
    final height = context.size?.height ?? 1;
    final dismiss =
        velocity > _flingVelocity ||
        (_offset.value > height * _dismissFraction && velocity > -300);
    if (dismiss) {
      _closing = true;
      final route = ModalRoute.of(context);
      if (widget.onDismiss case final close?) {
        close();
      } else {
        await Navigator.of(context).maybePop();
      }
      if (!mounted) return;
      // Popping: keep the offset so the exit continues from the finger.
      if (route != null && !route.isCurrent) return;
      // Held back (unsaved changes): settle back below.
      _closing = false;
    }
    final motion = Theme.of(
      context,
    ).extension<KDesignTokens>()!.motion(KMotionRole.control);
    await _offset.animateTo(0, duration: motion.settle, curve: motion.curve);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return GestureDetector(
      // Handle, header and non-scrolling areas.
      onVerticalDragUpdate: (details) => drag(details.delta.dy),
      onVerticalDragEnd: (details) => release(details.primaryVelocity ?? 0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          physics: _KSheetScrollPhysics(
            this,
            parent: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
          ),
          overscroll: false,
        ),
        child: AnimatedBuilder(
          animation: _offset,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _offset.value),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hands vertical drags at the top of a list to the sheet, and keeps the list
/// still while the sheet is pulled down.
class _KSheetScrollPhysics extends ScrollPhysics {
  const _KSheetScrollPhysics(this.sheet, {super.parent});

  final _KSheetDragState sheet;

  @override
  _KSheetScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _KSheetScrollPhysics(sheet, parent: buildParent(ancestor));

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (position.axis != Axis.vertical) {
      return super.applyPhysicsToUserOffset(position, offset);
    }
    // Finger down at the top: the sheet moves, the list stays.
    if (offset > 0 && position.pixels <= position.minScrollExtent) {
      return offset - sheet.drag(offset);
    }
    // Finger up while the sheet is pulled down: the sheet returns first.
    if (offset < 0 && sheet.offset > 0) {
      return super.applyPhysicsToUserOffset(
        position,
        offset - sheet.drag(offset),
      );
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.axis == Axis.vertical && sheet.offset > 0) {
      // Scroll velocity is positive when content moves up (finger up).
      sheet.release(-velocity);
      return null;
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
