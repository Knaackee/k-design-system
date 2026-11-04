import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:timezone/timezone.dart' as tz;
import 'calendar_fixture_data.dart';

class CalendarFixture extends StatefulWidget {
  const CalendarFixture({this.initialView = KCalendarView.week, super.key});
  final KCalendarView initialView;
  @override
  State<CalendarFixture> createState() => _CalendarFixtureState();
}

class _CalendarFixtureState extends State<CalendarFixture> {
  DateTime _date = DateTime.utc(2026, 9, 21);
  late KCalendarView _view = widget.initialView;
  List<CalendarDemoEvent> _events = calendarDemoEvents();
  String? _project, _scheduling;
  bool _unplanned = false;
  final String _message = '';
  int _next = 200;
  bool get german => KLocalization.of(context).locale.startsWith('de');
  String label(String en, String de) => german ? de : en;
  List<CalendarDemoEvent> get visible =>
      _events.where((e) => _project == null || e.project == _project).toList();
  void replace(CalendarDemoEvent event) => setState(
    () => _events = [
      for (final e in _events)
        if (e.id == event.id) event else e,
    ],
  );
  void navigate(int direction) {
    setState(() {
      if (_view == KCalendarView.month) {
        final month = DateTime.utc(_date.year, _date.month + direction);
        final last = DateTime.utc(month.year, month.month + 1, 0).day;
        _date = DateTime.utc(
          month.year,
          month.month,
          _date.day > last ? last : _date.day,
        );
      } else {
        _date = _date.add(
          Duration(
            days:
                direction *
                (_view == KCalendarView.week
                    ? 7
                    : _view == KCalendarView.threeDay
                    ? 3
                    : 1),
          ),
        );
      }
    });
  }

  void move(KCalendarMove<CalendarDemoEvent> change) {
    final start = kCalendarSlotToDate(change.target);
    replace(
      change.event.copyWith(
        start: start,
        end: start.add(
          Duration(
            minutes: change.target.allDay && change.durationMinutes < 1440
                ? 1440
                : change.durationMinutes,
          ),
        ),
        allDay: change.target.allDay,
      ),
    );
  }

