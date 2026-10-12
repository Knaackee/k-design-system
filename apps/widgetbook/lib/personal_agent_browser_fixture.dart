import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'agent_workspace_avatar.dart';

/// Deterministic session: gallery actions change local state, never transport.
class PersonalAgentBrowserFixture extends StatefulWidget {
  const PersonalAgentBrowserFixture({
    this.scenario = 'review',
    this.fullWidth = false,
    super.key,
  });
  final String scenario;
  final bool fullWidth;

  @override
  State<PersonalAgentBrowserFixture> createState() =>
      _PersonalAgentBrowserFixtureState();
}

class _PersonalAgentBrowserFixtureState
    extends State<PersonalAgentBrowserFixture> {
  late bool _permission = widget.scenario == 'permission';
  late bool _human = widget.scenario == 'human-control';
  late bool _connected = widget.scenario != 'disconnected';
  bool _open = true, _paused = false, _maximized = false;
  String _draft = '', _answer = '';
  final _messages = <String>[];

  String get _status => !_open
      ? 'Browser geschlossen'
      : !_connected
      ? 'Verbindung getrennt'
      : _human
      ? 'Du steuerst'
      : _permission
      ? 'Wartet auf deine Freigabe'
      : _paused
      ? 'Pausiert'
      : 'Agent arbeitet im Browser';
  String get _activity => !_open || !_connected
      ? 'idle'
      : _permission
      ? 'waiting'
      : _paused || _human
      ? 'idle'
      : 'working';

  Widget _avatar(double size) => AgentWorkspaceAvatar(
    shape: 'circle',
    color: Theme.of(context).extension<KDesignTokens>()!.colorStatusInfoAccent,
    status: _activity,
    size: size,
    label: 'Nova · $_status',
  );

  void _decide(String answer, {bool human = false}) => setState(() {
    _permission = false;
    _answer = answer;
    _human = human;
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Scaffold(
      backgroundColor: t.colorSurfaceCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maximized = _maximized;
            final height = maximized
                ? constraints.maxHeight
                : math.min(360.0, constraints.maxHeight * .45);
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maximized || widget.fullWidth
                      ? double.infinity
                      : 920,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!maximized)
                      Padding(
                        padding: EdgeInsets.all(t.spaceControlGap),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              children: [
                                _avatar(constraints.maxWidth <= 600 ? 80 : 104),
                                const KText(
                                  'Nova',
                                  variant: KTextVariant.heading4,
                                ),
                                KText(_status, variant: KTextVariant.caption),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: KIconButton(
                                label: 'Freigabe simulieren',
                                icon: KIconName.shieldQuestionMark,
                                onPressed: _open && _connected
                                    ? () => setState(() {
                                        _permission = true;
                                        _maximized = false;
                                        _answer = '';
                                      })
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!maximized)
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('personal-browser-chat'),
                          padding: EdgeInsets.all(t.spaceLayoutGutter),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: t.spaceControlGap * 2,
                            children: [
                              const KText(
                                'Du · Finde ein ruhiges Hotel in Berlin.',
                              ),
                              const KText(
                                'Nova · Ich vergleiche Lage und Verfügbarkeit. Du kannst meinen Browser hier verfolgen.',
                              ),
                              if (_permission && _open)
                                KSurface(
                                  tone: KSurfaceTone.raised,
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      t.spaceControlGap * 2,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      spacing: t.spaceControlGap,
                                      children: [
                                        const KText(
                                          'Formulardaten senden?',
                                          variant: KTextVariant.heading4,
                                        ),
                                        const KText(
                                          'stay.example · /hotels/search · Suchdaten senden. Normale Navigation benötigt keine Freigabe.',
                                        ),
                                        Wrap(
                                          spacing: t.spaceControlGap,
                                          runSpacing: t.spaceControlGap,
                                          children: [
                                            KButton(
                                              label: 'Einmal erlauben',
                                              onPressed: () =>
                                                  _decide('Einmal erlaubt'),
                                            ),
                                            KButton(
                                              label: 'Erlauben und merken',
                                              variant: KButtonVariant.secondary,
                                              onPressed: () => _decide(
                                                'Freigabe gespeichert',
                                              ),
                                            ),
                                            KButton(
                                              label: 'Immer fragen',
                                              variant: KButtonVariant.secondary,
                                              onPressed: () => setState(
                                                () => _answer =
                                                    'Diese Aktion wartet weiterhin auf deine Entscheidung.',
                                              ),
                                            ),
                                            KButton(
                                              label: 'Blockieren',
                                              variant: KButtonVariant.secondary,
                                              onPressed: () =>
                                                  _decide('Blockiert'),
                                            ),
                                            KButton(
                                              label: 'Browser übernehmen',
                                              variant: KButtonVariant.secondary,
                                              onPressed: () => _decide(
                                                'Du führst die Aktion aus',
                                                human: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_answer.isNotEmpty) KText(_answer),
                              for (final message in _messages) KText(message),
                            ],
                          ),
                        ),
                      ),
                    if (_open)
                      KBrowserViewer(
                        key: const ValueKey('personal-browser-viewer'),
                        height: height,
                        status: _status,
                        permissionPending: _permission,
                        connected: _connected,
                        humanControl: _human,
                        paused: _paused,
                        working: _activity == 'working',
                        maximized: maximized,
                        onMaximizedChanged: (value) =>
                            setState(() => _maximized = value),
                        onTakeControl: () => setState(() => _human = !_human),
                        onPause: () => setState(() => _paused = !_paused),
                        onStop: () => setState(() {
                          _paused = true;
                          _permission = false;
                          _human = false;
                        }),
                        onReconnect: () => setState(() => _connected = true),
                        onClose: () => setState(() {
                          _open = false;
                          _maximized = false;
                          _permission = false;
                          _human = false;
                          _paused = true;
                        }),
                        cursor: const Offset(.40, .60),
                        cursorState: KAgentCursorState.clicking,
                        cursorAvatar: _avatar(48),
                        child: _SimulatedHotelPage(
                          onChoose: () => setState(
                            () => _answer = 'Zimmer im Browser ausgewählt',
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KButton(
                          label: 'Browser öffnen',
                          variant: KButtonVariant.ghost,
                          leading: const KIcon(KIconName.globe),
                          onPressed: () => setState(() {
                            _open = true;
                            _paused = false;
                          }),
                        ),
                      ),
                    if (!maximized)
                      KChatComposer(
                        labels: const KChatComposerLabels(
                          input: 'Nachricht',
                          placeholder: 'Nachricht…',
                          send: 'Nachricht senden',
                        ),
                        value: _draft,
                        onValueChanged: (value) =>
                            setState(() => _draft = value),
                        onSubmit: (value) => setState(() {
                          _messages.add('Du · $value');
                          _messages.add('Nova · Nachricht angekommen.');
                          _draft = '';
                        }),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SimulatedHotelPage extends StatelessWidget {
  const _SimulatedHotelPage({required this.onChoose});
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 960,
        height: 540,
        child: ColoredBox(
          color: t.colorSurfaceRaised,
          child: Padding(
            padding: EdgeInsets.all(t.spaceControlGap * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KText(
                  'stay.example / hotels / berlin',
                  variant: KTextVariant.caption,
                  style: TextStyle(color: t.colorTextMuted),
                ),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: t.spaceLayoutGutter,
                      runSpacing: t.spaceControlGap,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const KIcon(KIconName.hotel, size: 40),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            KText(
                              'Ein ruhiger Ort in Berlin',
                              variant: KTextVariant.heading4,
                            ),
                            KText('Gartenblick · Frühstück · Ab 129 €'),
                          ],
                        ),
                        KButton(label: 'Zimmer ansehen', onPressed: onChoose),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
