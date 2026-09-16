import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KSeparatorOrientation { horizontal, vertical }

/// Decorative separation; semantic grouping belongs to surrounding content.
class KSeparator extends StatelessWidget {
  const KSeparator({
    this.orientation = KSeparatorOrientation.horizontal,
    this.length,
    super.key,
  });
  final KSeparatorOrientation orientation;
  final double? length;
  @override
  Widget build(BuildContext context) {
    if (length != null && (!length!.isFinite || length! < 0)) {
      throw ArgumentError.value(
        length,
        'length',
        'Must be nonnegative and finite',
      );
    }
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final horizontal = orientation == KSeparatorOrientation.horizontal;
    return ExcludeSemantics(
      child: SizedBox(
        width: horizontal
            ? length ?? double.infinity
            : tokens.borderWidthDefault,
        height: horizontal ? tokens.borderWidthDefault : length ?? 24,
        child: ColoredBox(color: tokens.colorBorderDefault),
      ),
    );
  }
}