  void resize(KCalendarResize<CalendarDemoEvent> change) => replace(
    change.event.copyWith(
      start: kCalendarSlotToDate(change.start),
      end: kCalendarSlotToDate(change.end),
    ),
  );
  Future<void> edit(
    bool compact, {
    CalendarDemoEvent? event,
    KCalendarSelection? selection,
  }) async {
    if (_scheduling != null && selection != null) {
      final item = _events.firstWhere((e) => e.id == _scheduling);
      replace(
        item.copyWith(
          start: kCalendarSlotToDate(selection.start),
          end: kCalendarSlotToDate(selection.end),
          allDay: selection.start.allDay,
        ),
      );
      setState(() => _scheduling = null);
      return;
    }
    final controller = TextEditingController(text: event?.title ?? '');
    final title = Text(label('Create issue', 'Issue erstellen'));
    final range = selection ?? eventSelection(event);
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KInput(
          controller: controller,
          autofocus: true,
          label: label('Title', 'Titel'),
        ),
        if (range != null) ...[
          const SizedBox(height: 12),
          Text(selectionDescription(range)),
        ],
      ],
    );
    if (selection != null) {
      setState(
        () => _events = [
          ..._events.where((e) => e.id != 'CAL-DRAFT'),
          CalendarDemoEvent(
            id: 'CAL-DRAFT',
            title: label('New event', 'Neuer Termin'),
            project: _project ?? 'Orbit',
            start: kCalendarSlotToDate(selection.start),
            end: kCalendarSlotToDate(selection.end),
            allDay: selection.start.allDay,
          ),
        ],
      );
    }
    final actions = Builder(
      builder: (routeContext) => KButton(
        label: label('Save', 'Speichern'),
        onPressed: () {
          if (controller.text.trim().isEmpty) return;
          if (event != null) {
            replace(event.copyWith(title: controller.text.trim()));
          } else if (selection != null) {
            setState(() {
              _events = [
                for (final e in _events)
                  if (e.id != 'CAL-DRAFT') e,
                CalendarDemoEvent(
                  id: 'CAL-${_next++}',
                  title: controller.text.trim(),
                  project: _project ?? 'Orbit',
                  start: kCalendarSlotToDate(selection.start),
                  end: kCalendarSlotToDate(selection.end),
                  allDay: selection.start.allDay,
                ),
              ];
            });
          }
          Navigator.of(routeContext).pop();
        },
      ),
    );
    if (compact) {
      await KBottomSheet.show<void>(
        context: context,
        title: title,
        child: child,
        actions: actions,
      );
    } else {
      await KDialog.show<void>(
        context: context,
        title: title,
        child: child,
        actions: actions,
      );
    }
    // Route transitions may still read the controller after the pop future.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  KCalendarSelection? eventSelection(CalendarDemoEvent? event) {
    if (event == null || event.start == null || event.end == null) return null;
    KCalendarSlot slot(DateTime instant) {
      final date = event.allDay
          ? instant.toUtc()
          : tz.TZDateTime.from(instant, tz.getLocation('Europe/Berlin'));
      return KCalendarSlot(
        date:
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        minutes: date.hour * 60 + date.minute,
        allDay: event.allDay,
        timeZone: 'Europe/Berlin',
      );
    }

    return KCalendarSelection(start: slot(event.start!), end: slot(event.end!));
  }

  String selectionDescription(KCalendarSelection selection) {
    final l = MaterialLocalizations.of(context);
    final allDay = selection.start.allDay;
    final start = DateTime.parse(selection.start.date);
    final end = DateTime.parse(
      selection.end.date,
    ).subtract(Duration(days: allDay ? 1 : 0));
    String format(DateTime date, int minutes) {
      final day = l.formatMediumDate(date);
      if (allDay) return day;
      final time = l.formatTimeOfDay(
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      return '$day, $time';
    }

    final first = format(start, selection.start.minutes);
    final last = format(end, selection.end.minutes);
    final range = first == last ? first : '$first – $last';
    return allDay ? '$range · ${label('All day', 'Ganztägig')}' : range;
  }

  Widget unplannedContent({bool sheet = false}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final event in visible.where((e) => e.start == null))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title),
              const SizedBox(height: 8),
              KButton(
                label: label('Schedule', 'Einplanen'),
                variant: KButtonVariant.secondary,
                onPressed: () {
                  setState(() => _scheduling = event.id);
                  if (sheet) Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ],
          ),
        ),
      if (!visible.any((e) => e.start == null))
        Text(label('All issues are scheduled', 'Alle Issues sind eingeplant')),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final pack = KLocalization.of(context).calendar();
    final months = pack['months'] as List;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Widgetbook's viewport addon renders the canvas inside a larger host
        // constraint; use its compact gallery fixture to exercise portrait
        // scrolling and tap-to-create semantics deterministically.
        final compact =
            constraints.maxWidth < 900 ||
            constraints.maxWidth < MediaQuery.sizeOf(context).height;
        final availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final calendarHeight = compact
            ? 420.0
            : (availableHeight - 120).clamp(420.0, 680.0);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KToolbar(
                  label: label('Calendar', 'Kalender'),
                  children: [
                    KButton(
                      label: label('Today', 'Heute'),
                      variant: KButtonVariant.secondary,
                      onPressed: () => setState(() => _date = DateTime.now()),
                    ),
                    KIconButton(
                      icon: KIconName.chevronLeft,
                      label: label('Previous period', 'Vorheriger Zeitraum'),
                      onPressed: () => navigate(-1),
                    ),
                    KIconButton(
                      icon: KIconName.chevronRight,
                      label: label('Next period', 'Nächster Zeitraum'),
                      onPressed: () => navigate(1),
                    ),
                    Text(
                      '${months[_date.month - 1]} ${_date.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(
                      width: 140,
                      child: KSelect(
                        value: _view.name,
                        options: [
                          KSelectOption(
                            value: 'day',
                            label: label('Day', 'Tag'),
                          ),
                          KSelectOption(
                            value: 'threeDay',
                            label: label('3 days', '3 Tage'),
                          ),
                          KSelectOption(
                            value: 'week',
                            label: label('Week', 'Woche'),
                          ),
                          KSelectOption(
                            value: 'month',
                            label: label('Month', 'Monat'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(
                              () => _view = KCalendarView.values.byName(v),
                            );
                          }
                        },
                      ),
                    ),
                    KButton(
                      label:
                          '${label('Unplanned', 'Ungeplant')} ${visible.where((e) => e.start == null).length}',
                      variant: KButtonVariant.secondary,
                      onPressed: () {
                        if (compact) {
                          KBottomSheet.show<void>(
                            context: context,
                            title: Text(label('Unplanned', 'Ungeplant')),
                            child: unplannedContent(sheet: true),
                          );
                        } else {
                          setState(() => _unplanned = !_unplanned);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                KFilterBar(
                  label: label('Calendar filters', 'Kalenderfilter'),
                  onReset: _project == null
                      ? null
                      : () => setState(() => _project = null),
                  children: [
                    SizedBox(
                      width: 180,
                      child: KSelect(
                        value: _project,
                        placeholder: label('All projects', 'Alle Projekte'),
                        clearable: true,
                        options: const [
                          KSelectOption(value: 'Orbit', label: 'Orbit'),
                          KSelectOption(value: 'Workspace', label: 'Workspace'),
                          KSelectOption(value: 'Research', label: 'Research'),
                        ],
                        onChanged: (v) => setState(() => _project = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_scheduling != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label(
                            'Choose a time in the calendar',
                            'Wähle einen Zeitraum im Kalender',
                          ),
                        ),
                      ),
                      KButton(
                        label: label('Cancel', 'Abbrechen'),
                        variant: KButtonVariant.ghost,
                        onPressed: () => setState(() => _scheduling = null),
                      ),
                    ],
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: KCalendar<CalendarDemoEvent>(
                        date: _date,
                        view: _view,
                        onNavigate: navigate,
                        events: visible,
                        eventId: (e) => e.id,
                        eventStart: (e) => e.start,
                        eventEnd: (e) => e.end,
                        eventAllDay: (e) => e.allDay,
                        timeZone: 'Europe/Berlin',
                        startHour: 7,
                        endHour: 24,
                        hourHeight: 56,
                        height: calendarHeight,
                        labels: KCalendarLabels(
                          allDay: label('All day', 'Ganztägig'),
                          resizeStart: label('Change start', 'Beginn ändern'),
                          resizeEnd: label('Change end', 'Ende ändern'),
                        ),
                        onEventOpen: (e) => edit(compact, event: e),
                        onEventMove: move,
                        onEventResize: resize,
                        onCreate: (range) => edit(compact, selection: range),
                        requireLongPress: compact,
                        eventBuilder: (context, value) => CalendarDemoCard(
                          event: value.event,
                          compact: compact || value.compact,
                        ),
                      ),
                    ),
                    if (_unplanned && !compact)
                      Container(
                        width: 280,
                        height: calendarHeight,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: t.colorBorderDefault),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(label('Unplanned', 'Ungeplant')),
                                ),
                                KIconButton(
                                  icon: KIconName.x,
                                  label: label('Close', 'Schließen'),
                                  onPressed: () =>
                                      setState(() => _unplanned = false),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            unplannedContent(),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _message.isEmpty
                      ? label(
                          'Click a free slot or drag to select a range.',
                          'Freien Zeitpunkt anklicken oder einen Zeitraum aufziehen.',
                        )
                      : _message,
                  style: TextStyle(
                    color: t.colorTextMuted,
                    fontSize: t.fontCaptionSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
