import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Common virtual data-cell styling and row semantics.
class KDataTableVirtualCell extends StatelessWidget {
  const KDataTableVirtualCell({
    required this.rowIndex,
    required this.label,
    required this.showRowDividers,
    required this.child,
    this.textAlign = TextAlign.start,
    super.key,
  });
  final int rowIndex;
  final String? label;
  final bool showRowDividers;
  final Widget child;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final scaler = MediaQuery.textScalerOf(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.cell,
      sortKey: OrdinalSortKey(rowIndex.toDouble()),
      identifier: 'k-data-row-${rowIndex + 1}',
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colorSurfaceCanvas,
          border: Border(
            bottom: BorderSide(
              width: t.borderWidthDefault,
              color: showRowDividers
                  ? t.colorBorderDefault
                  : Colors.transparent,
            ),
          ),
        ),
        child: DefaultTextStyle(
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: t.fontFamily,
            fontSize: t.fontBodySize,
            height: t.fontBodyLineHeight / t.fontBodySize,
            leadingDistribution: TextLeadingDistribution.even,
            fontWeight: t.fontBodyWeight,
            color: t.colorTextPrimary,
            letterSpacing: t.fontBodyLetterSpacing,
            fontVariations: [
              FontVariation.weight(t.fontBodyWeight.value.toDouble()),
              FontVariation.opticalSize(
                scaler.scale(t.fontBodySize).clamp(14, 32),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
