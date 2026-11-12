import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

// Decision 0017: KSettingsDialog, KSaveBar, KAvatarPicker.
// Storybook twins: src/settings-dialog.stories.tsx (same fixture ids).

const avatarShapes = [
  ('circle', 'Circle', KIconName.circle),
  ('squircle', 'Squircle', KIconName.squircle),
  ('triangle', 'Triangle', KIconName.triangle),
  ('star', 'Star', KIconName.star),
  ('drop', 'Drop', KIconName.droplet),
  ('cloud', 'Cloud', KIconName.cloud),
  ('hexagon', 'Hexagon', KIconName.hexagon),
  ('ghost', 'Ghost', KIconName.ghost),
  ('heart', 'Heart', KIconName.heart),
  ('egg', 'Egg', KIconName.egg),
  ('diamond', 'Diamond', KIconName.diamond),
  ('flower', 'Flower', KIconName.flower),
];

const avatarColors = [
  KAvatarColor(value: Color(0xFFF43F5E), label: 'Rose'),
  KAvatarColor(value: Color(0xFFF97316), label: 'Orange'),
  KAvatarColor(value: Color(0xFFEAB308), label: 'Yellow'),
  KAvatarColor(value: Color(0xFF22C55E), label: 'Green'),
  KAvatarColor(value: Color(0xFF14B8A6), label: 'Teal'),
  KAvatarColor(value: Color(0xFF22D3EE), label: 'Cyan'),
  KAvatarColor(value: Color(0xFF3B82F6), label: 'Blue'),
  KAvatarColor(value: Color(0xFF8B5CF6), label: 'Violet'),
];

List<KAvatarShape> avatarShapeOptions() => [
  for (final (id, label, icon) in avatarShapes)
    KAvatarShape(id: id, label: label, icon: KIcon(icon, size: 20)),
];

const _initial = <String, Object>{
  'name': 'Rocky',
  'shape': 'drop',
  'color': Color(0xFF22D3EE),
  'team': 'none',
  'tempo': 'normal',
  'dropbox': true,
  'gmail': true,
  'postiz': true,
  'web': false,
  'tailscale': true,
  'model': 'luna',
  'effort': 'medium',
  'instructions': '',
};

const _keysOf = {
  'profile': ['name', 'shape', 'color', 'team'],
  'voice': ['tempo'],
  'integrations': ['dropbox', 'gmail', 'postiz'],
  'access': ['web', 'tailscale'],
  'model': ['model', 'effort', 'instructions'],
};

/// The agent settings of Assist, as in the Storybook fixture.
class AgentSettings extends StatefulWidget {
  const AgentSettings({this.overlay = false, this.route = false, super.key});

  /// Shows a button that opens the dialog instead of the inline panel.
  final bool overlay;

  /// The content of the opened dialog route.
  final bool route;

  @override
  State<AgentSettings> createState() => _AgentSettingsState();
}

