import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const _projects = [
  (
    id: 'atlas',
    title: 'Atlas website',
    owner: 'Alex Morgan',
    budget: '€12,000',
  ),
  (
    id: 'orbit',
    title: 'Orbit mobile app',
    owner: 'Jordan Lee',
    budget: '€8,500',
  ),
  (
    id: 'docs',
    title: 'Design system documentation and accessibility review',
    owner: 'Sam Rivera',
    budget: '€3,200',
  ),
];
const _statuses = [
  KSelectOption(value: 'planned', label: 'Planned', icon: KIconName.minus),
  KSelectOption(value: 'active', label: 'In progress', icon: KIconName.clock),
  KSelectOption(value: 'done', label: 'Done', icon: KIconName.check),
];

class TableFixture extends StatefulWidget {
  const TableFixture({this.cells = false, super.key});
  final bool cells;

  @override
  State<TableFixture> createState() => _TableFixtureState();
}

class _TableFixtureState extends State<TableFixture> {
  final _values = <String, String>{
    'atlas': 'active',
    'orbit': 'planned',
    'docs': 'done',
  };
  String _result = 'No action selected';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: t.spaceLayoutGutter),
      child: KContainer(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            const KText('Project overview', variant: KTextVariant.heading4),
            KTable(
              label: 'Project overview',
              columns: [
                const KTableColumn(
                  id: 'project',
                  header: Text('Project'),
                  minWidth: 240,
                  flex: 2,
                ),
                if (widget.cells)
                  const KTableColumn(
                    id: 'status',
                    header: Text('Status'),
                    minWidth: 180,
                  ),
                const KTableColumn(id: 'owner', header: Text('Owner')),
                if (widget.cells)
                  const KTableColumn(
                    id: 'actions',
                    header: Text('Actions'),
                    width: 88,
                    align: KTableAlign.end,
                  )
                else
                  const KTableColumn(
                    id: 'amount',
                    header: Text('Budget'),
                    width: 120,
                    align: KTableAlign.end,
                  ),
              ],
              rows: [
                for (final project in _projects)
                  KTableRow(
                    id: project.id,
                    cells: [
                      Text(project.title),
                      if (widget.cells)
                        KSelect(
                          label: 'Status for ${project.title}',
                          options: _statuses,
                          value: _values[project.id],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _values[project.id] = value;
                              final label = _statuses
                                  .firstWhere((option) => option.value == value)
                                  .label;
                              _result = '${project.title}: $label';
                            });
                          },
                        ),
                      Text(project.owner),
                      if (widget.cells)
                        KOverflowMenu(
                          label: 'Actions for ${project.title}',
                          actions: [
                            KMenuAction(
                              id: 'open',
                              label: 'Open',
                              icon: KIconName.externalLink,
                              onSelect: () => setState(
                                () => _result = 'Open: ${project.title}',
                              ),
                            ),
                            KMenuAction(
                              id: 'copy',
                              label: 'Copy name',
                              icon: KIconName.copy,
                              onSelect: () => setState(
                                () => _result = 'Copy name: ${project.title}',
                              ),
                            ),
                          ],
                        )
                      else
                        Text(project.budget),
                    ],
                  ),
              ],
            ),
            if (widget.cells)
              Semantics(liveRegion: true, child: KText(_result)),
          ],
        ),
      ),
    );
  }
}
