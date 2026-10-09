import 'agent_workspace_usage.dart';
import 'agent_workspace_details.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'agent_workspace_avatar.dart';
part 'agent_workspace_demo_agents.dart';

enum AgentChatWorkspaceFixtureKind { fullScreen, needsInput, offline, mobile }

abstract final class AgentChatWorkspaceFixtureNames {
  static const fullScreen = 'Fullscreen';
  static const needsInput = 'NeedsInput';
  static const offline = 'Offline';
  static const mobile = 'Mobile';
  static const all = [fullScreen, needsInput, offline, mobile];
}

class AgentChatWorkspaceFixture extends StatefulWidget {
  const AgentChatWorkspaceFixture({
    this.kind = AgentChatWorkspaceFixtureKind.fullScreen,
    super.key,
  });

  final AgentChatWorkspaceFixtureKind kind;

  @override
  State<AgentChatWorkspaceFixture> createState() =>
      _AgentChatWorkspaceFixtureState();
}

class _AgentChatWorkspaceFixtureState extends State<AgentChatWorkspaceFixture> {
  late List<_DemoAgent> _agents;
  late String _selectedAgent;
  final _selectedSession = <String, String>{};
  final _drafts = <String, String>{};
  final _messages = <String, List<KChatMessageValue>>{};
  final _sessionLists = <String, List<String>>{};
  final _attachments = <String, List<KChatAttachmentPart>>{};
  String? _voiceKey;
  bool _rightSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _agents = [..._demoAgents];
    _selectedAgent = switch (widget.kind) {
      AgentChatWorkspaceFixtureKind.needsInput => 'mira',
      AgentChatWorkspaceFixtureKind.offline => 'pi',
      _ => 'ada',
    };
  }

  _DemoAgent get _agent =>
      _agents.firstWhere((agent) => agent.id == _selectedAgent);

  String get _session =>
      _selectedSession[_selectedAgent] ?? _sessionNames.first;

  String get _draftKey => '$_selectedAgent/$_session';

  @override
  Widget build(BuildContext context) {
    final workspace = KAgentChatWorkspace(
      conversationEmpty: _messagesFor(_draftKey).isEmpty,
      avatarTransitionDuration: const Duration(milliseconds: 550),
      labels: const KAgentChatWorkspaceLabels(
        agents: 'Agenten',
        closeAgents: 'Agenten schließen',
      ),
      sidebarBuilder: (context, controls) => _sidebar(controls.close),
      avatar: AgentWorkspaceAvatar(
        key: ValueKey('workspace-avatar-${_agent.id}'),
        shape: _agent.shape,
        color: _agent.color,
        status: _agent.avatarStatus,
        label: _agent.name,
      ),
      title: Text(_agent.name),
      avatarLabel: Text(_agent.name),
      avatarPopover: const AgentWorkspaceUsage(),
      avatarPopoverLabel: '${_agent.name}: Zugang und Kontingente',
      rightSidebar: const AgentWorkspaceDetails(),
      rightSidebarTitle: 'Kontext',
      rightSidebarOpen: _rightSidebarOpen,
      onRightSidebarOpenChange: (open) =>
          setState(() => _rightSidebarOpen = open),
      status: _agent.status == 'Bereit' || _agent.status == 'In Ruhe'
          ? null
          : Text('${_agent.status} · $_session'),
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Center(
              child: KSelect(
                textAlign: TextAlign.center,
                presentation: KSelectPresentation.inline,
                label: 'Letzte Sessions',
                optionsLabel: 'Letzte Sessions',
                value: _session,
                options: [
                  for (final session
                      in _sessionLists[_selectedAgent] ?? _sessionNames)
                    KSelectOption(value: session, label: session),
                ],
                onChanged: (session) {
                  if (session != null) {
                    setState(() {
                      _selectedSession[_selectedAgent] = session;
                      _voiceKey = null;
                    });
                  }
                },
              ),
            ),
          ),
          KIconButton(
            icon: KIconName.plus,
            label: 'Neue Session',
            onPressed: () => setState(() {
              final sessions =
                  _sessionLists[_selectedAgent] ?? [..._sessionNames];
              final name = 'Neue Session ${sessions.length - 1}';
              _sessionLists[_selectedAgent] = [name, ...sessions];
              _selectedSession[_selectedAgent] = name;
              _messages[_draftKey] = [];
              _voiceKey = null;
            }),
          ),
          KIconButton(
            icon: KIconName.info,
            label: 'Kontext',
            onPressed: () =>
                setState(() => _rightSidebarOpen = !_rightSidebarOpen),
          ),
        ],
      ),
      conversation: KChatConversation(
        emptyState: const SizedBox.shrink(),
        contentPadding: const EdgeInsets.fromLTRB(16, 144, 16, 16),
        key: ValueKey('conversation-$_draftKey'),
        messages: _messagesFor(_draftKey),
        runState: _agent.runState,
        metadataMode: KChatMessageMetadataMode.hidden,
        showTimestamps: false,
        labels: const KChatLabels(
          assistant: 'Agent',
          user: 'Du',
          emptyTitle: 'Noch keine Demo-Nachrichten',
          emptyDescription: 'Schreibe eine lokale Vorschau-Nachricht.',
        ),
      ),
      composer: KChatComposer(
        key: ValueKey('composer-$_draftKey'),
        value: _drafts[_draftKey] ?? '',
        disabled: _agent.connection == KAgentConnection.offline,
        runState: _agent.runState,
        onValueChanged: (value) => setState(() => _drafts[_draftKey] = value),
        onSubmit: _submit,
        attachments: _attachments[_draftKey] ?? [],
        leadingTools: [
          KMenuButton(
            label: 'Anhängen',
            triggerContent: const KIcon(KIconName.paperclip),
            actions: [
              KMenuAction(
                id: 'image',
                label: 'Bild auswählen',
                icon: KIconName.image,
                onSelect: () => _addAttachment('Bild.jpg', 'image/jpeg'),
              ),
              KMenuAction(
                id: 'camera',
                label: 'Neues Bild aufnehmen',
                icon: KIconName.camera,
                onSelect: () => _addAttachment('Aufnahme.jpg', 'image/jpeg'),
              ),
              KMenuAction(
                id: 'document',
                label: 'Dokument auswählen',
                icon: KIconName.file,
                onSelect: () =>
                    _addAttachment('Projektbrief.pdf', 'application/pdf'),
              ),
            ],
          ),
        ],
        onAttachmentRemove: (file) => setState(
          () => _attachments[_draftKey]?.removeWhere(
            (item) => item.id == file.id,
          ),
        ),
        voiceActive: _voiceKey == _draftKey,
        onVoiceInput: () => setState(
          () => _voiceKey = _voiceKey == _draftKey ? null : _draftKey,
        ),
        labels: const KChatComposerLabels(
          input: 'Demo-Nachricht',
          placeholder: 'Lokale Vorschau schreiben…',
          send: 'Demo-Nachricht senden',
          attach: 'Datei anhängen (Demo)',
          removeAttachment: 'Anhang entfernen',
          voice: 'Audio starten (Demo)',
          stopVoice: 'Audio stoppen (Demo)',
        ),
      ),
    );
    if (widget.kind != AgentChatWorkspaceFixtureKind.mobile) return workspace;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: math.min(390, constraints.maxWidth),
          height: constraints.maxHeight,
          child: workspace,
        ),
      ),
    );
  }

  Widget _sidebar(VoidCallback closeDrawer) => KSidebar(
    mode: KSidebarMode.expanded,
    expandedWidth: KAgentChatWorkspace.desktopSidebarWidth,
    semanticLabel: 'Agenten und Gespräche',
    child: Column(
      children: [
        Expanded(
          child: KAgentSwitcher(
            orientation: Axis.vertical,
            items: [for (final agent in _agents) agent.switcherItem],
            selectedId: _selectedAgent,
            onSelect: (id) {
              setState(() => _selectedAgent = id);
              closeDrawer();
            },
            onReorder: (ids) => setState(() {
              final byId = {for (final agent in _agents) agent.id: agent};
              _agents = [for (final id in ids) byId[id]!];
            }),
            labels: const KAgentSwitcherLabels(
              agents: 'Agenten',
              connectionPrefix: 'Verbindung',
              connectionOnline: 'Online',
              connectionOffline: 'Offline',
              connectionUnknown: 'Unbekannt',
              connectionSleeping: 'Ruhezustand',
              activityPrefix: 'Status',
              activityIdle: 'Bereit',
              activityWorking: 'Arbeitet',
              activityNeedsInput: 'Eingabe nötig',
              unreadMessages: _germanUnreadMessages,
              reorderInstruction:
                  '450 ms halten und ziehen oder Alt plus Pfeiltaste verwenden',
              reorderAnnouncement: _germanReorderAnnouncement,
            ),
          ),
        ),
      ],
    ),
  );

  List<KChatMessageValue> _messagesFor(String key) =>
      _messages.putIfAbsent(key, () => _initialMessages(_agent, _session));

  void _addAttachment(String title, String mediaType) => setState(
    () => _attachments
        .putIfAbsent(_draftKey, () => [])
        .add(
          KChatAttachmentPart(
            id: 'file-${DateTime.now().microsecondsSinceEpoch}',
            title: title,
            description: 'Demo-Anhang · nur Vorschau',
            mediaType: mediaType,
          ),
        ),
  );

  void _submit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    final key = _draftKey;
    setState(() {
      _messagesFor(key).addAll([
        KChatMessageValue(
          id: 'demo-user-${_messagesFor(key).length}',
          role: KChatRole.user,
          parts: [
            KChatTextPart(
              id: 'text-user-${_messagesFor(key).length}',
              text: text,
            ),
          ],
        ),
        KChatMessageValue(
          id: 'demo-agent-${_messagesFor(key).length}',
          role: KChatRole.assistant,
          parts: [
            KChatTextPart(
              id: 'text-agent-${_messagesFor(key).length}',
              text:
                  'Demo-Antwort: Diese Nachricht bleibt nur in der Widgetbook-Vorschau.',
            ),
          ],
        ),
      ]);
      _drafts[key] = '';
    });
  }
}

