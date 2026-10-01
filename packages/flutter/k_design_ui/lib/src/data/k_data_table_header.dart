import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_overflow_text.dart';
import 'k_data_table.dart';
import 'k_table.dart';

/// Shared controlled header for ordinary and virtual table tracks.
class KDataTableHeader<T> extends StatelessWidget {
  const KDataTableHeader({
    required this.table,
    required this.column,
    super.key,
  });
  final KDataTable<T> table;
  final KDataTableColumn<T> column;

  @override
  Widget build(BuildContext context) {
    final direction = table.sort?.columnId == column.id
        ? table.sort!.direction
        : null;
    final sortable = column.compare != null;
    final interactive = sortable && table.onSortChanged != null;
    final icon = KIcon(switch (direction) {
      KDataTableSortDirection.ascending => KIconName.arrowUp,
      KDataTableSortDirection.descending => KIconName.arrowDown,
      null => KIconName.arrowUpDown,
    });
    if (!column.headerContentInset.isFinite || column.headerContentInset < 0) {
      throw ArgumentError(
        'Header content inset must be finite and nonnegative',
      );
    }
    final end = column.align == KTableAlign.end;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: column.headerContentInset),
      child: Semantics(
        value: sortable ? direction?.name ?? 'not sorted' : null,
        child: interactive
            ? KButton(
                label: column.label,
                variant: KButtonVariant.ghost,
                paddingInline: 0,
                leading: end ? icon : null,
                trailing: end ? null : icon,
                onPressed: () {
                  if (table.interactiveCell != null &&
                      !(table.onBeforeActiveCellExit?.call() ?? false)) {
                    return;
                  }
                  table.onSortChanged!(
                    direction == KDataTableSortDirection.descending
                        ? null
                        : KDataTableSort(
                            columnId: column.id,
                            direction:
                                direction == KDataTableSortDirection.ascending
                                ? KDataTableSortDirection.descending
                                : KDataTableSortDirection.ascending,
                          ),
                  );
                },
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (direction != null && end) ...[
                    icon,
                    SizedBox(
                      width:
                          (Theme.of(context).extension<KDesignTokens>() ??
                                  KDesignTokens.orbitLight)
                              .spaceControlGap,
                    ),
                  ],
                  Flexible(child: KOverflowText(text: Text(column.label))),
                  if (direction != null && !end) ...[
                    SizedBox(
                      width:
                          (Theme.of(context).extension<KDesignTokens>() ??
                                  KDesignTokens.orbitLight)
                              .spaceControlGap,
                    ),
                    icon,
                  ],
                ],
              ),
      ),
    );
  }
}
