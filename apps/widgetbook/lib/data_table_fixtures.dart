import 'package:flutter/material.dart';
import 'data_table_title_cell.dart';
import 'data_table_sort_menu.dart';
import 'data_table_budget_cell.dart';
import 'data_table_project_data.dart';
export 'data_table_project_data.dart' show DataTableProject;
import 'data_table_draft_controls.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class DataTableFixture extends StatefulWidget {
  const DataTableFixture({
    this.grouped = false,
    this.showHeader = false,
    this.singleColumn = false,
    this.addLabel = 'Add project',
    this.initialEditColumn = 'project',
    this.createProject,
    this.saveProject,
    this.savePolicy = KDataTableDraftSavePolicy.explicit,
    this.allowAdd = true,
    super.key,
  });
  final String addLabel;
  final Future<DataTableProject> Function(DataTableProject)? saveProject;
  final KDataTableDraftSavePolicy savePolicy;
  final bool allowAdd;
  final String initialEditColumn;
  final DataTableProject Function(
    String id,
    KDataTableSection<DataTableProject> section,
  )?
  createProject;
  final bool grouped;
  final bool showHeader;
  final bool singleColumn;
  @override
  State<DataTableFixture> createState() => _DataTableFixtureState();
}

class _DataTableFixtureState extends State<DataTableFixture> {
  final _query = TextEditingController();
  String _result = 'No action selected';
  int _nextId = 1;
  late final KDataTableDraftController<DataTableProject> _drafts;
  final _boundaries = <String, KDataTableDraftBoundary>{};
  String? _initialEditRow;
  final _returnFocus = <String, FocusNode?>{};
  List<DataTableProject> _rows = List.of(exampleProjects);
  String _status = 'all';
  KDataTableSort? _sort;
  Set<String> _collapsed = {};
  bool _failSave = false;
  bool _delaySave = false;
  @override
  void initState() {
    super.initState();
    _drafts = KDataTableDraftController<DataTableProject>(
      rowId: (row) => row.id,
      cloneRow: (row) => row,
      isEqual: (a, b) => a == b,
      savePolicy: widget.savePolicy,
      onCommit: (row, snapshot) async {
        if (_delaySave) {
          await Future<void>.delayed(const Duration(milliseconds: 1000));
        }
        if (_failSave) throw StateError('Example save failed');
        return widget.saveProject == null
            ? row
            : await widget.saveProject!(row);
      },
      onEvent: (event) {
        if (!mounted) return;
        setState(() {
          _result =
              '${event.type.name}: ${event.snapshot.id} (${event.reason})';
          if (event.type == KDataTableDraftEventType.committed) {
            _rows = [..._rows, event.acceptedRow!];
          }
          if (event.type == KDataTableDraftEventType.cancelled ||
              event.type == KDataTableDraftEventType.committed) {
            _boundaries.remove(event.snapshot.id)?.close();
            _returnFocus.remove(event.snapshot.id);
            if (_initialEditRow == event.snapshot.id) _initialEditRow = null;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _drafts.dispose();
    _query.dispose();
    super.dispose();
  }

  void _addProject(KDataTableSection<DataTableProject> section) {
    if (widget.singleColumn) {
      setState(
        () => _result =
            'Add project requested in ${section.path.map((group) => group.label).join(' / ')}',
      );
      return;
    }
    setState(() {
      final n = _nextId++;
      const title = '';
      String groupValue(String id, String fallback) {
        for (final group in section.path) {
          if (group.id == id) return group.value;
        }
        return fallback;
      }

      final row =
          widget.createProject?.call('new-$n', section) ??
          (
            id: 'new-$n',
            title: title,
            owner: 'You',
            budget: 0,
            status: groupValue(
              'status',
              _status == 'all' ? 'planned' : _status,
            ),
            platform: groupValue('platform', 'Web'),
          );
      _boundaries[row.id] = KDataTableDraftBoundary(
        controller: _drafts,
        rowId: row.id,
      );
      _returnFocus[row.id] = FocusManager.instance.primaryFocus;
      _initialEditRow = row.id;
      _drafts.begin(
        row,
        originPath: section.path,
        initialColumnId: widget.initialEditColumn,
      );
    });
  }

  void _finishTitle(DataTableProject row, String value, bool commit) {
    if (_drafts.get(row.id) == null) {
      if (commit) _setTitle(row, value);
      return;
    }
    if (commit) {
      _setTitle(row, value);
    } else {
      _drafts.cancel(row.id, reason: 'escape');
    }
    if (_initialEditRow == row.id) _initialEditRow = null;
  }

  Widget _draftCell(DataTableProject row, String columnId, Widget child) =>
      KDataTableDraftCellBoundary(
        boundary: _boundaries[row.id],
        autofocus:
            _initialEditRow == row.id && widget.initialEditColumn == columnId,
        child: CallbackShortcuts(
          bindings: _drafts.get(row.id) == null
              ? {}
              : {
                  const SingleActivator(LogicalKeyboardKey.escape): () =>
                      _drafts.cancel(row.id, reason: 'escape'),
                  const SingleActivator(LogicalKeyboardKey.enter): () =>
                      _drafts.commit(row.id, reason: 'enter'),
                },
          child: child,
        ),
      );

  Widget _projectCell(DataTableProject row) => _draftCell(
    row,
    'project',
    ProjectTitleCell(
      key: ValueKey('title-${row.id}'),
      id: row.id,
      title: row.title,
      enabled: _drafts.get(row.id)?.status != KDataTableDraftStatus.saving,
      onChanged: _drafts.get(row.id) == null
          ? null
          : (value) => _setTitle(row, value),
      onSubmitted: () => _drafts.commit(row.id, reason: 'enter'),
      startEditing:
          _initialEditRow == row.id && widget.initialEditColumn == 'project',
      onFinish: (value, commit) => _finishTitle(row, value, commit),
    ),
  );

  void _replace(DataTableProject row) {
    if (_drafts.get(row.id) != null) {
      _drafts.update(row.id, row);
      return;
    }
    setState(() {
      _rows = [
        for (final item in _rows)
          if (item.id == row.id) row else item,
      ];
    });
  }

  void _setTitle(DataTableProject row, String value) {
    final current =
        _drafts.get(row.id)?.current ?? _rows.firstWhere((r) => r.id == row.id);
    _replace((
      id: current.id,
      title: value,
      owner: current.owner,
      budget: current.budget,
      status: current.status,
      platform: current.platform,
    ));
  }

  void _setStatus(DataTableProject row, String value) {
    final current =
        _drafts.get(row.id)?.current ?? _rows.firstWhere((r) => r.id == row.id);
    _replace((
      id: current.id,
      title: current.title,
      owner: current.owner,
      budget: current.budget,
      status: value,
      platform: current.platform,
    ));
  }

  void _setBudget(DataTableProject row, int budget) {
    final current =
        _drafts.get(row.id)?.current ?? _rows.firstWhere((r) => r.id == row.id);
    _replace((
      id: current.id,
      title: current.title,
      owner: current.owner,
      budget: budget,
      status: current.status,
      platform: current.platform,
    ));
  }

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
            const KText('Project workspace', variant: KTextVariant.heading4),
            KDataTable<DataTableProject>(
              label: 'Project workspace',
              displayMode: widget.singleColumn
                  ? KDataTableDisplayMode.singleColumn
                  : KDataTableDisplayMode.multiColumn,
              singleColumn: KDataTableSingleColumn<DataTableProject>(
                columnLabel: 'Project',
                title: (row) => Text(
                  row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: (_) => const KIcon(KIconName.folder),
                trailing: (row) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KIcon(
                      row.status == 'done'
                          ? KIconName.check
                          : row.status == 'active'
                          ? KIconName.clock
                          : KIconName.minus,
                    ),
                    SizedBox(width: t.spaceControlGap),
                    Flexible(child: Text(projectStatusLabel(row.status))),
                  ],
                ),
                semanticsLabel: (row) => 'Open ${row.title}',
                onActivate: (row) =>
                    setState(() => _result = 'Open: ${row.title}'),
              ),
              rows: _rows,
              draftRows: _drafts.draftRows,
              rowId: (row) => row.id,
              columns: [
                KDataTableColumn(
                  id: 'icon',
                  label: 'Type',
                  width: 48,
                  paddingInline: 0,
                  align: KTableAlign.center,
                  cell: (row) => _draftCell(
                    row,
                    'icon',
                    KIconButton(
                      label: 'Open ${row.id}',
                      icon: KIconName.folder,
                      onPressed: () =>
                          setState(() => _result = 'Open: ${row.title}'),
                    ),
                  ),
                ),
                KDataTableColumn(
                  id: 'project',
                  label: 'Project',
                  headerContentInset: 4 + t.borderWidthDefault,
                  minWidth: 240,
                  flex: 2,
                  paddingInline: 0,
                  cell: _projectCell,
                  compare: (a, b) => a.title.compareTo(b.title),
                ),
                KDataTableColumn(
                  id: 'status',
                  label: 'Status',
                  headerContentInset:
                      t.spaceControlInsetInline + t.borderWidthDefault,
                  minWidth: 180,
                  cell: (row) => _draftCell(
                    row,
                    'status',
                    KSelect(
                      presentation: KSelectPresentation.inline,
                      label: 'Status for ${row.title}',
                      options: projectStatuses,
                      value: row.status,
                      onChanged:
                          _drafts.get(row.id)?.status ==
                              KDataTableDraftStatus.saving
                          ? null
                          : (value) {
                              if (value != null) _setStatus(row, value);
                            },
                    ),
                  ),
                ),
                KDataTableColumn(
                  id: 'budget',
                  label: 'Budget',
                  headerContentInset: 4 + t.borderWidthDefault,
                  width: 168,
                  align: KTableAlign.end,
                  cell: (row) => _draftCell(
                    row,
                    'budget',
                    BudgetCell(
                      id: row.id,
                      value: row.budget,
                      enabled:
                          _drafts.get(row.id)?.status !=
                          KDataTableDraftStatus.saving,
                      onCommit: (value) => _setBudget(row, value),
                    ),
                  ),
                  compare: (a, b) => a.budget.compareTo(b.budget),
                ),
              ],
              empty: Semantics(
                liveRegion: true,
                child: const KText('No matching projects'),
              ),
              sort: _sort,
              showHeader: widget.showHeader,
              onSortChanged: (sort) => setState(() => _sort = sort),
              footerBuilder: !widget.allowAdd
                  ? null
                  : (section) => Semantics(
                      label: section.path.isEmpty
                          ? widget.addLabel
                          : '${widget.addLabel} to ${section.path.map((group) => group.label).join(' / ')}',
                      button: true,
                      excludeSemantics: true,
                      onTap: () => _addProject(section),
                      child: KButton(
                        label: widget.addLabel,
                        variant: KButtonVariant.ghost,
                        fullWidth: true,
                        paddingInline: widget.singleColumn ? null : 0,
                        leading: widget.singleColumn
                            ? const KIcon(KIconName.plus)
                            : const SizedBox(
                                width: 48,
                                child: Center(child: KIcon(KIconName.plus)),
                              ),
                        onPressed: () => _addProject(section),
                      ),
                    ),

              filter: (row) =>
                  (_status == 'all' || row.status == _status) &&
                  '${row.title} ${row.owner}'.toLowerCase().contains(
                    _query.text.toLowerCase(),
                  ),
              groups: widget.grouped
                  ? [
                      KDataTableGroup(
                        id: 'status',
                        value: (row) => row.status,
                        label: projectStatusLabel,
                      ),
                      KDataTableGroup(
                        id: 'platform',
                        value: (row) => row.platform,
                      ),
                    ]
                  : [],
              collapsedGroups: _collapsed,
              onCollapsedGroupsChanged: (value) =>
                  setState(() => _collapsed = value),
              toolbar: KFilterBar(
                label: 'Project filters',
                resetLabel: 'Reset all',
                resetEnabled: _query.text.isNotEmpty || _status != 'all',
                onReset: () => setState(() {
                  _query.clear();
                  _status = 'all';
                }),
                children: [
                  SizedBox(
                    width: 240,
                    child: KSearchField(
                      label: 'Search projects',
                      placeholder: 'Search projects',
                      controller: _query,
                      onChanged: (_) => setState(() {}),
                      clearable: true,
                      clearLabel: 'Clear search',
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: KSelect(
                      label: 'Status filter',
                      value: _status,
                      options: const [
                        KSelectOption(value: 'all', label: 'All statuses'),
                        ...projectStatuses,
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _status = value);
                      },
                    ),
                  ),
                  DataTableSortMenu(
                    onChanged: (sort) => setState(() => _sort = sort),
                  ),
                ],
              ),
            ),
            DraftFixtureControls(
              controller: _drafts,
              boundaries: _boundaries,
              delay: _delaySave,
              fail: _failSave,
              onDelay: (v) => setState(() => _delaySave = v),
              onFail: (v) => setState(() => _failSave = v),
            ),
            Semantics(liveRegion: true, child: KText(_result)),
          ],
        ),
      ),
    );
  }
}
