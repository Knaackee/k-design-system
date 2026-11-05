import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class TimelineFixture extends StatefulWidget {
  const TimelineFixture({super.key});
  @override
  State<TimelineFixture> createState() => _TimelineFixtureState();
}

class _TimelineFixtureState extends State<TimelineFixture> {
  List<TimelineEntry>? _items;
  List<TimelineEntry> _initial = [];
  List<TimelineGroup> _groups = [];
  DateTime _start = DateTime(2026, 9, 21), _end = DateTime(2026, 10, 12);
  final _today = DateTime(2026, 9, 25);
  String? _selected;
  String _title = 'Release roadmap';
  String _message = 'Select an item to inspect or edit its dates.';
  int _zoom = 21;
  bool _reject = false, _checks = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          jsonDecode(
                await rootBundle.loadString('fixtures/timeline-reference.json'),
              )
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _title = data['title'] as String;
        _groups = (data['groups'] as List)
            .map((e) => TimelineGroup.fromJson(e as Map<String, dynamic>))
            .toList();
        _initial = (data['items'] as List)
            .map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _items = _initial;
      });
    } catch (_) {
      if (mounted) setState(() => _message = 'Fixture unavailable');
    }
  }

  String _date(DateTime d) =>
      '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.day}';
  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  bool _propose(TimelineEntry next) {
    final result = applyTimelineProposal(
      _items!,
      next,
      _groups,
      accept: !_reject,
    );
    final accepted = !identical(result, _items);
    setState(() {
      if (accepted) {
        _items = result;
        _selected = next.id;
      }
      _message = accepted
          ? '${next.label}: ${_date(next.start)}${next.end == null ? '' : ' – ${_date(addTimelineDays(next.end!, -1))}'}. Change saved in this demo.'
          : 'Change declined. Original dates retained.';
    });
    return accepted;
  }

  void _details(String id) {
    final entry = _items!.firstWhere((e) => e.id == id);
    setState(() => _selected = id);
    var draft = entry;
    String? error;
    KDialog.show<void>(
      context: context,
      title: KText(entry.label),
      child: StatefulBuilder(
        builder: (context, update) {
          final t = Theme.of(context).extension<KDesignTokens>()!;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const KText('Start date', variant: KTextVariant.bodySmall),
              SizedBox(height: t.spaceControlGap),
              KDatePicker(
                label: 'Start date',
                value: _key(draft.start),
                enabled: !entry.readOnly,
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
                const KText(
                  'Last day included',
                  variant: KTextVariant.bodySmall,
                ),
                SizedBox(height: t.spaceControlGap),
                KDatePicker(
                  label: 'Last day included',
                  value: _key(addTimelineDays(draft.end!, -1)),
                  min: _key(draft.start),
                  enabled: !entry.readOnly,
                  allowTextInput: true,
                  onChanged: (v) {
                    if (v != null) {
                      update(
                        () => draft = draft.copyWith(
                          end: addTimelineDays(DateTime.parse(v), 1),
                        ),
                      );
                    }
                  },
                ),
              ],
              SizedBox(height: t.spaceControlGap),
              const KText('Group', variant: KTextVariant.bodySmall),
              SizedBox(height: t.spaceControlGap),
              KSelect(
                label: 'Group',
                value: draft.group,
                options: [
                  for (final g in _groups)
                    KSelectOption(value: g.id, label: g.label),
                ],
                onChanged: entry.readOnly
                    ? null
                    : (v) {
                        if (v != null) {
                          update(() => draft = draft.copyWith(group: v));
                        }
                      },
              ),
              if (error != null) KText(error!, variant: KTextVariant.caption),
              SizedBox(height: t.spaceControlGap),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: t.spaceControlGap,
                children: [
                  KButton(
                    label: 'Cancel',
                    variant: KButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  KButton(
                    label: 'Save changes',
                    onPressed: entry.readOnly
                        ? null
                        : () {
                            if (_propose(draft)) {
                              Navigator.of(context).pop();
                            } else {
                              update(
                                () => error =
                                    'Change declined. Check dates and demo settings.',
                              );
                            }
                          },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final items = _items;
    if (items == null) {
      return KText(
        _message == 'Fixture unavailable' ? _message : 'Loading timeline…',
      );
    }
    final selected = items.where((e) => e.id == _selected).firstOrNull;
    Widget section(List<Widget> children) => Padding(
      padding: EdgeInsets.all(t.spaceCardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(t.spaceLayoutGutter),
        child: KSurface(
          radius: KSurfaceRadius.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              section([
                KText(_title, variant: KTextVariant.heading3),
                SizedBox(height: t.spaceControlGap),
                KText(
                  'Design, build and launch · September–October 2026',
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(color: t.colorTextMuted),
                ),
                SizedBox(height: t.spaceControlGap),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: t.spaceControlGap,
                  runSpacing: t.spaceControlGap,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KIconButton(
                          label: 'Previous period',
                          icon: KIconName.chevronLeft,
                          onPressed: () => setState(() {
                            _start = addTimelineDays(_start, -_zoom);
                            _end = addTimelineDays(_end, -_zoom);
                          }),
                        ),
                        KButton(
                          label: 'Today',
                          variant: KButtonVariant.ghost,
                          onPressed: () => setState(() {
                            _start = addTimelineDays(_today, -3);
                            _end = addTimelineDays(_start, _zoom);
                          }),
                        ),
                        KIconButton(
                          label: 'Next period',
                          icon: KIconName.chevronRight,
                          onPressed: () => setState(() {
                            _start = addTimelineDays(_start, _zoom);
                            _end = addTimelineDays(_end, _zoom);
                          }),
                        ),
                      ],
                    ),
                    Wrap(
                      children: [
                        for (final entry in {
                          'Days': 7,
                          'Weeks': 21,
                          'Months': 60,
                        }.entries)
                          KButton(
                            label: entry.key,
                            variant: _zoom == entry.value
                                ? KButtonVariant.secondary
                                : KButtonVariant.ghost,
                            onPressed: () => setState(() {
                              _zoom = entry.value;
                              _end = addTimelineDays(_start, _zoom);
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: t.spaceControlGap),
                KText(
                  '${_date(_start)} – ${_date(addTimelineDays(_end, -1))}',
                  variant: KTextVariant.caption,
                  style: TextStyle(color: t.colorTextMuted),
                ),
              ]),
              KTimeline(
                items: items,
                groups: _groups,
                selectedId: _selected,
                windowStart: _start,
                windowEnd: _end,
                today: _today,
                onSelect: (id) => setState(() => _selected = id),
                onItemOpen: _details,
                onPropose: _propose,
                onWindowChange: (start, end) => setState(() {
                  _start = start;
                  _end = end;
                }),
              ),
              section([
                // Wraps the action under the label at large text.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: t.spaceControlGap,
                  children: [
                    KText(
                      selected?.label ?? '12 items · 3 groups',
                      variant: KTextVariant.bodySmall,
                    ),
                    KButton(
                      label: 'View details',
                      variant: KButtonVariant.ghost,
                      onPressed: selected == null
                          ? null
                          : () => _details(selected.id),
                    ),
                  ],
                ),
                SizedBox(height: t.spaceControlGap),
                KText(
                  'Drag the timeline to explore. Tap for details or hold a bar to move or resize it. Escape cancels.',
                  variant: KTextVariant.caption,
                  style: TextStyle(color: t.colorTextMuted),
                ),
                KButton(
                  label:
                      '${_checks ? '▾' : '▸'} Selection & interaction checks',
                  variant: KButtonVariant.ghost,
                  onPressed: () => setState(() => _checks = !_checks),
                ),
                if (_checks) ...[
                  KSelect(
                    label: 'Select an item',
                    value: _selected,
                    options: [
                      for (final e in items)
                        KSelectOption(value: e.id, label: e.label),
                    ],
                    onChanged: (id) => setState(() => _selected = id),
                  ),
                  KCheckbox(
                    label: 'Decline changes in this demo',
                    value: _reject,
                    onChanged: (v) => setState(() => _reject = v ?? false),
                  ),
                  KButton(
                    label: 'Reset demo data',
                    variant: KButtonVariant.ghost,
                    onPressed: () => setState(() {
                      _items = _initial;
                      _selected = null;
                      _message = 'Select an item to inspect or edit its dates.';
                    }),
                  ),
                ],
                Semantics(
                  liveRegion: true,
                  child: KText(
                    _message,
                    variant: KTextVariant.caption,
                    style: TextStyle(color: t.colorTextMuted),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
