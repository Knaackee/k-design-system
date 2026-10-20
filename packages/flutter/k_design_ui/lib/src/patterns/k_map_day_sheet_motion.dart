import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_map_day_sheet_controller.dart';
import 'k_map_day_types.dart';

typedef KMapDaySheetBuilder =
    Widget Function(
      BuildContext context,
      double fraction,
      KMapDayPanelState? state,
      ValueChanged<double> onDragUpdate,
      VoidCallback onDragEnd,
    );

class KMapDaySheetMotion extends StatefulWidget {
  const KMapDaySheetMotion({
    required this.state,
    required this.heights,
    required this.builder,
    required this.onStateChanged,
    this.controller,
    this.onFractionChanged,
    super.key,
  });

  final KMapDayPanelState state;
  final KMapDayPanelHeights heights;
  final KMapDaySheetBuilder builder;
  final ValueChanged<KMapDayPanelState> onStateChanged;
  final KMapDaySheetController? controller;
  final ValueChanged<double>? onFractionChanged;

  @override
  State<KMapDaySheetMotion> createState() => _KMapDaySheetMotionState();
}

class _KMapDaySheetMotionState extends State<KMapDaySheetMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController.unbounded(
    vsync: this,
    value: widget.heights.forState(widget.state),
  )..addListener(_emitPosition);
  late final KMapDaySheetBinding _binding = KMapDaySheetBinding(
    fraction: _animation.value,
    state: widget.state,
    isSheet: true,
    animateTo: _animateTo,
    snapTo: _snapTo,
  );
  double _viewportHeight = 1;
  double _compactFraction = 0;
  double _bodyMinimumFraction = 0;
  double _expandedFraction = 1;
  double? _lastReported;

  double get _actualFraction =>
      _animation.value.clamp(_compactFraction, _expandedFraction).toDouble();

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(_binding);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitPosition());
  }

  @override
  void didUpdateWidget(covariant KMapDaySheetMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?.detach(_binding);
      widget.controller?.attach(_binding);
    }
    if (oldWidget.state != widget.state) {
      _animateTo(widget.heights.forState(widget.state));
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(_binding);
    _animation.dispose();
    super.dispose();
  }

  Future<void> _animateTo(double fraction) async {
    if (!_animation.value.isFinite) return;
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final target = _clampProgrammaticTarget(fraction);
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.value = target;
      return;
    }
    try {
      await _animation
          .animateTo(
            target,
            duration: tokens.motionStandard,
            curve: Curves.easeOut,
          )
          .orCancel;
    } on TickerCanceled {
      // A newer drag or command owns the current position.
    }
  }

  Future<void> _snapTo(KMapDayPanelState state) async {
    widget.onStateChanged(state);
    await _animateTo(widget.heights.forState(state));
  }

  void _drag(double deltaY) {
    _animation.stop();
    _animation.value = (_animation.value - deltaY / _viewportHeight).clamp(
      _compactFraction,
      _expandedFraction,
    );
  }

  void _endDrag() {
    final state = KMapDayPanelState.values.reduce((a, b) {
      final aDistance = (_renderedSnap(a) - _actualFraction).abs();
      final bDistance = (_renderedSnap(b) - _actualFraction).abs();
      return aDistance <= bDistance ? a : b;
    });
    _snapTo(state);
  }

  KMapDayPanelState? _resolvedState(double fraction) {
    for (final state in KMapDayPanelState.values) {
      final configured = _renderedSnap(state);
      if ((configured - fraction).abs() <= 1e-4) return state;
    }
    return null;
  }

  void _emitPosition() {
    if (!mounted) return;
    final fraction = _actualFraction;
    final state = _resolvedState(fraction);
    _binding
      ..fraction = fraction
      ..state = state;
    widget.controller?.updatePosition(fraction, state);
    if (_lastReported == null || (_lastReported! - fraction).abs() > 1e-6) {
      _lastReported = fraction;
      widget.onFractionChanged?.call(fraction);
    }
  }

  double _renderedSnap(KMapDayPanelState state) => switch (state) {
    KMapDayPanelState.compact => _compactFraction,
    KMapDayPanelState.medium =>
      widget.heights.medium
          .clamp(_bodyMinimumFraction, _expandedFraction)
          .toDouble(),
    KMapDayPanelState.expanded => _expandedFraction,
  };

  double _clampProgrammaticTarget(double fraction) {
    if (fraction <= _compactFraction) return _compactFraction;
    return fraction.clamp(_bodyMinimumFraction, _expandedFraction).toDouble();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _viewportHeight = constraints.maxHeight;
      final tokens =
          Theme.of(context).extension<KDesignTokens>() ??
          KDesignTokens.orbitLight;
      final oldCompact = _compactFraction;
      final oldBodyMinimum = _bodyMinimumFraction;
      _compactFraction = widget.heights.compact.clamp(
        tokens.spaceHairline * 230 / _viewportHeight,
        widget.heights.expanded,
      );
      _bodyMinimumFraction = (tokens.spaceHairline * 360 / _viewportHeight)
          .clamp(_compactFraction, widget.heights.expanded);
      _expandedFraction = widget.heights.expanded;
      if (oldCompact != _compactFraction ||
          oldBodyMinimum != _bodyMinimumFraction) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _emitPosition());
      }
      return Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) => SizedBox(
            key: const ValueKey('k-map-day-sheet'),
            width: double.infinity,
            height: _viewportHeight * _actualFraction,
            child: widget.builder(
              context,
              _actualFraction,
              _actualFraction < _bodyMinimumFraction
                  ? KMapDayPanelState.compact
                  : _resolvedState(_actualFraction),
              _drag,
              _endDrag,
            ),
          ),
        ),
      );
    },
  );
}
