import 'dart:async';
import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

class SoundOnboardingFixture extends StatefulWidget {
  const SoundOnboardingFixture({super.key});
  @override
  State<SoundOnboardingFixture> createState() => _SoundOnboardingFixtureState();
}

class _SoundOnboardingFixtureState extends State<SoundOnboardingFixture> {
  final controller = KSoundController();
  String status = 'Bereit.';
  static const cues = {
    'Auswahl': KSoundCue.tap,
    'Schrittwechsel': KSoundCue.tick,
    'Website übernommen': KSoundCue.complete,
    'Angebot hinzugefügt': KSoundCue.pop,
    'Neu eingeordnet': KSoundCue.drop,
    'Rückgängig': KSoundCue.release,
  };
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KSoundProvider(
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
                  KInline(
                    align: KLayoutAlign.center,
                    children: [
                      const Flexible(
                        child: KText(
                          'Onboarding · Sounds',
                          variant: KTextVariant.heading2,
                        ),
                      ),
                      KSoundToggle(
                        enabled: controller.enabled,
                        onEnabledChanged: (enabled) {
                          controller.setEnabled(enabled);
                          if (enabled) {
                            unawaited(controller.play(KSoundCue.tap));
                          }
                        },
                        labelEnable: 'Sounds aktivieren',
                        labelDisable: 'Sounds ausschalten',
                      ),
                    ],
                  ),
                  const KText(
                    'Dezentes Feedback für bewusste Aktionen. Alle Aktionen funktionieren auch ohne Ton.',
                  ),
                  KSlider(
                    label: 'Lautstärke',
                    value: controller.volume * 100,
                    onChanged: (v) => controller.setVolume(v / 100),
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
                                unawaited(controller.play(cue.value));
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
