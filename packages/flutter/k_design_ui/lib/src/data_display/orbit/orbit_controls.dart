import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../../extended_components.dart';
import '../../primitives/k_button.dart';
import 'orbit_models.dart';

class KOrbitControls extends StatelessWidget {
  const KOrbitControls({
    required this.paused,
    required this.speed,
    required this.labels,
    required this.onReset,
    required this.onPauseChanged,
    required this.onSpeedChanged,
    super.key,
  });

  final bool paused;
  final double speed;
  final KOrbitLabels labels;
  final VoidCallback onReset;
  final ValueChanged<bool>? onPauseChanged;
  final ValueChanged<double>? onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    // Wraps under large text instead of overflowing (Decision 0010).
    final buttons = Wrap(
      spacing: tokens.spaceControlGap,
      runSpacing: tokens.spaceControlGap,
      children: [
        KButton(
          label: labels.reset,
          variant: KButtonVariant.secondary,
          onPressed: onReset,
        ),
        if (onPauseChanged != null) ...[
          KButton(
            label: paused ? labels.resume : labels.pause,
            variant: KButtonVariant.secondary,
            onPressed: onPauseChanged == null
                ? null
                : () => onPauseChanged!.call(!paused),
          ),
        ],
      ],
    );
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        tickMarkShape: SliderTickMarkShape.noTickMark,
        padding: EdgeInsets.zero,
      ),
      child: KSlider(
        label: labels.speed,
        value: speed,
        min: 0,
        max: 2,
        divisions: 8,
        valueLabel: (value) => '${value.toStringAsFixed(2)}×',
        onChanged: onSpeedChanged,
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(top: tokens.spaceControlGap),
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 440
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: buttons,
                    ),
                    if (onSpeedChanged != null) ...[
                      SizedBox(height: tokens.spaceControlGap),
                      slider,
                    ],
                  ],
                )
              : Row(
                  children: [
                    Flexible(child: buttons),
                    if (onSpeedChanged != null) ...[
                      SizedBox(width: tokens.spaceControlGap),
                      Expanded(child: slider),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
