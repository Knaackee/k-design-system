import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Gallery-only controls for reviewing an opt-in event-to-cue mapping.
class FoleyEventPreview extends StatelessWidget {
  const FoleyEventPreview({
    required this.enabled,
    required this.chat,
    required this.tools,
    required this.onEnabledChanged,
    required this.onChatChanged,
    required this.onToolsChanged,
    required this.onEvent,
    required this.status,
    super.key,
  });
  final bool enabled, chat, tools;
  final ValueChanged<bool> onEnabledChanged, onChatChanged, onToolsChanged;
  final void Function(String category, String cue, String message) onEvent;
  final String status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final gap = t.spaceCardPadding;
    Widget toggle(String label, bool value, ValueChanged<bool>? onChanged) =>
        Row(
          children: [
            Expanded(child: KText(label, variant: KTextVariant.label)),
            SizedBox(width: t.spaceControlGap),
            KSwitch(label: label, value: value, onChanged: onChanged),
          ],
        );
    return KSurface(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const KText('Ereignistöne', variant: KTextVariant.heading4),
            SizedBox(height: gap),
            const KText(
              'Feedback für Chat und Tool-Aktivitäten. Jederzeit abschaltbar.',
              variant: KTextVariant.bodySmall,
            ),
            SizedBox(height: gap),
            LayoutBuilder(
              builder: (context, constraints) {
                final controls = [
                  toggle('Ereignistöne aktivieren', enabled, onEnabledChanged),
                  toggle('Chat', chat, enabled ? onChatChanged : null),
                  toggle(
                    'Tool-Aktivitäten',
                    tools,
                    enabled ? onToolsChanged : null,
                  ),
                ];
                return constraints.maxWidth > 600
                    ? Row(
                        children: [
                          for (var i = 0; i < controls.length; i++) ...[
                            if (i > 0) SizedBox(width: gap),
                            Expanded(child: controls[i]),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < controls.length; i++) ...[
                            if (i > 0) SizedBox(height: t.spaceControlGap),
                            controls[i],
                          ],
                        ],
                      );
              },
            ),
            SizedBox(height: gap),
            Wrap(
              spacing: t.spaceControlGap,
              runSpacing: t.spaceControlGap,
              children: [
                KButton(
                  label: 'Nachricht empfangen',
                  variant: KButtonVariant.secondary,
                  onPressed: () =>
                      onEvent('chat', 'bubble', 'Nachricht empfangen.'),
                ),
                KButton(
                  label: 'Rückfrage',
                  variant: KButtonVariant.secondary,
                  onPressed: () =>
                      onEvent('chat', 'warning', 'Rückfrage gestellt.'),
                ),
                KButton(
                  label: 'Suche abgeschlossen',
                  variant: KButtonVariant.secondary,
                  onPressed: () =>
                      onEvent('tools', 'ready', 'Suche abgeschlossen.'),
                ),
                KButton(
                  label: 'Suche fehlgeschlagen',
                  variant: KButtonVariant.secondary,
                  onPressed: () =>
                      onEvent('tools', 'tick', 'Suche fehlgeschlagen.'),
                ),
              ],
            ),
            SizedBox(height: gap),
            Semantics(
              liveRegion: true,
              child: KText(status, variant: KTextVariant.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
