import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

class ChatBubbleFixture extends StatefulWidget {
  const ChatBubbleFixture({this.customContent = false, super.key});
  final bool customContent;
  @override
  State<ChatBubbleFixture> createState() => _ChatBubbleFixtureState();
}

class _ChatBubbleFixtureState extends State<ChatBubbleFixture> {
  int count = 0;
  int sequence = 0;
  List<KFabAttention> attention = [];

  void signal(String itemId) => setState(() {
    sequence++;
    attention = [
      ...attention.where((notice) => notice.itemId != itemId),
      KFabAttention(id: '$itemId-$sequence', itemId: itemId),
    ];
  });

  @override
  Widget build(BuildContext context) {
    final longPress = context.knobs.boolean(
      label: 'Longpress-Modus',
      initialValue: true,
    );
    final peekFraction = context.knobs.double.slider(
      label: 'Hinweis-Höhenanteil',
      initialValue: .5,
      min: 0,
      max: 1,
      divisions: 20,
    );
    final itemGap = context.knobs.double.slider(
      label: 'Abstand zwischen Bubbles (px)',
      initialValue: 8,
      min: 0,
      max: 32,
      divisions: 16,
    );
    final holdMs = context.knobs.double.slider(
      label: 'Hinweis-Haltedauer (ms)',
      initialValue: 324,
      min: 0,
      max: 2000,
      divisions: 20,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  KButton(
                    onPressed: () => signal('bubble-0'),
                    label: 'Stern anstupsen',
                    variant: KButtonVariant.secondary,
                  ),
                  KButton(
                    onPressed: () => signal('bubble-1'),
                    label: 'Herz anstupsen',
                    variant: KButtonVariant.secondary,
                  ),
                  KButton(
                    onPressed: () => setState(() => attention = []),
                    label: 'Alle bestätigen',
                    variant: KButtonVariant.ghost,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('${attention.length} offene Hinweise'),
              Text(
                count == 0
                    ? (longPress
                          ? 'Kurz drücken: Hauptaktion. Lange drücken: weitere Bubbles.'
                          : 'Kurz drücken: weitere Bubbles.')
                    : 'Aktion ausgelöst: $count',
              ),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: KFab(
            activation: longPress
                ? KFabActivation.longPress
                : KFabActivation.press,
            attention: attention,
            itemGap: itemGap,
            attentionPeekFraction: peekFraction,
            attentionHoldDuration: Duration(milliseconds: holdMs.round()),
            onAttentionSelect: (notice) => setState(
              () => attention = attention
                  .where((entry) => entry.id != notice.id)
                  .toList(),
            ),
            items: [
              for (var i = 0; i < 3; i++)
                KFabItem(
                  id: 'bubble-$i',
                  label: 'Bubble ${i + 1}',
                  child: KIcon(
                    [KIconName.star, KIconName.heart, KIconName.sparkles][i],
                    size: 28,
                  ),
                  onSelected: () => setState(() => count = i + 1),
                ),
            ],
            label: 'Chat öffnen',
            onPressed: () => setState(() => count++),
            child: widget.customContent
                ? const Text('✦', style: TextStyle(fontSize: 28))
                : const KIcon(KIconName.messageCircle, size: 28),
          ),
        ),
      ],
    );
  }
}
