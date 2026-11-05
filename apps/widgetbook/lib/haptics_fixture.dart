import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Patterns/Haptics/haptics-review (Decision 0013).
class HapticsFixture extends StatefulWidget {
  const HapticsFixture({super.key});
  @override
  State<HapticsFixture> createState() => _HapticsFixtureState();
}

class _HapticsFixtureState extends State<HapticsFixture> {
  final controller = KHapticController();
  String status = 'Bereit.';
  static const cues = {
    'Auswahl': KHapticCue.selection,
    'Leicht': KHapticCue.light,
    'Mittel': KHapticCue.medium,
    'Kräftig': KHapticCue.heavy,
    'Erfolg': KHapticCue.success,
    'Warnung': KHapticCue.warning,
    'Fehler': KHapticCue.error,
  };

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KHapticsProvider(
    controller: controller,
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Align(
        alignment: Alignment.topLeft,
        child: KSurface(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(
                Theme.of(
                  context,
                ).extension<KDesignTokens>()!.spaceLayoutSectionGap,
              ),
              child: KStack(
                gap: KLayoutGap.section,
                align: KLayoutAlign.stretch,
                children: [
                  const KText(
                    'Haptisches Feedback',
                    variant: KTextVariant.heading2,
                  ),
                  const KText(
                    'Aus, bis die Person es einschaltet. Jede Rückmeldung ist auch sichtbar; Haptik ergänzt nur.',
                  ),
                  KSwitch(
                    label: 'Haptik',
                    value: controller.enabled,
                    onChanged: controller.setEnabled,
                  ),
                  KStack(
                    gap: KLayoutGap.action,
                    align: KLayoutAlign.stretch,
                    children: [
                      KInline(
                        wrap: true,
                        children: [
                          for (final cue in cues.entries)
                            KButton(
                              label: cue.key,
                              variant: KButtonVariant.secondary,
                              onPressed: () {
                                setState(() => status = cue.key);
                                controller.perform(cue.value);
                              },
                            ),
                        ],
                      ),
                      Semantics(
                        liveRegion: true,
                        child: KText(status, variant: KTextVariant.bodySmall),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