class _AgentSettingsState extends State<AgentSettings> {
  var _saved = Map<String, Object>.of(_initial);
  var _state = Map<String, Object>.of(_initial);
  final _name = TextEditingController(text: 'Rocky');
  final _instructions = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _instructions.dispose();
    super.dispose();
  }

  List<String> get _changed => [
    for (final key in _state.keys)
      if (_state[key] != _saved[key]) key,
  ];

  void _set(String key, Object value) => setState(() => _state[key] = value);

  bool _dirty(String id) =>
      (_keysOf[id] ?? const []).any((key) => _changed.contains(key));

  Widget _switch(String key, String label) => KSwitch(
    label: label,
    showLabel: false,
    value: _state[key]! as bool,
    onChanged: (value) => _set(key, value),
  );

  Widget _select(String key, String label, List<(String, String)> options) =>
      KSelect(
        label: label,
        value: _state[key]! as String,
        onChanged: (value) => _set(key, value!),
        options: [
          for (final (value, text) in options)
            KSelectOption(value: value, label: text),
        ],
      );

  Widget _secondary(String label) => KButton(
    label: label,
    variant: KButtonVariant.secondary,
    onPressed: () {},
  );

  List<KSettingsDialogSection> get _sections {
    final active = [
      'dropbox',
      'gmail',
      'postiz',
    ].where((key) => _state[key] == true).length;
    return [
      KSettingsDialogSection(
        id: 'profile',
        icon: KIconName.user,
        group: 'Agent',
        title: 'Profile',
        summary: 'Drop · No team',
        description: 'Name, look and team. Shown in chats and notifications.',
        dirty: _dirty('profile'),
        child: KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            KInput(
              label: 'Name',
              controller: _name,
              onChanged: (value) => _set('name', value),
            ),
            KAvatarPicker(
              shapes: avatarShapeOptions(),
              colors: avatarColors,
              shape: _state['shape']! as String,
              color: _state['color']! as Color,
              onShapeChanged: (value) => _set('shape', value),
              onColorChanged: (value) => _set('color', value),
            ),
            KList(
              children: [
                KSettingsRow(
                  title: 'Team',
                  description: 'A team shares its knowledge with the agent.',
                  control: _select('team', 'Team', const [
                    ('none', 'No team'),
                    ('test', 'Test'),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
      KSettingsDialogSection(
        id: 'voice',
        icon: KIconName.audioLines,
        group: 'Agent',
        title: 'Voice',
        status: KStatusTone.warning,
        summary: 'No voice server ready',
        description:
            'Voice and speaking rate apply in the app, on the web and on '
            'Prompt-Boy.',
        dirty: _dirty('voice'),
        child: KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            KAlert(
              tone: KStatusTone.warning,
              icon: KIconName.triangleAlert,
              title: const Text('No voice server ready'),
              description: const Text(
                'Check the connection and reload the voices.',
              ),
              action: _secondary('Reload'),
            ),
            KList(
              children: [
                const KSettingsRow(
                  title: 'Voice',
                  description: 'No voice selected',
                  control: KSelect(
                    label: 'Voice',
                    placeholder: 'Choose voice',
                    options: [],
                  ),
                ),
                KSettingsRow(
                  title: 'Speaking rate',
                  control: _select('tempo', 'Speaking rate', const [
                    ('slow', 'Slow'),
                    ('normal', 'Normal'),
                    ('fast', 'Fast'),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
      KSettingsDialogSection(
        id: 'knowledge',
        icon: KIconName.bookOpen,
        group: 'Capabilities',
        title: 'Knowledge & skills',
        status: KStatusTone.warning,
        summary: '1 entry unavailable · 0 skills',
        child: KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            const KAlert(
              tone: KStatusTone.warning,
              icon: KIconName.triangleAlert,
              title: Text('A knowledge entry is no longer available'),
              description: Text('It was deleted or removed from the team.'),
            ),
            KList(
              title: 'Team knowledge',
              children: [
                KSettingsRow(
                  title: 'Memories',
                  description: 'What Rocky remembers from conversations.',
                  control: _secondary('Open'),
                ),
              ],
            ),
            KList(
              title: 'Skills',
              children: [
                KSettingsRow(
                  title: 'No skills in this area yet',
                  description: 'Save a version in the skill library first.',
                  control: _secondary('Skill library'),
                ),
              ],
            ),
          ],
        ),
      ),
      KSettingsDialogSection(
        id: 'integrations',
        icon: KIconName.plug,
        group: 'Capabilities',
        title: 'Integrations',
        summary: '$active of 3 active',
        description:
            'Connected services the agent may use. You still confirm '
            'writing actions.',
        dirty: _dirty('integrations'),
        child: KList(
          children: [
            KSettingsRow(
              title: 'Dropbox',
              description: 'Connected',
              control: _switch('dropbox', 'Dropbox'),
            ),
            KSettingsRow(
              title: 'Gmail',
              description: 'Connected',
              control: _switch('gmail', 'Gmail'),
            ),
            KSettingsRow(
              title: 'Postiz',
              description: 'Connected',
              control: _switch('postiz', 'Postiz'),
            ),
          ],
        ),
      ),
      KSettingsDialogSection(
        id: 'access',
        icon: KIconName.shield,
        group: 'Capabilities',
        title: 'Access',
        summary:
            'Web ${_state['web'] == true ? 'on' : 'off'} · Tailscale '
            '${_state['tailscale'] == true ? 'on' : 'off'}',
        dirty: _dirty('access'),
        child: KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            KList(
              title: 'Web and browser',
              children: [
                KSettingsRow(
                  title: 'Web access',
                  description: 'Reads websites with Firecrawl.',
                  control: _switch('web', 'Web access'),
                ),
                KSettingsRow(
                  title: 'Browser permissions',
                  description:
                      'None yet. Permissions from the browser chat appear '
                      'here.',
                  control: _secondary('Refresh'),
                ),
              ],
            ),
            KList(
              title: 'Network',
              children: [
                KSettingsRow(
                  title: 'Tailscale',
                  description: 'Own identity in your tailnet.',
                  control: _switch('tailscale', 'Tailscale'),
                ),
              ],
            ),
            const KList(
              title: 'Code and secrets',
              children: [
                KSettingsRow(
                  title: 'GitHub repositories',
                  description: 'None connected in this area.',
                  control: SizedBox.shrink(),
                ),
                KSettingsRow(
                  title: 'Secrets',
                  description: 'None in this area.',
                  control: SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
      KSettingsDialogSection(
        id: 'model',
        icon: KIconName.cpu,
        group: 'Runtime',
        title: 'Model',
        summary: 'GPT-5.6-Luna · Medium',
        dirty: _dirty('model'),
        child: KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            KList(
              children: [
                KSettingsRow(
                  title: 'Model',
                  description: 'The runtime checks support when it prepares.',
                  control: _select('model', 'Model', const [
                    ('luna', 'GPT-5.6-Luna'),
                    ('mini', 'GPT-5.6-mini'),
                  ]),
                ),
                KSettingsRow(
                  title: 'Reasoning effort',
                  control: KSegmentedControl<String>(
                    label: 'Reasoning effort',
                    value: _state['effort']! as String,
                    onChanged: (value) => _set('effort', value),
                    segments: const [
                      KSegment(value: 'low', label: 'Low'),
                      KSegment(value: 'medium', label: 'Medium'),
                      KSegment(value: 'high', label: 'High'),
                    ],
                  ),
                ),
              ],
            ),
            KTextarea(
              label: 'Personality and instructions',
              placeholder:
                  'For example: answer briefly, ask before sending mail.',
              controller: _instructions,
              onChanged: (value) => _set('instructions', value),
            ),
          ],
        ),
      ),
      KSettingsDialogSection(
        id: 'runtime',
        icon: KIconName.server,
        group: 'Runtime',
        title: 'Runtime',
        status: KStatusTone.error,
        summary: 'Environment unavailable',
        child: KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            KAlert(
              tone: KStatusTone.error,
              icon: KIconName.circleAlert,
              title: const Text('Environment unavailable'),
              description: const Text(
                'Running work keeps its resources. The new configuration '
                'applies once it is idle.',
              ),
              action: _secondary('Resume agent'),
            ),
            KList(
              children: [
                KSettingsRow(
                  title: 'Update runtime environment',
                  description:
                      'Reinstalls the environment. Agent state and working '
                      'directory stay.',
                  control: _secondary('Update'),
                ),
              ],
            ),
            const KDisclosure(
              title: 'Technical details',
              child: KText(
                'Applied revision sha256:af6cb9ac…730ab67f',
                variant: KTextVariant.caption,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget get _avatar {
    final icon =
        avatarShapes.where((s) => s.$1 == _state['shape']).firstOrNull?.$3 ??
        KIconName.circle;
    return KIcon(icon, size: 32, color: _state['color']! as Color);
  }

  Widget _footer() => KSaveBar(
    changes: _changed.length,
    onDiscard: () => setState(() {
      _state = Map.of(_saved);
      _name.text = _state['name']! as String;
      _instructions.text = _state['instructions']! as String;
    }),
    onSave: () => setState(() => _saved = Map.of(_state)),
  );

  Widget _dialog({VoidCallback? onClose}) => KSettingsDialog(
    title: (_state['name']! as String).isEmpty
        ? 'Untitled'
        : _state['name']! as String,
    subtitle: 'Personal · Orbit Agent Runtime',
    leading: _avatar,
    sections: _sections,
    footer: _footer(),
    onClose: onClose ?? () {},
  );

  @override
  Widget build(BuildContext context) {
    if (widget.route) {
      return _dialog(onClose: () => Navigator.of(context).pop());
    }
    if (!widget.overlay) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 640),
            child: _dialog(),
          ),
        ),
      );
    }
    return Center(
      child: KButton(
        label: 'Configure agent',
        onPressed: () => KSettingsDialog.show<void>(
          context: context,
          builder: (_) => const AgentSettings(route: true),
        ),
      ),
    );
  }
}
