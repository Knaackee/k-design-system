import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_data_table.dart';
import 'k_data_table_header.dart';
import 'k_table.dart';

/// Header scrolling follows the data viewport without consuming a data index.
class KDataTableVirtualHeader<T> extends StatelessWidget {
  const KDataTableVirtualHeader({
    required this.table,
    required this.widths,
    required this.gutter,
    required this.horizontal,
    required this.child,
    super.key,
  });
  final KDataTable<T> table;
  final List<double> widths;
  final double gutter;
  final ScrollController horizontal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!table.hasHeader) return child;
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final width = gutter + widths.fold(0.0, (a, b) => a + b);
    final direction = Directionality.of(context) == TextDirection.rtl ? 1 : -1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRect(
          child: AnimatedBuilder(
            animation: horizontal,
            builder: (context, _) => OverflowBox(
              alignment: AlignmentDirectional.topStart,
              fit: OverflowBoxFit.deferToChild,
              minWidth: width,
              maxWidth: width,
              child: Transform.translate(
                offset: Offset(
                  direction * (horizontal.hasClients ? horizontal.offset : 0),
                  0,
                ),
                child: SizedBox(
                  width: width,
                  child: ColoredBox(
                    color: tokens.colorSurfaceSubtle,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: gutter),
                      child: KTable(
                        label: '${table.label} columns',
                        showRowDividers: table.showRowDividers,
                        columns: [
                          for (var i = 0; i < table.displayColumns.length; i++)
                            KTableColumn(
                              id: table.displayColumns[i].id,
                              header: KDataTableHeader(
                                table: table,
                                column: table.displayColumns[i],
                              ),
                              width: widths[i],
                              paddingInline:
                                  table.displayColumns[i].paddingInline,
                              align: table.displayColumns[i].align,
                            ),
                        ],
                        rows: const [],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: table.viewport!.height, child: child),
      ],
    );
  }
}
