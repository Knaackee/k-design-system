import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      final section = _sections.firstWhere((entry) => entry.id == selected);
      final navigation = _SettingsNavigation(
        selected: selected,
        query: query,
        onQueryChanged: (value) => setState(() => query = value),
        onBackToApp: widget.onBackToApp,
        width: compact ? constraints.maxWidth : 280,
        onSelect: (id) => select(id, compact: compact),
      );
      final content = _SettingsContent(
        section: section,
        saved: saved,
        onSave: () => setState(() => saved = true),
        compact: compact,
        name: name,
        email: email,
        updates: updates,
        onUpdatesChanged: (value) => setState(() => updates = value ?? false),
        onBack: () => setState(() => mobileDetail = false),
      );
      if (compact) {
        return SizedBox.expand(child: mobileDetail ? content : navigation);
      }
      return SizedBox.expand(
        child: Row(
          children: [
            navigation,
            Expanded(child: content),
          ],
        ),
      );
    },
  );
}

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({
    required this.selected,
    required this.width,
    required this.onSelect,
    required this.query,
    required this.onQueryChanged,
    this.onBackToApp,
  });

  final String selected;
  final double width;
  final ValueChanged<String> onSelect;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback? onBackToApp;

  @override
  Widget build(BuildContext context) => KSidebar(
    mode: KSidebarMode.expanded,
    expandedWidth: width,
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
  );
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.section,
    required this.saved,
    required this.onSave,
    required this.compact,
    required this.name,
    required this.email,
    required this.updates,
    required this.onUpdatesChanged,
    required this.onBack,
  });

  final ({
    String id,
    String label,
    String description,
    KIconName icon,
    String group,
  })
  section;
  final bool compact;
  final bool saved;
  final VoidCallback onSave;
  final TextEditingController name;
  final TextEditingController email;
  final bool updates;
  final ValueChanged<bool?> onUpdatesChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return ColoredBox(
      color: t.colorSurfaceCanvas,
      child: ListView(
        primary: false,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 48,
          vertical: compact ? 12 : 48,
        ),
        children: [
          if (compact)
            Align(
              alignment: Alignment.centerLeft,
              child: KButton(
                label: 'Settings',
                leading: const KIcon(KIconName.arrowLeft),
                variant: KButtonVariant.ghost,
                onPressed: onBack,
              ),
            ),
          if (compact) const SizedBox(height: 12),
          Text(
            section.group,
            style: TextStyle(
              color: t.colorTextMuted,
              fontFamily: t.fontFamily,
              fontSize: t.fontCaptionSize,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section.label,
            style: TextStyle(
              color: t.colorTextPrimary,
              fontFamily: t.fontFamily,
              fontSize: compact ? 24 : 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.description,
            style: TextStyle(color: t.colorTextMuted, fontFamily: t.fontFamily),
          ),
          const SizedBox(height: 32),
          KField(
            label: 'Display name',
            child: KInput(controller: name, clearable: true),
          ),
          const SizedBox(height: 20),
          KField(
            label: 'Contact email',
            helperText: 'Used for account and security messages.',
            child: KInput(controller: email),
          ),
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: t.colorBorderDefault),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product updates',
                          style: TextStyle(
                            color: t.colorTextPrimary,
                            fontFamily: t.fontFamily,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Receive a concise monthly summary of important changes.',
                          style: TextStyle(
                            color: t.colorTextMuted,
                            fontFamily: t.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: 'Product updates',
                    child: ExcludeSemantics(
                      child: KCheckbox(
                        label: '',
                        value: updates,
                        onChanged: onUpdatesChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (saved)
            Semantics(
              liveRegion: true,
              child: Text('Demo: Changes saved locally.'),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: KButton(label: 'Save changes', onPressed: onSave),
          ),
        ],
      ),
    );
  }
}
