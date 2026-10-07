import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class AgentChatSwitcherFixture extends StatefulWidget {
  const AgentChatSwitcherFixture({super.key});

  @override
  State<AgentChatSwitcherFixture> createState() =>
      _AgentChatSwitcherFixtureState();
}

class _AgentChatSwitcherFixtureState extends State<AgentChatSwitcherFixture> {
  static const _labels = KAgentSwitcherLabels(
    agents: 'Persönliche Agenten',
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
        'Lange drücken und ziehen oder Alt und Pfeiltasten verwenden',
    reorderAnnouncement: _germanReorderAnnouncement,
  );
  static const _agents = [
    KAgentSwitcherItem(
      id: 'ada',
      name: 'Ada',
      avatar: KAvatar(
        alt: 'Ada',
        size: KAvatarSize.large,
        fallback: Text('🧭'),
      ),
      connection: KAgentConnection.online,
      activity: KAgentActivityState.working,
      unread: 2,
    ),
    KAgentSwitcherItem(
      id: 'linus',
      name: 'Linus',
      avatar: KAvatar(
        alt: 'Linus',
        size: KAvatarSize.large,
        fallback: Text('🌙'),
      ),
      connection: KAgentConnection.sleeping,
      activity: KAgentActivityState.idle,
    ),
    KAgentSwitcherItem(
      id: 'mira',
      name: 'Mira',
      avatar: KAvatar(
        alt: 'Mira',
        size: KAvatarSize.large,
        fallback: Text('✨'),
      ),
      connection: KAgentConnection.online,
      activity: KAgentActivityState.needsInput,
      unread: 1,
    ),
  ];

  final _drafts = <String, String>{
    'ada': 'Ergänze danach bitte die mobilen Zustände.',
    'linus': '',
    'mira': 'Nimm die kurze Zusammenfassung.',
  };
  final _activityByAgent = <String, KAgentActivityState>{
    'ada': KAgentActivityState.working,
    'linus': KAgentActivityState.idle,
    'mira': KAgentActivityState.needsInput,
  };
  final _messagesByAgent = <String, List<KChatMessageValue>>{
    'ada': [
      const KChatMessageValue(
        id: 'ada-user',
        role: KChatRole.user,
        authorLabel: 'Du',
        parts: [
          KChatTextPart(
            id: 'ada-user-text',
            text: 'Prüfe bitte den aktuellen Web-Build.',
          ),
        ],
      ),
      const KChatMessageValue(
        id: 'ada-agent',
        role: KChatRole.assistant,
        authorLabel: 'Ada',
        parts: [
          KChatTextPart(
            id: 'ada-agent-text',
            text: 'Ich prüfe gerade Komponenten und Tastaturbedienung.',
          ),
        ],
      ),
    ],
    'linus': [
      const KChatMessageValue(
        id: 'linus-agent',
        role: KChatRole.assistant,
        authorLabel: 'Linus',
        parts: [
          KChatTextPart(
            id: 'linus-agent-text',
            text: 'Die letzte Analyse ist abgeschlossen. Ich bin im Ruhemodus.',
          ),
        ],
      ),
    ],
    'mira': [
      const KChatMessageValue(
        id: 'mira-agent',
        role: KChatRole.assistant,
        authorLabel: 'Mira',
        parts: [
          KChatTextPart(
            id: 'mira-agent-text',
            text:
                'Soll ich die kurze oder die ausführliche Zusammenfassung vorbereiten?',
          ),
        ],
      ),
    ],
  };
  String _selectedId = 'ada';
  String _manageNote = '';

  List<KAgentSwitcherItem> get _visibleAgents => [
    for (final agent in _agents)
      KAgentSwitcherItem(
        id: agent.id,
        name: agent.name,
        avatar: agent.avatar,
        connection: agent.connection,
        activity: _activityByAgent[agent.id]!,
        unread: agent.unread,
      ),
  ];

  KAgentSwitcherItem get _selected =>
      _visibleAgents.firstWhere((agent) => agent.id == _selectedId);

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final selected = _selected;
    final runState = selected.activity == KAgentActivityState.working
        ? KChatRunState.streaming
        : KChatRunState.awaitingInput;
    return SizedBox.expand(
      child: ColoredBox(
        color: tokens.colorSurfaceCanvas,
        child: Column(
          children: [
            KAgentSwitcher(
              items: _visibleAgents,
              selectedId: selected.id,
              onSelect: (id) => setState(() {
                _selectedId = id;
                _manageNote = '';
              }),
              onManage: () => setState(
                () => _manageNote = 'Agentenauswahl geöffnet (Demo)',
              ),
              labels: _labels,
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceLayoutGutter,
                vertical: tokens.spaceControlGap,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tokens.colorBorderDefault,
                    width: tokens.borderWidthDefault,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: KText(
                      'Demodaten · keine echten Agenten oder Arbeitsläufe',
                      variant: KTextVariant.bodySmall,
                    ),
                  ),
                  SizedBox(width: tokens.spaceControlGap),
                  Semantics(
                    liveRegion: true,
                    child: KText(
                      _manageNote.isEmpty
                          ? 'Chat mit ${selected.name}'
                          : _manageNote,
                      variant: KTextVariant.caption,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: KChatConversation(
                    messages: _messagesByAgent[selected.id]!,
                    runState: runState,
                    metadataMode: KChatMessageMetadataMode.grouped,
                    showTimestamps: false,
                    labels: KChatLabels(assistant: selected.name, user: 'Du'),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: KChatComposer(
                key: ValueKey('agent-composer-${selected.id}'),
                value: _drafts[selected.id]!,
                runState: runState,
                onValueChanged: (value) =>
                    setState(() => _drafts[selected.id] = value),
                onSubmit: _send,
                onStop: () => setState(
                  () =>
                      _activityByAgent[selected.id] = KAgentActivityState.idle,
                ),
                labels: KChatComposerLabels(
                  placeholder: 'Nachricht an ${selected.name}…',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send(String value) {
    final message = value.trim();
    if (message.isEmpty) return;
    final id = _selectedId;
    setState(() {
      _messagesByAgent[id]!.add(
        KChatMessageValue(
          id: '$id-user-${_messagesByAgent[id]!.length}',
          role: KChatRole.user,
          authorLabel: 'Du',
          parts: [
            KChatTextPart(
              id: '$id-text-${_messagesByAgent[id]!.length}',
              text: message,
            ),
          ],
        ),
      );
      _drafts[id] = '';
    });
  }
}

String _germanUnreadMessages(int count) =>
    '$count ${count == 1 ? 'ungelesene Nachricht' : 'ungelesene Nachrichten'}';

String _germanReorderAnnouncement(String name, int position, int count) =>
    '$name auf Position $position von $count verschoben';
