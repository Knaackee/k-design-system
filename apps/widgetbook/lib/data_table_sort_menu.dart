import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class DataTableSortMenu extends StatelessWidget {
  const DataTableSortMenu({required this.onChanged, super.key});
  final ValueChanged<KDataTableSort?> onChanged;

  @override
  Widget build(BuildContext context) => KMenuButton(
    label: 'Sort',
    actions: [
      KMenuAction(
        id: 'original',
        label: 'Original order',
        onSelect: () => onChanged(null),
      ),
      for (final column in const [('project', 'Project'), ('budget', 'Budget')])
        for (final direction in KDataTableSortDirection.values)
          KMenuAction(
            id: '${column.$1}-${direction == KDataTableSortDirection.ascending ? 'asc' : 'desc'}',
            label: '${column.$2} ${direction.name}',
            onSelect: () => onChanged(
              KDataTableSort(columnId: column.$1, direction: direction),
            ),
          ),
    ],
  );
}
