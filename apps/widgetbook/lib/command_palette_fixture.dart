import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_ui/k_design_ui.dart';

class CommandPaletteFixture extends StatefulWidget {
  const CommandPaletteFixture({super.key});

  @override
  State<CommandPaletteFixture> createState() => _CommandPaletteFixtureState();
}

class _CommandPaletteFixtureState extends State<CommandPaletteFixture> {
  String _result = 'No command selected';
  bool _opening = false;

  static const _commands = <KCommandPaletteItem>[
    KCommandPaletteItem(
      id: 'new',
      label: 'Create new…',
      description: 'Start with a new item',
      icon: KIconName.plus,
      group: 'Actions',
      priority: 20,
      children: [
        KCommandPaletteItem(
          id: 'new-issue',
          label: 'Issue',
          icon: KIconName.circleCheck,
          shortcut: ['N', 'I'],
        ),
        KCommandPaletteItem(
          id: 'new-project',
          label: 'Project',
          icon: KIconName.folder,
          shortcut: ['N', 'P'],
        ),
        KCommandPaletteItem(
          id: 'new-document',
          label: 'Document',
          icon: KIconName.fileText,
          shortcut: ['N', 'D'],
        ),
      ],
    ),
    KCommandPaletteItem(
      id: 'search',
      label: 'Search workspace',
      description: 'Find issues, projects and documents',
      keywords: ['find', 'lookup'],
      icon: KIconName.search,
      shortcut: ['⌘', 'F'],
      group: 'Actions',
      priority: 10,
    ),
    KCommandPaletteItem(
      id: 'inbox',
      label: 'Open inbox',
      description: 'Review unread notifications',
      icon: KIconName.mail,
      shortcut: ['G', 'I'],
      group: 'Navigation',
    ),
    KCommandPaletteItem(
      id: 'projects',
      label: 'Open projects',
      icon: KIconName.folder,
      shortcut: ['G', 'P'],
      group: 'Navigation',
    ),
    KCommandPaletteItem(
      id: 'settings',
      label: 'Open settings',
      icon: KIconName.settings,
      shortcut: ['⌘', ','],
      group: 'Navigation',
    ),
    KCommandPaletteItem(
      id: 'theme',
      label: 'Change appearance…',
      description: 'Choose a color theme',
      icon: KIconName.eye,
      group: 'Preferences',
      children: [
        KCommandPaletteItem(
          id: 'theme-system',
          label: 'Use system appearance',
          icon: KIconName.slidersHorizontal,
        ),
        KCommandPaletteItem(
          id: 'theme-light',
          label: 'Light appearance',
          icon: KIconName.eye,
        ),
        KCommandPaletteItem(
          id: 'theme-dark',
          label: 'Dark appearance',
          icon: KIconName.eyeOff,
        ),
      ],
    ),
    KCommandPaletteItem(
      id: 'disabled',
      label: 'Unavailable command',
      description: 'Disabled items remain discoverable',
      icon: KIconName.lock,
      group: 'Preferences',
      disabled: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (_opening || !mounted) return;
    _opening = true;
    await KCommandPalette.show(
      context: context,
      items: _commands,
      onCommand: (item) {
        if (mounted) setState(() => _result = '${item.label} selected');
      },
    );
    _opening = false;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _open,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _open,
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const KText('Command palette', variant: KTextVariant.heading4),
              const SizedBox(height: 8),
              const KText(
                'Run an action with search, touch or keyboard navigation.',
              ),
              const SizedBox(height: 16),
              KButton(label: 'Open commands · Ctrl K', onPressed: _open),
              const SizedBox(height: 16),
              KText(_result),
            ],
          ),
        ),
      ),
    );
  }
}
