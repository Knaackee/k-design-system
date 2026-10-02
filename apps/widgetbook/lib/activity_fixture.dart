import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'activity_fixture_data.dart';
import 'activity_cells.dart';

class ActivityFixture extends StatefulWidget {
  const ActivityFixture({this.phone = false, this.empty = false, super.key});
  final bool phone, empty;
  @override
  State<ActivityFixture> createState() => _ActivityFixtureState();
}

class _ActivityFixtureState extends State<ActivityFixture> {
  String mode = 'completed';
  List<String> projects = [], people = [], statuses = [];
  DateTime? selected;
  String? detail;
  int firstMonth = 0, lastMonth = 2;
  final scroll = ScrollController();
  final monthKeys = <int, GlobalKey>{};
  KDesignTokens get t => Theme.of(context).extension<KDesignTokens>()!;
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  List<ActivityIssue> get filtered =>
      (widget.empty ? <ActivityIssue>[] : activityIssues)
          .where(
            (i) =>
                (mode == 'completed'
                    ? i.status == 'done'
                    : i.status != 'done') &&
                (projects.isEmpty || projects.contains(i.project)) &&
                (people.isEmpty || people.contains(i.person)) &&
                (statuses.isEmpty || statuses.contains(i.status)),
          )
          .toList();
  List<ActivityIssue> dayIssues(DateTime date) =>
      filtered.where((i) => i.date == date).toList();
  Widget small(String text) =>
      Text(text, style: TextStyle(fontSize: 11, color: t.colorTextMuted));
  Color levelColor(int count) => activityLevelColor(t, count);

