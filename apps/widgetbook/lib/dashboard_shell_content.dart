import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const shellProjects = [
  ('Website refresh', 'In progress'),
  ('Customer portal', 'In review'),
  ('Mobile app', 'Planned'),
];

class DashboardShellContent extends StatelessWidget {
  const DashboardShellContent({
    required this.page,
    required this.project,
    required this.mobile,
    required this.onSelect,
    required this.onBack,
    super.key,
  });
  final String page;
  final String? project;
  final bool mobile;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return ListView(
      primary: false,
      padding: EdgeInsets.all(mobile ? 16 : 24),
      children: [
        KText(project ?? page, variant: KTextVariant.heading2),
        KText(
          project != null
              ? 'Track progress and keep project notes together.'
              : page == 'Overview'
              ? 'A clear view of your workspace.'
              : 'Your current projects and their progress.',
          style: TextStyle(color: t.colorTextPrimary),
        ),
        const SizedBox(height: 16),
        if (page == 'Overview' && project == null) ...[
          LayoutBuilder(
            builder: (context, box) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final metric in [
                  ('Active projects', '12'),
                  ('Tasks completed', '84'),
                  ('Needs attention', '3'),
                ])
                  SizedBox(
                    width: mobile ? box.maxWidth : (box.maxWidth - 32) / 3,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 104),
                      child: KCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KText(metric.$1, variant: KTextVariant.bodySmall),
                            const SizedBox(height: 8),
                            KText(metric.$2, variant: KTextVariant.heading2),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (project == null) ...[
                const KText('Projects', variant: KTextVariant.heading4),
                const SizedBox(height: 16),
                for (final row in shellProjects)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: row == shellProjects.last ? 0 : 16,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      decoration: BoxDecoration(
                        border: row == shellProjects.last
                            ? null
                            : Border(
                                bottom: BorderSide(color: t.colorBorderDefault),
                              ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          KButton(
                            label: row.$1,
                            variant: KButtonVariant.ghost,
                            onPressed: () => onSelect(row.$1),
                          ),
                          KBadge(
                            variant: KBadgeVariant.secondary,
                            child: Text(row.$2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: KBadge(
                    variant: KBadgeVariant.secondary,
                    child: Text(
                      shellProjects.firstWhere((row) => row.$1 == project).$2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const KText(
                  'Review the project details and add a note to coordinate the next steps.',
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: KButton(
                    label: 'Back to projects',
                    variant: KButtonVariant.secondary,
                    onPressed: onBack,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        KText(
          'Demo workspace · No live data',
          variant: KTextVariant.caption,
          style: TextStyle(color: t.colorTextPrimary),
        ),
      ],
    );
  }
}
