import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const _statuses = [
  KSelectOption(value: 'active', label: 'Active', icon: KIconName.circleCheck),
  KSelectOption(value: 'planned', label: 'Planned', icon: KIconName.clock),
  KSelectOption(
    value: 'closed',
    label: 'Closed',
    icon: KIconName.lock,
    disabled: true,
  ),
];

class MultiSelectFixture extends StatefulWidget {
  const MultiSelectFixture({super.key});
  @override
  State<MultiSelectFixture> createState() => _MultiSelectFixtureState();
}

class _MultiSelectFixtureState extends State<MultiSelectFixture> {
  List<String> teams = [], projects = [], people = [];
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.symmetric(
      vertical: Theme.of(context).extension<KDesignTokens>()!.spaceLayoutGutter,
    ),
    child: KContainer(
      child: KStack(
        gap: KLayoutGap.section,
        align: KLayoutAlign.stretch,
        children: [
          const KText('Workspace filters', variant: KTextVariant.heading4),
          KField(
            label: 'Teams',
            child: KSelect(
              multiple: true,
              clearable: true,
              label: 'Teams',
              placeholder: 'All teams and private projects',
              values: teams,
              onValuesChanged: (values) => setState(() => teams = values),
              selectionLabel: teams.length > 1 ? '${teams.length} areas' : null,
              options: const [
                KSelectOption(
                  value: 'private',
                  label: 'Private workspace projects',
                  icon: KIconName.lock,
                ),
                KSelectOption(
                  value: 'design',
                  label: 'Design',
                  icon: KIconName.palette,
                ),
                KSelectOption(
                  value: 'engineering',
                  label: 'Engineering',
                  icon: KIconName.code,
                ),
              ],
            ),
          ),
          KField(
            label: 'Projects',
            child: KSelect(
              multiple: true,
              clearable: true,
              label: 'Projects',
              placeholder: 'All projects',
              values: projects,
              onValuesChanged: (values) => setState(() => projects = values),
              selectionLabel: projects.length > 1
                  ? '${projects.length} projects'
                  : null,
              options: const [
                KSelectOption(
                  value: 'orbit',
                  label: 'Orbit',
                  leading: KIcon(KIconName.rocket, color: Color(0xFFE76F51)),
                ),
                KSelectOption(
                  value: 'tasks',
                  label: 'Tasks',
                  leading: KIcon(KIconName.code, color: Color(0xFF2A9D8F)),
                ),
              ],
            ),
          ),
          KField(
            label: 'People',
            child: KCombobox(
              multiple: true,
              clearable: true,
              label: 'People',
              placeholder: 'All people',
              values: people,
              onValuesChanged: (values) => setState(() => people = values),
              selectionLabel: people.length > 1
                  ? '${people.length} people'
                  : null,
              options: _people,
            ),
          ),
        ],
      ),
    ),
  );
}

const _people = [
  KSelectOption(
    value: 'alex',
    label: 'Alex',
    imageSrc: '/avatars/alex.png',
    icon: KIconName.user,
  ),
  KSelectOption(
    value: 'jordan',
    label: 'Jordan',
    imageSrc: '/avatars/jordan.png',
    icon: KIconName.user,
  ),
  KSelectOption(
    value: 'sam',
    label: 'Sam',
    icon: KIconName.user,
    disabled: true,
  ),
];

class FormFixture extends StatefulWidget {
  const FormFixture({this.kind = 'filter-bar', super.key});
  final String kind;
  @override
  State<FormFixture> createState() => _FormFixtureState();
}

class _FormFixtureState extends State<FormFixture> {
  final _query = TextEditingController();
  final _readOnly = TextEditingController(text: 'Workspace overview');
  final _disabled = TextEditingController(text: 'Unavailable item');
  String? _status = 'active';
  String? _person = 'alex';
  bool _archived = false;
  bool? _mixed;