const _sessionNames = ['Aktuelles Gespräch', 'Release vorbereiten'];

String _germanUnreadMessages(int count) =>
    '$count ungelesene ${count == 1 ? 'Nachricht' : 'Nachrichten'}';

String _germanReorderAnnouncement(String name, int position, int count) =>
    '$name wurde an Position $position von $count verschoben';

const _demoConversation = <(KChatRole, String)>[
  (KChatRole.user, 'Was müssen wir vor der Freitagsvorschau prüfen?'),
  (
    KChatRole.assistant,
    '''Wir sollten die Vorschau an drei konkreten Aufgaben prüfen: ein Gespräch beginnen, zwischen zwei Agenten wechseln und eine laufende Antwort stoppen. Für jede Aufgabe halten wir fest, was die Person sehen und tun können muss.

1. Öffne die Agentenliste und wähle eine andere Person aus. Der Entwurf des bisherigen Gesprächs bleibt erhalten.
2. Schreibe eine kurze Nachricht und danach einen längeren Absatz. Die Eingabe darf die Antwortgeschichte nicht verdecken.
3. Öffne die Tastatur, scrolle zu einer früheren Antwort und kehre zur neuesten Nachricht zurück.
4. Trenne die Verbindung. Die Oberfläche erklärt den Zustand, ohne einen erfolgreichen Versand vorzutäuschen.

Für die Abnahme brauchen wir zusätzlich ein schmales Telefon und ein Tablet. Ein einzelnes Bildschirmfoto zeigt die Abstände, aber erst das Scrollen macht sichtbar, ob Avatar, Text und Eingabe dauerhaft zusammenpassen.''',
  ),
  (KChatRole.user, 'Beginne am Telefon. Der Avatar darf nichts verdecken.'),
  (
    KChatRole.assistant,
    '''Ja. Der Avatar liegt als kleine Ebene über dem Gespräch. Am Anfang gibt es etwas Abstand innerhalb des scrollbaren Verlaufs. Dieser Abstand verschwindet beim Scrollen mit den Nachrichten; er verkleinert den verfügbaren Bereich nicht dauerhaft.

Wenn die Tastatur erscheint, wird der Avatar kleiner. Die Gesprächsauswahl, die Schaltfläche für ein neues Gespräch und das Schließen bleiben erreichbar. Lange Namen kürzen wir sichtbar ab, während die vollständige Bezeichnung für assistive Technologien erhalten bleibt.''',
  ),
  (KChatRole.user, 'Wie prüfe ich die getrennten Entwürfe?'),
  (
    KChatRole.assistant,
    '''Ein kurzer Test reicht:

- Schreibe bei Ada „Termin am Donnerstag“ und sende noch nicht.
- Wechsle zu Linus und schreibe „Build prüfen“.
- Kehre zu Ada zurück. Dort muss wieder „Termin am Donnerstag“ stehen.
- Öffne bei Ada ein neues Gespräch. Dieses beginnt mit einer leeren Eingabe.
- Wähle das erste Gespräch erneut. Sein bisheriger Entwurf erscheint wieder.

Die Vorschau verwendet ausschließlich lokale Beispieldaten. Es werden keine echten Agenten angeschrieben und keine Änderungen an einer produktiven Unterhaltung gespeichert.''',
  ),
  (KChatRole.user, 'Ergänze einen kurzen Rückblick für Freitag.'),
  (
    KChatRole.assistant,
    '''**Rückblick für die Vorschau**

Die wichtigsten Wege sind jetzt beschrieben: Auswahl, getrennte Entwürfe, Senden, Stoppen und die Rückkehr zu früheren Nachrichten. Offen bleibt die visuelle Prüfung auf beiden Geräten mit eingeblendeter Tastatur, langen Antworten und wechselnder Verbindung.

Für den nächsten Durchgang nehmen wir genau diesen längeren Beispielverlauf. Wir lesen eine ältere Liste, scrollen wieder nach unten und schreiben eine neue Nachricht. So prüfen wir die Oberfläche im tatsächlichen Gebrauch statt nur im leeren Zustand.

Die Reihenfolge für Freitag lautet: erst die Geräteprüfung abschließen, dann die gefundenen Abstandsprobleme korrigieren und zuletzt die gemeinsam geprüfte Vorschau freigeben.''',
  ),
];
List<KChatMessageValue> _initialMessages(_DemoAgent agent, String session) => [
  KChatMessageValue(
    id: 'demo-${agent.id}-$session-user',
    role: KChatRole.user,
    parts: [
      KChatTextPart(
        id: 'demo-${agent.id}-$session-user-text',
        text: 'Hilf mir bitte beim nächsten Schritt, ${agent.name}.',
      ),
    ],
  ),
  KChatMessageValue(
    id: 'demo-${agent.id}-$session-assistant',
    role: KChatRole.assistant,
    parts: [
      KChatTextPart(
        id: 'demo-${agent.id}-$session-assistant-text',
        text: agent.demoReply,
      ),
    ],
  ),
  for (final (index, (role, text)) in _demoConversation.indexed)
    KChatMessageValue(
      id: 'demo-${agent.id}-$session-continued-$index',
      role: role,
      parts: [KChatTextPart(id: 'continued-$index-text', text: text)],
    ),
];

