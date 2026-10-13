import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

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

class _CallBarFixtureState extends State<CallBarFixture>
    with SingleTickerProviderStateMixin {
  late bool _muted = widget.state == 'muted';
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  @override
  void initState() {
    super.initState();
    if (widget.state == 'speaking') _motion.repeat(reverse: true);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
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
    final bar = KCallBar(
      name: 'Alex',
      status: _muted ? statuses['muted']! : statuses[widget.state]!,
      duration: widget.state == 'connecting' ? '00:00' : '02:14',
      muted: _muted,
      microphoneLevel: widget.state == 'listening' ? .7 : .15,
      onMutedChanged: ['connecting', 'ending'].contains(widget.state)
          ? null
          : (value) => setState(() => _muted = value),
      regionLabel: 'Anruf',
      durationLabel: 'Anrufdauer',
      muteLabel: 'Mikrofon stummschalten',
      unmuteLabel: 'Mikrofon einschalten',
    );
    if (!widget.composition) {
      return Align(alignment: Alignment.topCenter, child: bar);
    }
    return KAgentChatWorkspace(
      title: const Text('Alex'),
      avatarLabel: const Text('Alex'),
      avatar: AnimatedBuilder(
        animation: _motion,
        builder: (_, child) => Transform.scale(
          scaleY: MediaQuery.disableAnimationsOf(context)
              ? 1
              : 1 - .06 * _motion.value,
          child: child,
        ),
        child: const KIcon(KIconName.bot, size: 96),
      ),
      defaultSidebarCollapsed: true,
      sidebar: const Text('Persönliche Agenten'),
      conversationHeader: bar,
      actions: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          KIconButton(
            icon: KIconName.phoneOff,
            label: 'Auflegen',
            onPressed: () {},
          ),
        ],
      ),
      conversation: KChatConversation(
        avatarBuilder: (_, _, _) => null,
        metadataMode: KChatMessageMetadataMode.hidden,
        showTimestamps: false,
        messages: [
          for (var i = 0; i < 12; i++)
            KChatMessageValue(
              id: '$i',
              role: i.isEven ? KChatRole.user : KChatRole.assistant,
              parts: [
                KChatTextPart(
                  id: 'text-$i',
                  text: i.isEven
                      ? 'Was steht heute an?'
                      : 'Ich schaue mir die Aufgabe an.',
                ),
              ],
            ),
        ],
      ),
      composer: KChatComposer(
        value: '',
        onValueChanged: (_) {},
        onSubmit: (_) {},
        labels: const KChatComposerLabels(
          input: 'Nachricht',
          placeholder: 'Nachricht …',
        ),
      ),
    );
  }
}