  @override
  void dispose() {
    _query.dispose();
    _readOnly.dispose();
    _disabled.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _query.clear();
    _status = null;
    _person = null;
    _archived = false;
  });

  List<Widget> _chips() => [
    if (_status != null)
      KFilterChip(
        label:
            'Status: ${_statuses.firstWhere((o) => o.value == _status).label}',
        onRemove: () => setState(() => _status = null),
      ),
    if (_person != null)
      KFilterChip(
        label:
            'Assignee: ${_people.firstWhere((o) => o.value == _person).label}',
        onRemove: () => setState(() => _person = null),
      ),
    if (_query.text.isEmpty && _status == null && _person == null && !_archived)
      const KText('No active filters'),
  ];

  Widget _input({
    TextEditingController? controller,
    String? placeholder,
    bool enabled = true,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) => widget.kind == 'search-field'
      ? KSearchField(
          controller: controller,
          placeholder: placeholder,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
          clearable: true,
          clearLabel: 'Clear search',
        )
      : KInput(
          controller: controller,
          placeholder: placeholder,
          enabled: enabled,
          readOnly: readOnly,
          onChanged: onChanged,
        );

  Widget _selection({
    required String? value,
    ValueChanged<String?>? onChanged,
    String placeholder = 'Choose…',
  }) => widget.kind == 'select'
      ? KSelect(
          options: onChanged == null
              ? [
                  for (final option in _people)
                    KSelectOption(
                      value: option.value,
                      label: option.label,
                      disabled: option.disabled,
                    ),
                ]
              : _people,
          clearable: true,
          clearLabel: 'Clear assignee',
          value: value,
          onChanged: onChanged,
          placeholder: placeholder,
        )
      : KCombobox(
          options: onChanged == null
              ? [
                  for (final option in _people)
                    KSelectOption(
                      value: option.value,
                      label: option.label,
                      disabled: option.disabled,
                    ),
                ]
              : _people,
          clearable: true,
          clearLabel: 'Clear assignee',
          value: value,
          onChanged: onChanged,
          placeholder: placeholder,
        );

  Widget _content() {
    switch (widget.kind) {
      case 'filter-bar':
        return KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.action,
          children: [
            KField(
              label: 'Search items',
              child: KSearchField(
                controller: _query,
                placeholder: 'Search items',
                clearable: true,
                clearLabel: 'Clear search',
                onChanged: (_) => setState(() {}),
              ),
            ),
            KField(
              label: 'Status',
              child: KSelect(
                options: _statuses,
                clearable: true,
                clearLabel: 'Clear status',
                value: _status,
                onChanged: (value) => setState(() => _status = value),
                placeholder: 'Choose status',
              ),
            ),
            KField(
              label: 'Assignee',
              child: KCombobox(
                options: _people,
                clearable: true,
                clearLabel: 'Clear assignee',
                value: _person,
                onChanged: (value) => setState(() => _person = value),
                placeholder: 'Find a person',
              ),
            ),
            KCheckbox(
              label: 'Include archived',
              value: _archived,
              onChanged: (value) => setState(() => _archived = value ?? false),
            ),
            KFilterBar(
              label: 'Workspace filters',
              onReset: _reset,
              resetLabel: 'Reset all',
              resetEnabled:
                  _query.text.isNotEmpty ||
                  _status != null ||
                  _person != null ||
                  _archived,
              children: _chips(),
            ),
          ],
        );
      case 'checkbox':
        return KStack(
          gap: KLayoutGap.action,
          children: [
            KCheckbox(
              label: 'Include archived',
              value: _archived,
              onChanged: (value) => setState(() => _archived = value ?? false),
            ),
            KCheckbox(
              label: 'Select group',
              value: _mixed,
              onChanged: (value) => setState(() => _mixed = value),
            ),
            const KCheckbox(
              label: 'Unavailable',
              value: false,
              onChanged: null,
            ),
          ],
        );
      case 'select':
      case 'combobox':
        return KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            if (widget.kind == 'select')
              KSelect(
                expandedPopup: true,
                label: 'Conversation',
                value: 'conversation',
                onChanged: (_) {},
                options: const [
                  KSelectOption(
                    value: 'conversation',
                    label:
                        'A long conversation about open tasks and recent changes',
                    description: '21.10.2026, 17:30',
                  ),
                ],
              ),

            KField(
              label: 'Assignee',
              helperText: 'Sam is unavailable.',
              child: _selection(
                value: _person,
                onChanged: (value) => setState(() => _person = value),
                placeholder: 'Find a person',
              ),
            ),
            KField(
              label: 'Unavailable',
              child: _selection(value: 'alex'),
            ),
          ],
        );
      case 'filter-chip':
        return KInline(wrap: true, children: _chips());
      default:
        return KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            KField(
              label: 'Title',
              helperText: 'Use a clear, descriptive name.',
              required: true,
              child: _input(
                controller: _query,
                placeholder: 'New item',
                onChanged: (_) => setState(() {}),
              ),
            ),
            KField(
              label: 'Required name',
              errorText: 'Enter an item name.',
              child: _input(placeholder: 'New item'),
            ),
            KField(
              label: 'Read only',
              child: _input(controller: _readOnly, readOnly: true),
            ),
            KField(
              label: 'Unavailable',
              child: _input(controller: _disabled, enabled: false),
            ),
          ],
        );
    }
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
            const KText('Workspace filters', variant: KTextVariant.heading4),
            _content(),
            Semantics(
              liveRegion: true,
              child: KText(
                'Query: ${_query.text.isEmpty ? 'All items' : _query.text} · Status: ${_status ?? 'Any'} · Assignee: ${_person ?? 'Anyone'} · Archived: ${_archived ? 'Yes' : 'No'}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
