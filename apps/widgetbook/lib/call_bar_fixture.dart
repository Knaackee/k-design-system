import 'dart:async';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'agent_workspace_avatar.dart';

class CallBarFixture extends StatefulWidget {
  const CallBarFixture({
    this.state = 'listening',
    this.composition = false,
    super.key,
  });
  final String state;
  final bool composition;
  @override
  State<CallBarFixture> createState() => _CallBarFixtureState();
}

class _CallBarFixtureState extends State<CallBarFixture> {
  late bool _muted = widget.state == 'muted';
  bool _expanded = true, _ended = false;
  String? _activity;
  Timer? _timer;
  Timer? _elapsedTimer;
  int _seconds = 0;
  String _draft = '';
  @override
  void initState() {
    super.initState();
    if (widget.composition) {
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !_ended) setState(() => _seconds++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _runActivity(String kind) {
    _timer?.cancel();
    setState(() => _activity = kind);
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    const statuses = {
      'connecting': 'Verbindung wird aufgebaut …',
      'listening': 'Hört zu',
      'speaking': 'Spricht',
      'muted': 'Mikrofon stumm',
      'ending': 'Anruf wird beendet …',
    };
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final bar = KCallBar(
      name: 'Alex',
      status: _ended
          ? 'Anruf beendet'
          : _activity != null
          ? _activity == 'tool'
                ? 'Prüft deinen Kalender'
                : 'Arbeitet mit Mira'
          : _muted
          ? statuses['muted']!
          : statuses[widget.state]!,
      duration: widget.composition
          ? '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}'
          : widget.state == 'connecting'
          ? '00:00'
          : '02:14',
      muted: _muted,
      microphoneLevel: widget.state == 'listening' ? .7 : .15,
      onMutedChanged: _ended || ['connecting', 'ending'].contains(widget.state)
          ? null
          : (value) => setState(() => _muted = value),
      expanded: widget.composition && _expanded && !_ended,
      avatar: widget.composition
          ? AgentWorkspaceAvatar(
              shape: 'squircle',
              color: const Color(0xff8c9cf0),
              status: widget.state == 'speaking' ? 'speaking' : 'idle',
              size: 240,
              label: 'Alex',
            )
          : null,
      onExpandedChanged: widget.composition
          ? (value) => setState(() => _expanded = value)
          : null,
      onEndCall: widget.composition && !_ended
          ? () {
              _timer?.cancel();
              setState(() {
                _ended = true;
                _expanded = false;
              });
            }
          : null,
      regionLabel: 'Anruf',
      durationLabel: 'Anrufdauer',
      muteLabel: 'Mikrofon stummschalten',
      unmuteLabel: 'Mikrofon einschalten',
      minimizeLabel: 'Zum Chat',
      expandLabel: 'Anruf öffnen',
      endLabel: 'Auflegen',
    );
    if (!widget.composition) {
      return Align(alignment: Alignment.topCenter, child: bar);
    }
    final expanded = _expanded && !_ended;
    return ColoredBox(
      color: t.colorSurfaceCanvas,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, bounds) => Stack(
                children: [
                  if (!expanded)
                    Positioned.fill(
                      top: t.sizeIconDefault * 2 + t.spaceControlGap * 2,
                      child: KChatConversation(
                        avatarBuilder: (_, _, _) => null,
                        metadataMode: KChatMessageMetadataMode.hidden,
                        showTimestamps: false,
                        messages: [
                          const KChatMessageValue(
                            id: 'request',
                            role: KChatRole.user,
                            parts: [
                              KChatTextPart(
                                id: 'question',
                                text: 'Was steht heute an?',
                              ),
                            ],
                          ),
                          KChatMessageValue(
                            id: 'reply',
                            role: KChatRole.assistant,
                            parts: [
                              KChatTextPart(
                                id: 'answer',
                                text: _activity == 'delegation'
                                    ? 'Mira prüft die Aufgaben. Du kannst währenddessen weitersprechen.'
                                    : 'Ich schaue in deinen Kalender und sortiere die nächsten Schritte.',
                              ),
                              if (_activity != null)
                                KChatTextPart(
                                  id: 'activity',
                                  text: _activity == 'tool'
                                      ? 'Kalender · Termine werden geladen …'
                                      : 'Mira · Aufgaben werden geprüft …',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : t.motionEmphasis,
                    curve: Curves.easeInOut,
                    height: expanded
                        ? bounds.maxHeight
                        : t.sizeIconDefault * 2 + t.spaceControlGap * 2,
                    child: bar,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.spaceControlGap),
            child: Wrap(
              spacing: t.spaceControlGap,
              runSpacing: t.spaceControlGap,
              alignment: WrapAlignment.center,
              children: [
                KButton(
                  label: 'Tool starten',
                  variant: KButtonVariant.secondary,
                  onPressed: _ended ? null : () => _runActivity('tool'),
                ),
                KButton(
                  label: 'An Mira delegieren',
                  variant: KButtonVariant.secondary,
                  onPressed: _ended ? null : () => _runActivity('delegation'),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(t.spaceLayoutGutter),
            child: KChatComposer(
              value: _draft,
              onValueChanged: (value) => setState(() => _draft = value),
              onSubmit: (_) => setState(() {
                _draft = '';
                _expanded = false;
              }),
              labels: const KChatComposerLabels(
                input: 'Nachricht',
                placeholder: 'Nachricht an Alex …',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
