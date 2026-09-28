import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class GanttFixture extends StatefulWidget {
  const GanttFixture({super.key});
  @override
  State<GanttFixture> createState() => _GanttFixtureState();
}

class _GanttFixtureState extends State<GanttFixture> {
  List<GanttTask>? _tasks;
  List<GanttLink> _links = [];
  DateTime _start = DateTime(2026, 9, 21), _end = DateTime(2026, 10, 17);
  String? _selected, _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          jsonDecode(
                await rootBundle.loadString('fixtures/gantt-reference.json'),
              )
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _tasks = (data['tasks'] as List)
            .map((e) => GanttTask.fromJson(e as Map<String, dynamic>))
            .toList();
        _links = (data['links'] as List)
            .map((e) => GanttLink.fromJson(e as Map<String, dynamic>))
            .toList();
        _start = DateTime.parse(data['window']['start'] as String);
        _end = DateTime.parse(data['window']['end'] as String);
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Fixture unavailable: $error');
    }
  }

  bool _propose(GanttTask next) {
    final result = applyGanttProposal(_tasks!, next);
    if (identical(result, _tasks)) return false;
    setState(() {
      _tasks = result;
      _selected = next.id;
    });
    return true;
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  Future<void> _details(String id) async {
    final entry = summarizeGanttTasks(_tasks!).firstWhere((e) => e.id == id);
    var draft = entry;
    final locked = entry.readOnly || entry.type == 'summary';
    String? error;
    final progress = TextEditingController(text: '${entry.progress.round()}');
    await KDialog.show<void>(
      context: context,
      title: KText(entry.text),
      child: StatefulBuilder(
        builder: (context, update) {
          final t = Theme.of(context).extension<KDesignTokens>()!;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KDatePicker(
                  label: 'Start date',
                  value: _date(draft.start),
                  enabled: !locked,
                  allowTextInput: true,
                  onChanged: (v) {
                    if (v != null) {
                      update(
                        () => draft = draft.copyWith(start: DateTime.parse(v)),
                      );
                    }
                  },
                ),
                SizedBox(height: t.spaceControlGap),
                if (draft.end != null) ...[
                  KDatePicker(
                    label: 'Last day included',
                    value: _date(ganttAddDays(draft.end!, -1)),
                    min: _date(draft.start),
                    enabled: !locked,
                    allowTextInput: true,
                    onChanged: (v) {
                      if (v != null) {
                        update(
                          () => draft = draft.copyWith(
                            end: ganttAddDays(DateTime.parse(v), 1),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: t.spaceControlGap),
                ],
                KInput(
                  label: 'Progress (%)',
                  controller: progress,
                  enabled: !locked,
                ),
                if (entry.type == 'summary')
                  const KText(
                    'Summary dates and progress follow the child tasks.',
                    variant: KTextVariant.caption,
                  ),
                if (error != null)
                  KText(error!, variant: KTextVariant.bodySmall),
                SizedBox(height: t.spaceControlGap),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: t.spaceControlGap,
                  children: [
                    KButton(
                      label: 'Close',
                      variant: KButtonVariant.ghost,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    KButton(
                      label: 'Save changes',
                      onPressed: locked
                          ? null
                          : () {
                              final value = double.tryParse(progress.text);
                              if (value != null &&
                                  _propose(draft.copyWith(progress: value))) {
                                Navigator.of(context).pop();
                              } else {
                                update(
                                  () => error =
                                      'Check dates and progress (0–100).',
                                );
                              }
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    progress.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    if (_tasks == null) return KText(_error ?? 'Loading timeline…');
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(t.spaceLayoutGutter),
        child: KSurface(
          radius: KSurfaceRadius.card,
          child: KGantt(
            tasks: _tasks!,
            links: _links,
            start: _start,
            end: _end,
            selectedId: _selected,
            onSelect: (id) => setState(() => _selected = id),
            onOpen: _details,
            onPropose: _propose,
          ),
        ),
      ),
    );
  }
}
