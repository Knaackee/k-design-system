import 'dart:ui' show SemanticsRole;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KTableAlign { start, center, end }

/// Column tracks include cell padding. Fixed widths override minWidth and flex.
class KTableColumn {
  const KTableColumn({
    required this.id,
    required this.header,
    this.headerLabel,
    this.width,
    this.paddingInline,
    this.minWidth = 160,
    this.flex = 1,
    this.align = KTableAlign.start,
  });
  final String id;
  final Widget header;
  final String? headerLabel;
  final double? width;

  /// Horizontal cell padding; defaults to the density control inset.
  final double? paddingInline;
  final double minWidth;
  final double flex;
  final KTableAlign align;
}

class KTableRow {
  const KTableRow({required this.id, required this.cells});
  final String id;
  final List<Widget> cells;
}

/// Presentational table with shared tracks and horizontal overflow.
/// The parent must provide a bounded width. Cells retain their own interactions.
class KTable extends StatelessWidget {
  const KTable({
    required this.columns,
    required this.rows,
    required this.label,
    this.showHeader = true,
    this.showRowDividers = true,
    super.key,
  });
  final List<KTableColumn> columns;
  final List<KTableRow> rows;
  final String label;
  final bool showHeader;
  final bool showRowDividers;

  void _validate() {
    if (label.trim().isEmpty || columns.isEmpty) {
      throw ArgumentError('KTable requires a nonempty label and columns');
    }
    final columnIds = <String>{};
    for (final column in columns) {
      if (column.paddingInline != null &&
          (!column.paddingInline!.isFinite || column.paddingInline! < 0)) {
        throw ArgumentError(
          'Column paddingInline must be finite and nonnegative',
        );
      }
      if (!showHeader &&
          (column.headerLabel == null || column.headerLabel!.trim().isEmpty)) {
        throw ArgumentError(
          'Hidden headers require nonempty headerLabel for each column',
        );
      }
      if (column.id.trim().isEmpty || !columnIds.add(column.id)) {
        throw ArgumentError('Column IDs must be nonempty and unique');
      }
      final base = column.width ?? column.minWidth;
      if (!base.isFinite ||
          base <= 0 ||
          (column.width == null &&
              (!column.flex.isFinite || column.flex <= 0))) {
        throw ArgumentError('Column dimensions must be positive and finite');
      }
    }
    final rowIds = <String>{};
    for (final row in rows) {
      if (row.id.trim().isEmpty ||
          !rowIds.add(row.id) ||
          row.cells.length != columns.length) {
        throw ArgumentError(
          'Rows require unique nonempty IDs and one cell per column',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _validate();
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final size = tokens.fontBodySize;
    final minimum =
        tokens.sizeControl +
        2 * tokens.spaceControlGap +
        tokens.borderWidthDefault;
    TextStyle style(bool header) {
      final weight = header ? tokens.fontLabelWeight : tokens.fontBodyWeight;
      return TextStyle(
        fontFamily: tokens.fontFamily,
        fontSize: size,
        height: tokens.fontBodyLineHeight / size,
        leadingDistribution: TextLeadingDistribution.even,
        letterSpacing: tokens.fontBodyLetterSpacing,
        fontWeight: weight,
        color: header ? tokens.colorTextMuted : tokens.colorTextPrimary,
        fontVariations: [
          FontVariation.weight(weight.value.toDouble()),
          FontVariation.opticalSize(
            MediaQuery.textScalerOf(context).scale(size).clamp(14, 32),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw ArgumentError('KTable requires a bounded width');
        }
        final base = columns.fold(
          0.0,
          (sum, c) => sum + (c.width ?? c.minWidth),
        );
        final flex = columns
            .where((c) => c.width == null)
            .fold(0.0, (sum, c) => sum + c.flex);
        if (!base.isFinite || !flex.isFinite) {
          throw ArgumentError('Combined column dimensions must be finite');
        }
        final extra = math.max(0.0, constraints.maxWidth - base);
        final widths = [
          for (final c in columns)
            c.width ?? c.minWidth + (flex == 0 ? 0 : extra * (c.flex / flex)),
        ];
        final width = widths.fold(0.0, (sum, w) => sum + w);
        TableRow row(List<Widget> cells, bool header, LocalKey key) => TableRow(
          key: key,
          decoration: BoxDecoration(
            color: header
                ? tokens.colorSurfaceSubtle
                : tokens.colorSurfaceCanvas,
            border: Border(
              bottom: BorderSide(
                width: tokens.borderWidthDefault,
                color: showRowDividers
                    ? tokens.colorBorderDefault
                    : Colors.transparent,
              ),
            ),
          ),
          children: [
            for (var i = 0; i < cells.length; i++)
              Semantics(
                label: !showHeader && !header ? columns[i].headerLabel : null,
                container: true,
                explicitChildNodes: true,
                role: header ? SemanticsRole.columnHeader : SemanticsRole.cell,
                child: DefaultTextStyle(
                  style: style(header),
                  textAlign: switch (columns[i].align) {
                    KTableAlign.start => TextAlign.start,
                    KTableAlign.center => TextAlign.center,
                    KTableAlign.end => TextAlign.end,
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minimum),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        columns[i].paddingInline ??
                            tokens.spaceControlInsetInline,
                        tokens.spaceControlGap,
                        columns[i].paddingInline ??
                            tokens.spaceControlInsetInline,
                        tokens.spaceControlGap + tokens.borderWidthDefault,
                      ),
                      child: Align(
                        heightFactor: 1,
                        alignment: switch (columns[i].align) {
                          KTableAlign.start => AlignmentDirectional.centerStart,
                          KTableAlign.center => AlignmentDirectional.center,
                          KTableAlign.end => AlignmentDirectional.centerEnd,
                        },
                        child: cells[i],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Semantics(
              label: label,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: {
                  for (var i = 0; i < widths.length; i++)
                    i: FixedColumnWidth(widths[i]),
                },
                children: [
                  if (showHeader)
                    row(
                      [for (final c in columns) c.header],
                      true,
                      const ValueKey<int>(0),
                    ),
                  for (final r in rows) row(r.cells, false, ValueKey(r.id)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