  Future<void> chooseDay(DateTime date, bool mobile) async {
    if (selected == date && !mobile) {
      setState(() {
        selected = null;
        detail = null;
      });
      return;
    }
    setState(() {
      selected = date;
      detail = null;
    });
    if (!mobile) return;
    await KBottomSheet.show<void>(
      context: context,
      title: Text(activityDateLabel(date)),
      description: Text(
        mode == 'completed' ? 'Abgeschlossene Issues' : 'Anstehende Issues',
      ),
      closeLabel: 'Schließen',
      child: StatefulBuilder(
        builder: (context, update) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dayIssues(date).isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'Keine Issues an diesem Tag.',
                  style: TextStyle(color: t.colorTextMuted),
                ),
              ),
            for (final issue in dayIssues(date))
              issueRow(issue, true, () => update(() => detail = issue.id)),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$detail ausgewählt. In Tasks öffnet sich hier die Issue-Detailansicht.',
                ),
              ),
          ],
        ),
      ),
    );
    if (mounted) {
      setState(() {
        selected = null;
        detail = null;
      });
    }
  }

  Widget dayCell(DateTime date, double size, bool mobile) => activityDayCell(
    date,
    size,
    mode == 'completed',
    selected == date,
    dayIssues(date).length,
    t,
    () => chooseDay(date, mobile),
  );
  Widget issueRow(ActivityIssue issue, bool mobile, VoidCallback onTap) =>
      activityIssueRow(t, issue, mobile, onTap);

  void loadMonths(bool earlier) {
    final old = monthKeys[firstMonth]?.currentContext;
    final top = (old?.findRenderObject() as RenderBox?)
        ?.localToGlobal(Offset.zero)
        .dy;
    setState(() {
      if (earlier) {
        firstMonth -= 3;
      } else {
        lastMonth += 3;
      }
    });
    if (earlier && top != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !scroll.hasClients) return;
        final next = (old?.findRenderObject() as RenderBox?)
            ?.localToGlobal(Offset.zero)
            .dy;
        if (next != null) {
          scroll.jumpTo(
            (scroll.offset + next - top).clamp(
              0,
              scroll.position.maxScrollExtent,
            ),
          );
        }
      });
    }
  }

  Widget monthBlock(int offset) {
    final start = DateTime.utc(2026, 10 + offset);
    final cells = activityMonthCells(offset);
    return Container(
      key: monthKeys.putIfAbsent(offset, GlobalKey.new),
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${activityMonths[start.month - 1]} ${start.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (offset == 0) small('Aktueller Monat'),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    for (final day in [
                      'Mo',
                      'Di',
                      'Mi',
                      'Do',
                      'Fr',
                      'Sa',
                      'So',
                    ])
                      SizedBox(
                        height: 50,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: small(day),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var week = 0; week < cells.length ~/ 7; week++)
                            Column(
                              children: [
                                for (var row = 0; row < 7; row++)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: row < 6 ? 6 : 0,
                                    ),
                                    child: cells[week * 7 + row] == null
                                        ? const SizedBox(width: 44, height: 44)
                                        : dayCell(
                                            cells[week * 7 + row]!,
                                            44,
                                            true,
                                          ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget filters(bool mobile) {
    final items = [
      KSelect(
        label: 'Ansicht',
        value: mode,
        options: const [
          KSelectOption(
            value: 'completed',
            label: 'Erledigt',
            icon: KIconName.circleCheck,
          ),
          KSelectOption(
            value: 'upcoming',
            label: 'Anstehend',
            icon: KIconName.calendar,
          ),
        ],
        onChanged: (v) => setState(() {
          mode = v!;
          selected = null;
          detail = null;
          statuses = [];
        }),
      ),
      KSelect(
        label: 'Projekte',
        multiple: true,
        values: projects,
        placeholder: 'Alle Projekte',
        options: const [
          KSelectOption(
            value: 'Tasks',
            label: 'Tasks',
            leading: KIcon(KIconName.code, color: Color(0xff2A9D8F)),
          ),
          KSelectOption(
            value: 'Orbit',
            label: 'Orbit',
            leading: KIcon(KIconName.rocket, color: Color(0xffE76F51)),
          ),
        ],
        onValuesChanged: (v) => setState(() => projects = v),
      ),
      KSelect(
        label: 'Personen',
        multiple: true,
        values: people,
        placeholder: 'Alle Personen',
        options: const [
          KSelectOption(value: 'Denis', label: 'Denis', icon: KIconName.user),
          KSelectOption(value: 'Hans', label: 'Hans', icon: KIconName.user),
        ],
        onValuesChanged: (v) => setState(() => people = v),
      ),
      KSelect(
        label: 'Status',
        multiple: true,
        values: statuses,
        placeholder: mode == 'completed' ? 'Erledigt' : 'Alle offenen',
        options: mode == 'completed'
            ? const [
                KSelectOption(
                  value: 'done',
                  label: 'Erledigt',
                  icon: KIconName.circleCheck,
                ),
              ]
            : const [
                KSelectOption(
                  value: 'backlog',
                  label: 'Backlog',
                  icon: KIconName.inbox,
                ),
                KSelectOption(
                  value: 'in-progress',
                  label: 'In Arbeit',
                  icon: KIconName.loader,
                ),
              ],
        onValuesChanged: (v) => setState(() => statuses = v),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in items)
            SizedBox(
              width:
                  (constraints.maxWidth - (mobile ? 12 : 36)) /
                  (mobile ? 2 : 4),
              child: item,
            ),
        ],
      ),
    );
  }

  Widget desktopRaster(double width) =>
      activityDesktopRaster(width, t, dayCell);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = widget.phone || constraints.maxWidth <= 600;
      final maxWidth = widget.phone && constraints.maxWidth > 600
          ? 390.0
          : 1040.0;
      return ColoredBox(
        color: t.colorSurfaceCanvas,
        child: SingleChildScrollView(
          controller: scroll,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: mobile
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 20)
                    : const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    small('WORKSPACE · BEISPIELDATEN'),
                    const SizedBox(height: 8),
                    const Text(
                      'Aktivität',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Was geschafft wurde. Was als Nächstes ansteht.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    filters(mobile),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${filtered.length} ${mode == 'completed' ? 'abgeschlossene' : 'offene'} Issues',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!mobile) small('29. Juni – 27. Dezember 2026'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (mobile) ...[
                      KButton(
                        label: 'Frühere Monate laden',
                        onPressed: () => loadMonths(true),
                        variant: KButtonVariant.ghost,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 24),
                      for (var month = firstMonth; month <= lastMonth; month++)
                        monthBlock(month),
                      KButton(
                        label: 'Weitere Monate laden',
                        onPressed: () => loadMonths(false),
                        variant: KButtonVariant.ghost,
                        fullWidth: true,
                      ),
                    ] else
                      LayoutBuilder(
                        builder: (context, box) => desktopRaster(box.maxWidth),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        small(
                          '${mode == 'completed' ? 'Abschlüsse' : 'Fällige Issues'} pro Tag · Heute: 2. Oktober',
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            small('Weniger'),
                            for (var i = 0; i <= 4; i++)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: levelColor(i),
                                  border: Border.all(
                                    color: t.colorBorderDefault,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            small('Mehr'),
                          ],
                        ),
                      ],
                    ),
                    if (!mobile && selected != null) ...[
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activityDateLabel(selected!),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          KButton(
                            label: 'Schließen',
                            onPressed: () => setState(() {
                              selected = null;
                              detail = null;
                            }),
                            variant: KButtonVariant.ghost,
                          ),
                        ],
                      ),
                      if (dayIssues(selected!).isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Text('Keine Issues an diesem Tag.'),
                        ),
                      for (final issue in dayIssues(selected!))
                        issueRow(
                          issue,
                          false,
                          () => setState(() => detail = issue.id),
                        ),
                      if (detail != null)
                        Text(
                          '$detail ausgewählt. In Tasks öffnet sich hier die Issue-Detailansicht.',
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
