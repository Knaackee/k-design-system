import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

const _sections =
    <
      ({
        String id,
        String label,
        String description,
        KIconName icon,
        String group,
      })
    >[
      (
        id: 'preferences',
        label: 'Preferences',
        description: 'Language, appearance, and regional defaults.',
        icon: KIconName.slidersHorizontal,
        group: 'Personal',
      ),
      (
        id: 'profile',
        label: 'Profile',
        description: 'Your public name and account details.',
        icon: KIconName.user,
        group: 'Personal',
      ),
      (
        id: 'notifications',
        label: 'Notifications',
        description: 'Choose when and where you are notified.',
        icon: KIconName.bell,
        group: 'Personal',
      ),
      (
        id: 'security',
        label: 'Security & access',
        description: 'Password, sessions, and sign-in methods.',
        icon: KIconName.lock,
        group: 'Personal',
      ),
      (
        id: 'workspace',
        label: 'Workspace',
        description: 'Identity and defaults for this workspace.',
        icon: KIconName.users,
        group: 'Workspace',
      ),
      (
        id: 'issues',
        label: 'Issues & editor',
        description: 'Defaults for creating and editing work.',
        icon: KIconName.checkCheck,
        group: 'Workspace',
      ),
      (
        id: 'integrations',
        label: 'Agents & integrations',
        description: 'Connected tools and automated workflows.',
        icon: KIconName.settings,
        group: 'Workspace',
      ),
      (
        id: 'data',
        label: 'Data & advanced',
        description: 'Exports, retention, and advanced options.',
        icon: KIconName.settings,
        group: 'System',
      ),
    ];

class SettingsPageFixture extends StatefulWidget {
  const SettingsPageFixture({this.onBackToApp, super.key});
  final VoidCallback? onBackToApp;

  @override
  State<SettingsPageFixture> createState() => _SettingsPageFixtureState();
}

class _SettingsPageFixtureState extends State<SettingsPageFixture> {
  String selected = 'profile';
  bool mobileDetail = false;
  bool updates = true;
  bool saved = false;
  double notificationVolume = 60;
  String query = '';
  final name = TextEditingController(text: 'Dennis Knaack');
  final email = TextEditingController(text: 'dennis@example.com');

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  void select(String id, {required bool compact}) => setState(() {
    selected = id;
    if (compact) mobileDetail = true;
  });

  @override
  Widget build(BuildContext context) {
    return KSettingsPage(
      contentPadding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < KSettingsPage.breakpoint ? 16 : 24,
        24,
        MediaQuery.sizeOf(context).width < KSettingsPage.breakpoint ? 16 : 24,
        48,
      ),
      navigation: _SettingsNavigation(
        selected: selected,
        query: query,
        onQueryChanged: (value) => setState(() => query = value),
        onBackToApp: widget.onBackToApp,
        onSelect: (id) => select(id, compact: true),
      ),
      content: _SettingsContent(
        saved: saved,
        onSave: () => setState(() => saved = true),
        name: name,
        email: email,
        updates: updates,
        onUpdatesChanged: (value) => setState(() => updates = value),
        notificationVolume: notificationVolume,
        onNotificationVolumeChanged: (value) =>
            setState(() => notificationVolume = value),
      ),
      detailVisible: mobileDetail,
      onBack: () => setState(() => mobileDetail = false),
      backLabel: 'Settings',
      title: 'Profile',
      description:
          'Manage your personal information and communication preferences.',
    );
  }
}

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({
    required this.selected,
    required this.onSelect,
    required this.query,
    required this.onQueryChanged,
    this.onBackToApp,
  });

  final String selected;
  final ValueChanged<String> onSelect;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback? onBackToApp;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => KSidebar(
      mode: KSidebarMode.expanded,
      expandedWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : 280,
      semanticLabel: 'Settings navigation',
      child: Column(
        children: [
          KSidebarHeader(
            child: Column(
              spacing: 8,
              children: [
                KSidebarItem(
                  label: 'Back to app',
                  onPressed: onBackToApp,
                  leading: KIcon(KIconName.arrowLeft),
                ),
                KSearchField(
                  placeholder: 'Search settings',
                  onChanged: onQueryChanged,
                ),
              ],
            ),
          ),
          KSidebarBody(
            children: ['Personal', 'Workspace', 'System']
                .map(
                  (group) => KSidebarGroup(
                    label: group,
                    children: _sections
                        .where(
                          (section) =>
                              section.group == group &&
                              section.label.toLowerCase().contains(
                                query.toLowerCase(),
                              ),
                        )
                        .map(
                          (section) => KSidebarItem(
                            label: section.label,
                            leading: KIcon(section.icon),
                            trailing: const KIcon(
                              KIconName.chevronRight,
                              size: 14,
                            ),
                            active: section.id == selected,
                            onPressed: () => onSelect(section.id),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.saved,
    required this.onSave,
    required this.name,
    required this.email,
    required this.updates,
    required this.onUpdatesChanged,
    required this.notificationVolume,
    required this.onNotificationVolumeChanged,
  });

  final bool saved;
  final VoidCallback onSave;
  final TextEditingController name;
  final TextEditingController email;
  final bool updates;
  final ValueChanged<bool> onUpdatesChanged;
  final double notificationVolume;
  final ValueChanged<double> onNotificationVolumeChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KSettingsSection(
        title: 'Profile information',
        description: 'Details shown across your workspace.',
        child: Column(
          children: [
            KSettingsRow(
              title: 'Display name',
              description: 'Used in comments, assignments, and mentions.',
              layout: KSettingsRowLayout.fullWidth,
              control: KInput(
                controller: name,
                label: 'Display name',
                clearable: true,
              ),
            ),
            KSettingsRow(
              title: 'Contact email',
              description: 'Used for account and security messages.',
              layout: KSettingsRowLayout.fullWidth,
              control: KInput(controller: email, label: 'Contact email'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      KSettingsSection(
        title: 'Communication',
        description: 'Choose which product messages you receive.',
        child: Column(
          children: [
            KSettingsRow(
              title: 'Notification volume',
              description: 'Adjust the volume used for preview sounds.',
              layout: KSettingsRowLayout.fullWidth,
              control: KSlider(
                label: 'Notification volume',
                value: notificationVolume,
                valueLabel: (value) => '${value.round()}%',
                onChanged: onNotificationVolumeChanged,
              ),
            ),
            KSettingsRow(
              title: 'Product updates',
              description:
                  'Receive a concise monthly summary of important changes.',
              layout: KSettingsRowLayout.compact,
              control: KSwitch(
                label: 'Product updates',
                showLabel: false,
                value: updates,
                onChanged: onUpdatesChanged,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 32),
      Align(
        alignment: Alignment.centerLeft,
        child: KButton(label: 'Save changes', onPressed: onSave),
      ),
      if (saved) ...[
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: const Text('Changes saved locally.'),
        ),
      ],
    ],
  );
}
