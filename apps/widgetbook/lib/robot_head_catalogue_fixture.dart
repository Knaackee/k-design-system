import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'robot_head_audio_fixture.dart';

class RobotHeadCatalogueFixture extends StatelessWidget {
  const RobotHeadCatalogueFixture({this.shapes = false, super.key});

  static const _headSize = 160.0;
  final bool shapes;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final values = shapes ? KRobotHeadShape.values : KRobotHeadState.values;
    final tileWidth = _headSize + 2 * tokens.spaceLayoutSectionGap;
    return KPage(
      children: [
        KText(
          shapes ? 'KRobotHead · Shapes' : 'KRobotHead · States',
          variant: KTextVariant.heading3,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: tokens.spaceLayoutSectionGap,
          runSpacing: tokens.spaceLayoutSectionGap,
          children: [
            for (final value in values)
              SizedBox(
                width: tileWidth,
                child: KStack(
                  align: KLayoutAlign.center,
                  children: [
                    KRobotHead(
                      state: value is KRobotHeadState
                          ? value
                          : KRobotHeadState.idle,
                      shape: value is KRobotHeadShape
                          ? value
                          : KRobotHeadShape.rectangle,
                      size: _headSize,
                      semanticsLabel: value.name,
                    ),
                    KText(value.name),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class RobotHeadAudioDemoFixture extends StatefulWidget {
  const RobotHeadAudioDemoFixture({super.key});

  @override
  State<RobotHeadAudioDemoFixture> createState() =>
      _RobotHeadAudioDemoFixtureState();
}

class _RobotHeadAudioDemoFixtureState extends State<RobotHeadAudioDemoFixture> {
  var _state = KRobotHeadState.speaking;
  var _playing = false;
  KRobotHeadAudioFrame Function()? _source;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return KPage(
      children: [
        const KStack(
          children: [
            KText('KRobotHead · Audio', variant: KTextVariant.heading3),
            KText(
              'Deine PCM-WAV-Datei, dein Roboter. Lokal abspielen und vergleichen.',
            ),
          ],
        ),
        KStack(
          align: KLayoutAlign.center,
          gap: KLayoutGap.action,
          children: [
            KRobotHead(
              state: _state,
              size: 240,
              seed: 0.42,
              audioSource: _source,
              semanticsLabel: 'Audioreaktiver Roboter',
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: tokens.spaceControlGap,
              runSpacing: tokens.spaceControlGap,
              children: [
                KButton(
                  label: 'Sprechen',
                  variant: _state == KRobotHeadState.speaking
                      ? KButtonVariant.primary
                      : KButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => _state = KRobotHeadState.speaking),
                ),
                KButton(
                  label: 'Zuhören / Equalizer',
                  variant: _state == KRobotHeadState.listening
                      ? KButtonVariant.primary
                      : KButtonVariant.secondary,
                  onPressed: () =>
                      setState(() => _state = KRobotHeadState.listening),
                ),
              ],
            ),
            KText(
              _playing
                  ? 'Audio läuft'
                  : _source != null
                  ? 'Audio bereit / still'
                  : 'Synthetische Animation',
            ),
          ],
        ),
        RobotHeadAudioFixture(
          onSourceChanged: (source) => setState(() => _source = source),
          onPlayingChanged: (playing) => setState(() => _playing = playing),
        ),
      ],
    );
  }
}
