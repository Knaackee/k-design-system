import 'package:flutter/material.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import 'k_data_table.dart';
import 'k_data_table_virtual_types.dart';

Widget buildKDataTableSpanning<T>(
  KDataTable<T> table,
  KDataTableEntry<T> entry,
  double indent,
  bool Function() allowExit,
) {
  Widget child;
  if (entry.kind == KDataTableEntryKind.footer) {
    child =
        table.footerBuilder?.call(
          KDataTableSection(rows: entry.rows, path: entry.path),
        ) ??
        const SizedBox.shrink();
  } else {
    final hasDraft = table.draftRows.any(
      (d) =>
          d.originPath.length >= entry.path.length &&
          List.generate(
            entry.path.length,
            (i) =>
                d.originPath[i].id == entry.path[i].id &&
                d.originPath[i].value == entry.path[i].value,
          ).every((v) => v),
    );
    final collapsed =
        table.collapsedGroups.contains(entry.groupKey) && !hasDraft;
    final label = '${entry.label} (${entry.count})';
    child = table.onCollapsedGroupsChanged == null
        ? Text(label)
        : Semantics(
            expanded: !collapsed,
            child: KButton(
              label: label,
              variant: KButtonVariant.ghost,
              leading: KIcon(
                collapsed ? KIconName.chevronRight : KIconName.chevronDown,
              ),
              onPressed: () {
                if (hasDraft || !allowExit()) return;
                final next = {...table.collapsedGroups};
                if (!next.remove(entry.groupKey)) next.add(entry.groupKey!);
                table.onCollapsedGroupsChanged!(next);
              },
            ),
          );
  }
  return Padding(
    padding: EdgeInsetsDirectional.only(start: entry.depth * indent),
    child: Align(alignment: AlignmentDirectional.centerStart, child: child),
  );
}