class _DemoAgent {
  const _DemoAgent({
    required this.id,
    required this.name,
    required this.shape,
    required this.color,
    required this.status,
    required this.connection,
    required this.activity,
    required this.avatarStatus,
  });

  final String id;
  final String name;
  final String shape;
  final Color color;
  final String status;
  final KAgentConnection connection;
  final KAgentActivityState activity;
  final String avatarStatus;

  String get demoReply => switch (id) {
    'mira' =>
      'Soll ich zuerst die mobile Ansicht oder die Tastaturbedienung prüfen?',
    'pi' =>
      'Die lokale Verbindung ist unterbrochen. Entwürfe bleiben auf diesem Gerät erhalten.',
    _ => 'Ich habe den Kontext und bereite einen klaren nächsten Schritt vor.',
  };

  KChatRunState get runState => switch (activity) {
    KAgentActivityState.working => KChatRunState.streaming,
    KAgentActivityState.needsInput => KChatRunState.awaitingInput,
    KAgentActivityState.idle => KChatRunState.idle,
  };

  KAgentSwitcherItem get switcherItem => KAgentSwitcherItem(
    id: id,
    name: name,
    avatar: _RosterAvatar(shape: shape, color: color, name: name),
    unread: id == 'mira' ? 1 : null,
    connection: connection,
    activity: activity,
    statusContent: Text(status),
  );
}

class _RosterAvatar extends StatelessWidget {
  const _RosterAvatar({
    required this.shape,
    required this.color,
    required this.name,
  });

  final String shape;
  final Color color;
  final String name;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Transform.scale(
      scaleX: shape == 'capsule' ? .78 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            shape == 'star' ? '★' : name.substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
