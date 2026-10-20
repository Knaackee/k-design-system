import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_map_day_types.dart';

class KMapDaySheetHandle extends StatefulWidget {
  const KMapDaySheetHandle({
    required this.state,
    required this.labels,
    required this.onStateChanged,
    required this.onDragUpdate,
    required this.onDragEnd,
    super.key,
  });

  final KMapDayPanelState state;
  final KMapDayLabels labels;
  final ValueChanged<KMapDayPanelState> onStateChanged;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  State<KMapDaySheetHandle> createState() => _KMapDaySheetHandleState();
}

class _KMapDaySheetHandleState extends State<KMapDaySheetHandle> {
  void _step(int delta) => widget.onStateChanged(widget.state.step(delta));

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return Semantics(
      label: widget.labels.resize,
      value: widget.labels.panelState(widget.state),
      increasedValue: widget.state == KMapDayPanelState.expanded
          ? null
          : widget.labels.panelState(widget.state.step(1)),
      decreasedValue: widget.state == KMapDayPanelState.compact
          ? null
          : widget.labels.panelState(widget.state.step(-1)),
      onIncrease: widget.state == KMapDayPanelState.expanded
          ? null
          : () => _step(1),
      onDecrease: widget.state == KMapDayPanelState.compact
          ? null
          : () => _step(-1),
      child: GestureDetector(
        key: const ValueKey('k-map-day-handle'),
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) =>
            widget.onDragUpdate(details.delta.dy),
        onVerticalDragEnd: (_) => widget.onDragEnd(),
        child: SizedBox(
          height: tokens.spaceHairline * 28,
          child: Center(
            child: Container(
              width: tokens.spaceHairline * 36,
              height: tokens.spaceHairline * 4,
              decoration: BoxDecoration(
                color: tokens.colorBorderDefault,
                borderRadius: BorderRadius.circular(tokens.spaceHairline * 4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
