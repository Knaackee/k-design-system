import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class AudioEdgeGlowFixture extends StatefulWidget {
  const AudioEdgeGlowFixture({
    super.key,
    this.state = KAudioEdgeGlowState.capturing,
    this.audioLevel = 0,
    this.reducedMotion = false,
  });
  final KAudioEdgeGlowState state;
  final double audioLevel;
  final bool reducedMotion;
  @override
  State<AudioEdgeGlowFixture> createState() => _AudioEdgeGlowFixtureState();
}

class _AudioEdgeGlowFixtureState extends State<AudioEdgeGlowFixture> {
  late KAudioEdgeGlowState _state = widget.state;
  late double _level = widget.audioLevel;
  Color _color = const Color(0xff84cc16);
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SizedBox.expand(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: t.colorSurfaceCanvas)),
            Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: t.spaceControlGap,
                    children: [
                      Text(
                        _state == KAudioEdgeGlowState.capturing
                            ? 'Ich höre zu'
                            : _state == KAudioEdgeGlowState.processing
                            ? 'Wird verarbeitet'
                            : 'Bereit',
                      ),
                      Wrap(
                        spacing: t.spaceControlGap,
                        alignment: WrapAlignment.center,
                        children: [
                          KButton(
                            label: 'Aufnahme',
                            onPressed: () => setState(
                              () => _state = KAudioEdgeGlowState.capturing,
                            ),
                          ),
                          KButton(
                            label: 'Verarbeitung',
                            variant: KButtonVariant.secondary,
                            onPressed: () => setState(
                              () => _state = KAudioEdgeGlowState.processing,
                            ),
                          ),
                          KButton(
                            label: 'Aus',
                            variant: KButtonVariant.ghost,
                            onPressed: () => setState(
                              () => _state = KAudioEdgeGlowState.inactive,
                            ),
                          ),
                        ],
                      ),
                      Text('Pegel · ${(_level * 100).round()} %'),
                      KSlider(
                        label: 'Mikrofonpegel',
                        value: _level * 100,
                        onChanged: (value) =>
                            setState(() => _level = value / 100),
                      ),
                      Wrap(
                        spacing: t.spaceControlGap,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final entry in const [
                            ('Limette', Color(0xff84cc16)),
                            ('Violett', Color(0xffa78bfa)),
                            ('Blau', Color(0xff38bdf8)),
                          ])
                            KButton(
                              label: entry.$1,
                              variant: KButtonVariant.ghost,
                              onPressed: () =>
                                  setState(() => _color = entry.$2),
                            ),
                        ],
                      ),
                      Text(
                        widget.reducedMotion
                            ? 'Bewegung reduziert'
                            : 'Die Farbe und der Pegel gehören dem Consumer.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: KAudioEdgeGlow(
                color: _color,
                state: _state,
                audioLevel: _level,
                reducedMotion: widget.reducedMotion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
