import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

typedef _Item = ({String id, String title, String team});
final _seed = List.generate(
  240,
  (i) => (
    id: 'row-$i',
    title: 'Project ${i + 1}',
    team: i < 120 ? 'Web' : 'Mobile',
  ),
);

class DataTableVirtualFixture extends StatefulWidget {
  const DataTableVirtualFixture({this.external = false, super.key});
  final bool external;
  @override
  State<DataTableVirtualFixture> createState() => _VirtualState();
}

class _VirtualState extends State<DataTableVirtualFixture> {
  List<_Item> _rows = List.of(_seed);
  KDataTableCellIdentity? _active, _focusCell;
  final _draft = TextEditingController();
  final _editorFocus = FocusNode();
  Set<String> _collapsed = {};
  String _message = '', _revision = 'query-1';
  bool _hold = false, _error = false;
  KDataTableRange? _pending;
  KDataTableWindow<_Item> _window = KDataTableWindow(
    queryRevision: 'query-1',
    totalCount: 240,
    startIndex: 0,
    entries: [],
  );
  @override
  void initState() {
    super.initState();
    _editorFocus.addListener(_blur);
  }

  void _blur() {
    if (!_editorFocus.hasFocus && _active != null) _commit();
  }

  @override
  void dispose() {
    _editorFocus.removeListener(_blur);
    _editorFocus.dispose();
    _draft.dispose();
    super.dispose();
  }

  void _load(KDataTableRange range) {
    setState(
      () => _window = KDataTableWindow(
        queryRevision: range.queryRevision,
        totalCount: 240,
        startIndex: range.startIndex,
        entries: [
          for (final row in _seed.sublist(
            range.startIndex,
            range.endIndex.clamp(0, 240),
          ))
            KDataTableEntry.item(id: 'item:${row.id}', row: row),
        ],
      ),
    );
  }

  void _request(KDataTableRange range) {
    _pending = range;
    if (!_hold) _load(range);
  }

  bool _commit() {
    final active = _active;
    if (active == null) return true;
    if (_draft.text.trim().isEmpty) {
      setState(() => _message = 'Title is required');
      return false;
    }
    setState(() {
      _rows = [
        for (final r in _rows)
          if (r.id == active.rowId)
            (id: r.id, title: _draft.text, team: r.team)
          else
            r,
      ];
      _message = 'Saved ${_draft.text}';
      _active = null;
    });
    return true;
  }

  Widget _title(_Item row) => KEditableCell(
    label: 'Edit ${row.id}',
    display: Text(row.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    editing: _active?.rowId == row.id,
    onEdit: () {
      setState(() {
        _active = KDataTableCellIdentity(rowId: row.id, columnId: 'title');
        _draft.text = row.title;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editorFocus.requestFocus();
      });
    },
    editor: Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          setState(() {
            _active = null;
            _message = 'Cancelled';
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: KInput(
        label: 'Title ${row.id}',
        controller: _draft,
        focusNode: _editorFocus,
        autofocus: true,
        onSubmitted: (_) => _commit(),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final external = widget.external;
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLayoutGutter),
      child: KStack(
        align: KLayoutAlign.stretch,
        gap: KLayoutGap.section,
        children: [
          KInline(
            gap: KLayoutGap.control,
            wrap: true,
            children: [
              if (!external)
                KButton(
                  label: 'Focus project 201',
                  onPressed: () => setState(
                    () => _focusCell = const KDataTableCellIdentity(
                      rowId: 'row-200',
                      columnId: 'title',
                    ),
                  ),
                ),
              if (external) ...[
                KButton(
                  label: 'Change query',
                  onPressed: () => setState(() {
                    _hold = true;
                    _revision = _revision == 'query-1' ? 'query-2' : 'query-1';
                  }),
                ),
                KButton(
                  label: 'Load requested range',
                  onPressed: () {
                    if (_pending != null) _load(_pending!);
                    setState(() {
                      _hold = false;
                      _error = false;
                    });
                  },
                ),
                KButton(
                  label: 'Deliver stale response',
                  onPressed: () => setState(
                    () => _window = KDataTableWindow(
                      queryRevision: 'obsolete',
                      totalCount: 1,
                      startIndex: 0,
                      entries: [
                        KDataTableEntry.item(
                          id: 'stale',
                          row: (
                            id: 'stale',
                            title: 'STALE RESULT',
                            team: 'Old',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                KButton(
                  label: 'Simulate error',
                  onPressed: () => setState(() => _error = true),
                ),
              ],
            ],
          ),
          KDataTable<_Item>(
            label: external ? 'External projects' : 'Virtual projects',
            rows: external ? [] : _rows,
            rowId: (r) => r.id,
            empty: const Text('No projects'),
            columns: [
              KDataTableColumn(
                id: 'title',
                label: 'Project',
                minWidth: 240,
                cell: external ? (r) => Text(r.title) : _title,
              ),
              KDataTableColumn(
                id: 'team',
                label: 'Team',
                width: 160,
                cell: (r) => Text(r.team),
              ),
              if (!external)
                for (var i = 0; i < 8; i++)
                  KDataTableColumn(
                    id: 'detail-$i',
                    label: 'Detail ${i + 1}',
                    width: 120,
                    cell: (r) => Text('${r.id} / ${i + 1}'),
                  ),
            ],
            viewport: const KDataTableViewport(height: 320, overscan: 2),
            groups: external
                ? []
                : [KDataTableGroup(id: 'team', value: (r) => r.team)],
            collapsedGroups: _collapsed,
            onCollapsedGroupsChanged: (keys) =>
                setState(() => _collapsed = keys),
            footerBuilder: external
                ? null
                : (section) => KButton(
                    label: 'Add project to ${section.path.last.label}',
                    variant: KButtonVariant.ghost,
                    onPressed: () => setState(
                      () => _message = 'Add to ${section.path.last.label}',
                    ),
                  ),
            activeCell: _active,
            onBeforeActiveCellExit: _commit,
            focusCell: _focusCell,
            externalWindow: external ? _window : null,
            queryRevision: external ? _revision : null,
            onRangeRequest: external ? _request : null,
            loading: const Text('Loading projects'),
            error: _error ? const Text('Could not load projects') : null,
          ),
          Semantics(
            liveRegion: true,
            child: Text(
              _message.isNotEmpty
                  ? _message
                  : external
                  ? 'Query $_revision'
                  : '240 projects; drafts stay outside cells',
            ),
          ),
        ],
      ),
    );
  }
}
