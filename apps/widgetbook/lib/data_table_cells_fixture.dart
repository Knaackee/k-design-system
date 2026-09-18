import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const _kinds = [
  'text',
  'checkbox',
  'select',
  'combobox',
  'date',
  'time',
  'datetime',
  'currency',
  'readonly',
];
const _propertyLabels = <String, (String, KIconName)>{
  'text': ('Title', KIconName.fileText),
  'checkbox': ('Review', KIconName.circleCheck),
  'select': ('Status', KIconName.circleCheck),
  'combobox': ('Owner', KIconName.user),
  'date': ('Due date', KIconName.calendar),
  'time': ('Reminder', KIconName.clock),
  'datetime': ('Scheduled', KIconName.calendar),
  'currency': ('Budget', KIconName.info),
  'readonly': ('Source', KIconName.lock),
};

class DataTableCellsFixture extends StatefulWidget {
  const DataTableCellsFixture({super.key});
  @override
  State<DataTableCellsFixture> createState() => _DataTableCellsFixtureState();
}

class _DataTableCellsFixtureState extends State<DataTableCellsFixture> {
  final Map<String, Object?> _values = {
    'text': 'Atlas website',
    'checkbox': true,
    'select': 'active',
    'combobox': 'alex',
    'date': '2026-09-17',
    'time': '14:30',
    'datetime': '2026-09-17T12:30:00.000Z',
    'currency': 123456,
    'readonly': 'Consumer-owned content',
  };
  String? _editing;
  final _draft = TextEditingController();
  final _textFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    _textFocus.addListener(_blur);
  }

  void _blur() {
    if (!_textFocus.hasFocus && _editing == 'text') _commitText();
  }

  void _commitText() => setState(() {
    _values['text'] = _draft.text;
    _editing = null;
  });
  void _update(String kind, Object? value) =>
      setState(() => _values[kind] = value);
  void _edit(String kind) {
    setState(() {
      _editing = kind;
      if (kind == 'text') _draft.text = _values[kind] as String;
    });
    if (kind == 'text') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _textFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _textFocus.removeListener(_blur);
    _textFocus.dispose();
    _draft.dispose();
    super.dispose();
  }

  Widget _cell(String kind) {
    final label = 'Cell $kind';
    switch (kind) {
      case 'checkbox':
        return KCheckbox(
          label: 'Approved',
          value: _values[kind] as bool,
          onChanged: (value) => _update(kind, value),
        );
      case 'select':
        return KSelect(
          label: label,
          presentation: KSelectPresentation.inline,
          value: _values[kind] as String,
          onChanged: (value) => _update(kind, value),
          options: const [
            KSelectOption(
              value: 'planned',
              label: 'Planned',
              icon: KIconName.minus,
            ),
            KSelectOption(
              value: 'active',
              label: 'In progress',
              icon: KIconName.clock,
            ),
          ],
        );
      case 'combobox':
        return KCombobox(
          label: label,
          presentation: KSelectPresentation.inline,
          value: _values[kind] as String,
          options: const [
            KSelectOption(value: 'alex', label: 'Alex Morgan'),
            KSelectOption(value: 'sam', label: 'Sam Rivera'),
          ],
          onChanged: (value) => _update(kind, value),
        );
      case 'date':
        return KDatePicker(
          label: label,
          presentation: KPickerPresentation.inline,
          value: _values[kind] as String?,
          onChanged: (value) => _update(kind, value),
          dateFormat: KDateFormat.dayMonthYear,
          timeFormat: KTimeFormat.h24,
          timeZone: 'Europe/Berlin',
          now: DateTime.utc(2026, 9, 17, 10),
          clearable: true,
        );
      case 'time':
        return KTimePicker(
          label: label,
          presentation: KPickerPresentation.inline,
          value: _values[kind] as String?,
          onChanged: (value) => _update(kind, value),
          dateFormat: KDateFormat.dayMonthYear,
          timeFormat: KTimeFormat.h24,
          timeZone: 'Europe/Berlin',
          now: DateTime.utc(2026, 9, 17, 10),
          clearable: true,
        );
      case 'datetime':
        return KDateTimePicker(
          label: label,
          presentation: KPickerPresentation.inline,
          value: _values[kind] as String?,
          onChanged: (value) => _update(kind, value),
          dateFormat: KDateFormat.dayMonthYear,
          timeFormat: KTimeFormat.h24,
          timeZone: 'Europe/Berlin',
          now: DateTime.utc(2026, 9, 17, 10),
          clearable: true,
        );
      case 'currency':
        return KEditableCell(
          label: label,
          display: KText(
            formatCurrencyMinorUnits(
              _values[kind] as int?,
              currency: 'EUR',
              locale: 'de-DE',
            ),
          ),
          editing: _editing == kind,
          onEdit: () => _edit(kind),
          editor: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  setState(() => _editing = null),
            },
            child: KCurrencyInput(
              label: label,
              autofocus: true,
              value: _values[kind] as int?,
              currency: 'EUR',
              locale: 'de-DE',
              onCommit: (value) => setState(() {
                _values[kind] = value;
                _editing = null;
              }),
            ),
          ),
        );
      default:
        return KEditableCell(
          label: label,
          display: KText(_values[kind] as String),
          editing: _editing == kind,
          onEdit: kind == 'readonly' ? null : () => _edit(kind),
          editor: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  setState(() => _editing = null),
            },
            child: KInput(
              label: label,
              controller: _draft,
              focusNode: _textFocus,
              autofocus: true,
              onSubmitted: (_) => _commitText(),
            ),
          ),
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
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            const KText('Properties', variant: KTextVariant.heading4),
            KDataTable<String>(
              label: 'Document properties',
              rows: _kinds,
              rowId: (value) => value,
              empty: const KText('No cells'),
              columns: [
                KDataTableColumn<String>(
                  id: 'kind',
                  label: 'Type',
                  width: 140,
                  cell: (kind) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KIcon(_propertyLabels[kind]!.$2, color: t.colorTextMuted),
                      SizedBox(width: t.spaceControlGap),
                      Flexible(
                        child: KText(
                          _propertyLabels[kind]!.$1,
                          style: TextStyle(color: t.colorTextMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                KDataTableColumn<String>(
                  id: 'value',
                  label: 'Value',
                  minWidth: 300,
                  paddingInline: 0,
                  cell: _cell,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
