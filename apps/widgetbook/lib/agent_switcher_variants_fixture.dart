import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class AgentSwitcherShowcaseFixture extends StatefulWidget {
  const AgentSwitcherShowcaseFixture({
    this.showConnections = true,
    this.showActivity = true,
    this.showUnread = true,
    this.customColors = true,
    this.reorderable = true,
    super.key,
  });

  final bool showConnections;
  final bool showActivity;
  final bool showUnread;
  final bool customColors;
  final bool reorderable;

  @override
  State<AgentSwitcherShowcaseFixture> createState() =>
      _AgentSwitcherShowcaseFixtureState();
}

class _AgentSwitcherShowcaseFixtureState
    extends State<AgentSwitcherShowcaseFixture> {
  static const _initialIds = [
    'nova',
    'atlas',
    'echo',
    'sage',
    'pixel',
    'lumen',
    'orbit',
    'quill',
    'wren',
    'iris',
    'sol',
    'moss',
    'coda',
    'finn',
  ];

  var _ids = [..._initialIds];
  String? _selectedId = 'nova';
  String _note = 'Bereit';

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final byId = _showcaseItems(tokens);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: KStack(
          align: KLayoutAlign.stretch,
          children: [
            KAgentSwitcher(
              items: [for (final id in _ids) byId[id]!],
              selectedId: _selectedId,
              onSelect: (id) => setState(() {
                _selectedId = id;
                _note = 'Auswahl: $id';
              }),
              onLongPress: (id) => setState(() => _note = 'Langdruck: $id'),
              onReorder: widget.reorderable
                  ? (ids) => setState(() {
                      _ids = ids;
                      _note = 'Reihenfolge: ${ids.join(', ')}';
                    })
                  : null,
              labels: const KAgentSwitcherLabels(
                agents: 'Konfigurierbarer Agentenumschalter',
                connectionPrefix: 'Verbindung',
                connectionOnline: 'Online',
                connectionOffline: 'Offline',
                connectionUnknown: 'Unbekannt',
                connectionSleeping: 'Schläft',
                activityPrefix: 'Aktivität',
                activityIdle: 'In Ruhe',
                activityWorking: 'Arbeitet',
                activityNeedsInput: 'Benötigt Eingabe',
                unreadMessages: _germanUnreadMessages,
                reorderInstruction:
                    'Gedrückt halten und ziehen oder Alt und Pfeiltasten verwenden',
                reorderAnnouncement: _germanReorderAnnouncement,
              ),
            ),
            KText(
              widget.reorderable
                  ? 'Sortieren: gedrückt halten und ziehen oder Alt + '
                        'Pfeiltasten verwenden.'
                  : 'Benutzerdefinierte Inhalte bleiben innerhalb der '
                        'standardisierten Avatarfläche.',
              variant: KTextVariant.bodySmall,
            ),
            Semantics(
              liveRegion: true,
              child: KText(_note, variant: KTextVariant.caption),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, KAgentSwitcherItem> _showcaseItems(KDesignTokens tokens) {
    final connection = widget.showConnections;
    final activity = widget.showActivity;
    final unread = widget.showUnread;
    final colors = widget.customColors;
    return {
      'nova': KAgentSwitcherItem(
        id: 'nova',
        name: 'Nova',
        avatar: const KAvatar(
          alt: 'Nova',
          size: KAvatarSize.large,
          fallback: _AnimatedNovaAvatar(),
        ),
        nameContent: const Text('Nova'),
        statusContent: activity ? const Text('Plant') : null,
        badgeContent: unread ? const Text('VIP') : null,
        semanticLabel: [
          'Nova',
          if (activity) 'plant',
          if (unread) 'VIP',
        ].join(', '),
        connection: connection ? KAgentConnection.online : null,
        activity: activity ? KAgentActivityState.working : null,
        unread: unread ? 3 : null,
        connectionColor: colors ? tokens.colorBrandSecondaryAccent : null,
        statusColor: colors ? tokens.colorBrandSecondaryForeground : null,
        badgeColor: colors ? tokens.colorBrandSecondaryBackground : null,
        badgeForeground: colors ? tokens.colorBrandSecondaryForeground : null,
        selectedColor: colors ? tokens.colorBrandSecondaryAccent : null,
      ),
      'atlas': KAgentSwitcherItem(
        id: 'atlas',
        name: 'Atlas',
        avatar: const KAvatar(
          alt: 'Atlas',
          size: KAvatarSize.large,
          fallback: KIcon(KIconName.bot),
        ),
        connection: connection ? KAgentConnection.offline : null,
        activity: activity ? KAgentActivityState.idle : null,
      ),
      'echo': const KAgentSwitcherItem(
        id: 'echo',
        name: 'Echo',
        avatar: KAvatar(
          alt: 'Echo',
          size: KAvatarSize.large,
          fallback: KIcon(KIconName.audioWaveform),
        ),
        semanticLabel: 'Echo, kompakte Darstellung',
        showName: false,
      ),
      'sage': _standard(
        'sage',
        'Sage',
        connection ? KAgentConnection.unknown : null,
        activity ? KAgentActivityState.needsInput : null,
        unread ? 1 : null,
      ),
      'pixel': _standard(
        'pixel',
        'Pixel',
        connection ? KAgentConnection.online : null,
        activity ? KAgentActivityState.idle : null,
      ),
      'lumen': _standard(
        'lumen',
        'Lumen',
        connection ? KAgentConnection.sleeping : null,
        activity ? KAgentActivityState.idle : null,
      ),
      'orbit': _standard(
        'orbit',
        'Orbit',
        connection ? KAgentConnection.offline : null,
        activity ? KAgentActivityState.idle : null,
      ),
      'quill': _standard(
        'quill',
        'Quill',
        connection ? KAgentConnection.online : null,
        activity ? KAgentActivityState.working : null,
      ),
      'wren': _standard(
        'wren',
        'Wren',
        connection ? KAgentConnection.online : null,
        activity ? KAgentActivityState.idle : null,
      ),
      'iris': _standard(
        'iris',
        'Iris',
        connection ? KAgentConnection.online : null,
        activity ? KAgentActivityState.needsInput : null,
      ),
      'sol': _standard(
        'sol',
        'Sol',
        connection ? KAgentConnection.sleeping : null,
        activity ? KAgentActivityState.idle : null,
      ),
      'moss': _standard(
        'moss',
        'Moss',
        connection ? KAgentConnection.offline : null,
        activity ? KAgentActivityState.idle : null,
      ),
      'coda': _standard(
        'coda',
        'Coda',
        connection ? KAgentConnection.online : null,
        activity ? KAgentActivityState.working : null,
      ),
      'finn': _standard(
        'finn',
        'Finn',
        connection ? KAgentConnection.unknown : null,
        activity ? KAgentActivityState.idle : null,
      ),
    };
  }
}

KAgentSwitcherItem _standard(
  String id,
  String name,
  KAgentConnection? connection,
  KAgentActivityState? activity, [
  int? unread,
]) => KAgentSwitcherItem(
  id: id,
  name: name,
  connection: connection,
  activity: activity,
  unread: unread,
);

class _AnimatedNovaAvatar extends StatefulWidget {
  const _AnimatedNovaAvatar();

  @override
  State<_AnimatedNovaAvatar> createState() => _AnimatedNovaAvatarState();
}

class _AnimatedNovaAvatarState extends State<_AnimatedNovaAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _scale = Tween(
    begin: 0.8,
    end: 1.1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = Theme.of(
      context,
    ).extension<KDesignTokens>()!.motionProgress;
    if (_controller.duration != duration) _controller.duration = duration;
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: const KIcon(KIconName.sparkles));
}

String _germanUnreadMessages(int count) =>
    '$count ${count == 1 ? 'ungelesene Nachricht' : 'ungelesene Nachrichten'}';

String _germanReorderAnnouncement(String name, int position, int count) =>
    '$name ist an Position $position von $count.';
