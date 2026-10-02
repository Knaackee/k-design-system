import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'activity_fixture_data.dart';

class ActivityFixture extends StatefulWidget {
  const ActivityFixture({
    this.phone = false,
    this.empty = false,
    this.statusView = false,
    super.key,
  });
  final bool phone, empty, statusView;
  @override
  State<ActivityFixture> createState() => _ActivityFixtureState();
}

class _ActivityFixtureState extends State<ActivityFixture> {
  String mode = 'completed';
  List<String> projects = [], people = [], statuses = [];

  String? detail;

  KDesignTokens get t => Theme.of(context).extension<KDesignTokens>()!;
  List<ActivityIssue> get filtered =>
      (widget.empty
              ? <ActivityIssue>[]
              : widget.statusView
              ? activityStatusIssues
              : activityIssues)
          .where(
            (i) =>
                (widget.statusView ||
                    (mode == 'completed'
                        ? i.status == 'done'
                        : i.status != 'done')) &&
                (projects.isEmpty || projects.contains(i.project)) &&
                (people.isEmpty || people.contains(i.person)) &&
                (statuses.isEmpty || statuses.contains(i.status)),
          )
          .toList();
  Widget small(String text) =>
      Text(text, style: TextStyle(fontSize: 11, color: t.colorTextMuted));

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

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: widget.phone
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 20)
          : const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          small('WORKSPACE · BEISPIELDATEN'),
          const SizedBox(height: 8),
          const Text(
            'Aktivität',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('Was geschafft wurde. Was als Nächstes ansteht.'),
          const SizedBox(height: 24),
          filters(widget.phone),
          const SizedBox(height: 24),
          KActivityHeatmap(
            phone: widget.phone,
            today: activityToday,
            mode: mode == 'completed'
                ? KActivityMode.completed
                : KActivityMode.upcoming,
            items: [
              for (final issue in filtered)
                KActivityItem(
                  id: issue.id,
                  title: issue.title,
                  date: issue.date,
                  metadata: '${issue.id} · ${issue.project} · ${issue.person}',
                  leading: KIcon(
                    issue.project == 'Orbit'
                        ? KIconName.rocket
                        : KIconName.code,
                    color: issue.project == 'Orbit'
                        ? const Color(0xffE76F51)
                        : const Color(0xff2A9D8F),
                  ),
                  completed: issue.status == 'done',
                ),
            ],
            onOpenItem: (id) => setState(() => detail = id),
            onAddDate: (date) => setState(
              () => detail = 'add:${date.toIso8601String().substring(0, 10)}',
            ),
            addLabel: 'Issue hinzufügen',
          ),
          if (detail != null)
            Text(
              '$detail ausgewählt. In Tasks öffnet sich hier die Issue-Detailansicht.',
            ),
        ],
      ),
    ),
  );
}
