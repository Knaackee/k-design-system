import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Same fixtures as Storybook core-components-fixtures.tsx.
EdgeInsets _pad(BuildContext context) => EdgeInsets.all(
  Theme.of(context).extension<KDesignTokens>()!.spaceLayoutGutter,
);

/// Reference settings screen: grouped sections, real content, no demo text.
class SettingsListFixture extends StatelessWidget {
  const SettingsListFixture({super.key});

  @override
  Widget build(BuildContext context) => KStack(
    gap: KLayoutGap.section,
    align: KLayoutAlign.stretch,
    children: [
      KList(
        title: 'Account',
        children: [
          KListItem(
            title: 'Profile',
            description: 'Dana Weber · dana@example.com',
            leadingIcon: KIconName.user,
            onPressed: () {},
          ),
          KListItem(
            title: 'Password and security',
            leadingIcon: KIconName.lock,
            onPressed: () {},
          ),
        ],
      ),
      KList(
        title: 'Notifications',
        children: [
          KListItem(
            title: 'Push notifications',
            leadingIcon: KIconName.bell,
            trailing: const KBadge(
              variant: KBadgeVariant.secondary,
              child: Text('3 new'),
            ),
            onPressed: () {},
          ),
          KListItem(
            title: 'Email summary',
            leadingIcon: KIconName.mail,
            value: 'Weekly',
            onPressed: () {},
          ),
        ],
      ),
      KList(
        title: 'Assistant',
        footer: 'Speech input runs on this device.',
        children: [
          KListItem(
            title: 'On-device speech input',
            leadingIcon: KIconName.mic,
            value: 'Not set up',
            onPressed: () {},
          ),
        ],
      ),
      KList(
        title: 'Storage',
        footer: 'Offline files are removed after 30 days without use.',
        children: [
          const KListItem(
            title: 'Used',
            leadingIcon: KIconName.hardDrive,
            value: '12.4 of 50 GB',
          ),
          KListItem(
            title: 'Downloads',
            leadingIcon: KIconName.download,
            value: 'Wi-Fi only',
            onPressed: () {},
          ),
        ],
      ),
      KList(
        title: 'About',
        footer: 'Version 4.2.0 (318)',
        children: [
          KListItem(
            title: 'Help and support',
            leadingIcon: KIconName.circleQuestionMark,
            onPressed: () {},
          ),
          KListItem(
            title: 'Terms of use',
            leadingIcon: KIconName.fileText,
            onPressed: () {},
          ),
        ],
      ),
    ],
  );
}

/// Objects with media tiles, a status badge and a shared-with summary.
class PortfolioListFixture extends StatelessWidget {
  const PortfolioListFixture({super.key});

  @override
  Widget build(BuildContext context) => KStack(
    gap: KLayoutGap.section,
    align: KLayoutAlign.stretch,
    children: [
      KList(
        title: 'Own portfolios',
        children: [
          KListItem(
            title: 'Riverside Holdings',
            description: 'Dana Weber · Updated 22.09.2026',
            mediaIcon: KIconName.folder,
            trailing: const KBadge(
              variant: KBadgeVariant.secondary,
              child: Text('Draft'),
            ),
            onPressed: () {},
          ),
          KListItem(
            title: 'North Estates',
            description: 'Updated 03.10.2026',
            mediaIcon: KIconName.building,
            value: '12 units',
            onPressed: () {},
          ),
        ],
      ),
      KList(
        title: 'Sharing',
        children: [
          KListItem(
            title: 'Sabrina, Patricia, Kristin',
            leadingIcon: KIconName.users,
            value: '3 people',
            onPressed: () {},
          ),
        ],
      ),
    ],
  );
}

class ListFixture extends StatelessWidget {
  const ListFixture({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: _pad(context),
    child: const SettingsListFixture(),
  );
}

class SegmentedControlFixture extends StatefulWidget {
  const SegmentedControlFixture({super.key});
  @override
  State<SegmentedControlFixture> createState() =>
      _SegmentedControlFixtureState();
}

class _SegmentedControlFixtureState extends State<SegmentedControlFixture> {
  String period = 'week';
  String view = 'list';

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: _pad(context),
    child: KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        KSegmentedControl<String>(
          label: 'Period',
          value: period,
          onChanged: (value) => setState(() => period = value),
          segments: const [
            KSegment(value: 'day', label: 'Day'),
            KSegment(value: 'week', label: 'Week'),
            KSegment(value: 'month', label: 'Month'),
            KSegment(value: 'year', label: 'Year'),
          ],
        ),
        KSegmentedControl<String>(
          label: 'View',
          value: view,
          onChanged: (value) => setState(() => view = value),
          segments: const [
            KSegment(value: 'list', label: 'List', icon: KIconName.list),
            KSegment(value: 'grid', label: 'Grid', icon: KIconName.layoutGrid),
          ],
        ),
        Semantics(
          liveRegion: true,
          child: KText('$period · $view', variant: KTextVariant.bodySmall),
        ),
      ],
    ),
  );
}

class PageHeaderFixture extends StatelessWidget {
  const PageHeaderFixture({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: _pad(context),
    child: KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        KPageHeader(
          title: 'Riverside',
          subtitle: '3 buildings · updated today',
          backLabel: 'Back to Portfolios',
          onBack: () {},
          actions: [
            KIconButton(
              label: 'Share',
              icon: KIconName.share,
              onPressed: () {},
            ),
            KButton(label: 'Add building', onPressed: () {}),
          ],
        ),
        const KPageHeader(
          title: 'Portfolios',
          subtitle: 'Top level: no back control',
        ),
      ],
    ),
  );
}

class AppShellFixture extends StatefulWidget {
  const AppShellFixture({this.initial = 'settings', super.key});
  final String initial;
  @override
  State<AppShellFixture> createState() => _AppShellFixtureState();
}

class _AppShellFixtureState extends State<AppShellFixture> {
  late String selected = widget.initial;
  static const destinations = [
    KAppDestination(id: 'home', label: 'Home', icon: KIconName.house),
    KAppDestination(
      id: 'portfolios',
      label: 'Portfolios',
      icon: KIconName.building,
    ),
    KAppDestination(
      id: 'inbox',
      label: 'Inbox',
      icon: KIconName.inbox,
      badge: '2',
    ),
    KAppDestination(
      id: 'settings',
      label: 'Settings',
      icon: KIconName.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = destinations.firstWhere((item) => item.id == selected);
    return KAppShell(
      destinations: destinations,
      selectedId: selected,
      onSelected: (id) => setState(() => selected = id),
      sidebarHeader: const KText('Assetry', variant: KTextVariant.label),
      // Bottom padding from the shell keeps the last row above the tab bar.
      child: SingleChildScrollView(
        padding: _pad(context).copyWith(
          bottom: _pad(context).bottom + MediaQuery.paddingOf(context).bottom,
        ),
        child: KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            KPageHeader(title: current.label),
            if (selected == 'settings')
              const SettingsListFixture()
            else if (selected == 'portfolios')
              const PortfolioListFixture()
            else
              KText('${current.label} has no content in this reference.'),
          ],
        ),
      ),
    );
  }
}
