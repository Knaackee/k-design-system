import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

class AgentCursorFixture extends StatefulWidget {
  const AgentCursorFixture({this.variant = 'Default', super.key});
  final String variant;

  @override
  State<AgentCursorFixture> createState() => _AgentCursorFixtureState();
}

class _AgentCursorFixtureState extends State<AgentCursorFixture> {
  bool saved = false;
  @override
  Widget build(BuildContext context) {
    final theme = widget.variant == 'DarkSurface'
        ? kDesignTheme(brightness: Brightness.dark)
        : Theme.of(context);
    final t = theme.extension<KDesignTokens>()!;
    final glowEnabled = context.knobs.boolean(
      label: 'Glow enabled',
      initialValue: true,
    );
    final glowIntensity = context.knobs.double.slider(
      label: 'Glow intensity',
      initialValue: 1,
      min: 0,
      max: 1,
      divisions: 20,
    );
    final glowColor = context.knobs.color(
      label: 'Glow color',
      initialValue: t.colorStatusInfoAccent,
    );
    final showAvatar = context.knobs.boolean(
      label: 'Show avatar',
      initialValue: widget.variant == 'WithAvatar',
    );
    final avatarText = context.knobs.string(
      label: 'Avatar text',
      initialValue: 'A',
    );
    final label = context.knobs.string(
      label: 'Label',
      initialValue: widget.variant == 'WithAvatar' ? 'Agent' : '',
    );
    final stage = Theme(
      data: theme,
      child: Container(
        width: 480,
        height: 260,
        decoration: BoxDecoration(
          color: t.colorSurfaceRaised,
          border: Border.all(color: t.colorBorderDefault),
          borderRadius: BorderRadius.circular(t.radiusOverlay),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: t.colorBorderDefault),
                    ),
                  ),
                  child: Text(
                    '◌   Workspace / Notes',
                    style: TextStyle(color: t.colorTextMuted, fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Research notes',
                        style: TextStyle(
                          color: t.colorTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A small change, ready to save.',
                        style: TextStyle(color: t.colorTextMuted),
                      ),
                      const SizedBox(height: 24),
                      KButton(
                        label: saved ? 'Saved' : 'Save notes',
                        onPressed: () => setState(() => saved = !saved),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 112,
              top: 172,
              child: KAgentCursor(
                visible: widget.variant != 'Hidden',
                state: widget.variant == 'Clicking'
                    ? KAgentCursorState.clicking
                    : KAgentCursorState.pointing,
                glowEnabled: glowEnabled,
                glowIntensity: glowIntensity,
                glowColor: glowColor,
                avatar: showAvatar
                    ? KAvatar(
                        alt: label.isEmpty ? 'Agent' : label,
                        fallback: Text(avatarText),
                        size: KAvatarSize.small,
                      )
                    : null,
                label: label,
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.variant == 'ReducedMotion')
            MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: stage,
            )
          else
            stage,
          const SizedBox(height: 16),
          Text(
            'The arrow tip marks the supplied position. The button remains interactive.',
            style: TextStyle(
              color: Theme.of(
                context,
              ).extension<KDesignTokens>()!.colorTextMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
