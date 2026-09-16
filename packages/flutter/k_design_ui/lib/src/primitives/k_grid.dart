import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_layout.dart';

class KGrid extends StatelessWidget {
  const KGrid({
    required this.children,
    this.minColumnWidth = 240,
    this.columns,
    this.gap = KLayoutGap.section,
    super.key,
  });
  final List<Widget> children;
  final double minColumnWidth;

  /// Omit for automatic responsive columns.
  final int? columns;
  final KLayoutGap gap;
  @override
  Widget build(BuildContext context) {
    if (!minColumnWidth.isFinite || minColumnWidth <= 0) {
      throw ArgumentError.value(
        minColumnWidth,
        'minColumnWidth',
        'Must be positive and finite',
      );
    }
    if (columns != null && columns! < 1) {
      throw ArgumentError.value(columns, 'columns', 'Must be positive');
    }
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final spacing = switch (gap) {
      KLayoutGap.control => tokens.spaceControlGap,
      KLayoutGap.action => tokens.spaceContentActionGap,
      KLayoutGap.section => tokens.spaceLayoutSectionGap,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError('KGrid requires a bounded width');
        }
        final count =
            columns ??
            math.max(
              1,
              ((constraints.maxWidth + spacing) / (minColumnWidth + spacing))
                  .floor(),
            );
        final itemWidth = math.max(
          0.0,
          (constraints.maxWidth - (count - 1) * spacing) / count,
        );
        return SizedBox(
          width: constraints.maxWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing,
            children: [
              for (var start = 0; start < children.length; start += count)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: spacing,
                  children: [
                    for (
                      var n = start;
                      n < math.min(start + count, children.length);
                      n++
                    )
                      SizedBox(width: itemWidth, child: children[n]),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
