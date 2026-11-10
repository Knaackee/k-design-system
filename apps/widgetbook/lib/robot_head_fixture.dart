import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'robot_head_audio_fixture.dart';
import 'robot_head_catalogue_fixture.dart';

Widget buildRobotHeadPlayground(BuildContext context) =>
    const RobotHeadPlaygroundFixture();

Widget buildRobotHeadStates(BuildContext context) =>
    const RobotHeadCatalogueFixture();

Widget buildRobotHeadShapes(BuildContext context) =>
    const RobotHeadCatalogueFixture(shapes: true);

Widget buildRobotHeadAudio(BuildContext context) =>
    const RobotHeadAudioDemoFixture();

const _descriptions = <KRobotHeadState, String>{
  KRobotHeadState.idle: 'Schaut sich um, blinzelt und hüpft gelegentlich.',
  KRobotHeadState.thinking:
      'Denkt mit wandernden Punkten und sanfter Neigung nach.',
  KRobotHeadState.searching: 'Sucht mit einer wandernden Scanlinie.',
  KRobotHeadState.listening:
      'Hört zu. Die Frequenzbänder können echtem Audio folgen.',
  KRobotHeadState.speaking:
      'Spricht. Der Mund kann dem abgespielten Audio folgen.',
  KRobotHeadState.working:
      'Arbeitet mit einer zyklischen Fortschrittsanimation.',
  KRobotHeadState.happy: 'Freut sich, lächelt und hüpft.',
  KRobotHeadState.error: 'Zeigt einen Fehler mit roten LEDs und Kopfschütteln.',
  KRobotHeadState.sleeping: 'Schläft mit geschlossenen Augen und Z-Zeichen.',
};

const _shells = <(String, Color)>[
  ('Kobalt', Color(0xff2b49a3)),
  ('Tomate', Color(0xffcf4b3e)),
  ('Mandarine', Color(0xffe08832)),
  ('Senf', Color(0xffc4a345)),
  ('Mint', Color(0xff6bbf9a)),
  ('Teal', Color(0xff287e85)),
  ('Traube', Color(0xff7951ad)),
  ('Rosa', Color(0xffdf8aaa)),
  ('Graphit', Color(0xff454953)),
  ('Porzellan', Color(0xffdedbd2)),
];
const _defaultTrim = Color(0xff93a6c8);
const _defaultScreen = Color(0xffe8f2ff);
const _maxHeadSize = 280.0;

class RobotHeadPlaygroundFixture extends StatefulWidget {
  const RobotHeadPlaygroundFixture({super.key});

  @override
  State<RobotHeadPlaygroundFixture> createState() =>
      _RobotHeadPlaygroundFixtureState();
}

class _RobotHeadPlaygroundFixtureState
    extends State<RobotHeadPlaygroundFixture> {
  final _controller = KRobotHeadController();
  var _state = KRobotHeadState.idle;
  var _shape = KRobotHeadShape.rectangle;
  var _color = _shells.first.$2;
  var _trimColor = _defaultTrim;
  var _screenColor = _defaultScreen;
  var _size = 240.0;
  var _speed = 1.0;
  var _paused = false;
  var _antenna = true;
  var _shadow = true;
  var _interactive = true;
  var _reducedMotion = false;
  var _tracking = _Tracking.pointer;
  var _target = Offset.zero;
  var _activations = 0;
  var _reaction = false;
  var _audioPlaying = false;
  KRobotHeadAudioFrame Function()? _audioSource;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return KPage(
      width: KPageWidth.fluid,
      children: [
        const KStack(
          children: [
            KText('KRobotHead', variant: KTextVariant.heading3),
            KText('Ein kleines Gesicht für große Ideen.'),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final wide =
                kWindowClassForWidth(width).index >=
                KWindowClass.expanded.index;
            final columnsWidth = width - tokens.spaceLayoutSectionGap;
            final previewWidth = wide ? columnsWidth * .6 : width;
            return KInline(
              gap: KLayoutGap.section,
              wrap: true,
              children: [
                SizedBox(width: previewWidth, child: _preview(tokens)),
                SizedBox(
                  width: wide ? columnsWidth - previewWidth : width,
                  child: _controls(tokens),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _preview(KDesignTokens tokens) {
    final previewHeight = _maxHeadSize + 2 * tokens.spaceLayoutSectionGap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KSurface(
          tone: KSurfaceTone.subtle,
          radius: KSurfaceRadius.card,
          child: SizedBox(
            height: previewHeight,
            width: double.infinity,
            child: Center(
              child: KRobotHead(
                controller: _controller,
                state: _state,
                shape: _shape,
                size: _size,
                color: _color,
                trimColor: _trimColor,
                screenColor: _screenColor,
                speed: _speed,
                paused: _paused,
                reducedMotion: _reducedMotion,
                interactive: _interactive,
                antenna: _antenna,
                floorShadow: _shadow,
                target: _tracking == _Tracking.external ? _target : null,
                trackPointer: _tracking == _Tracking.pointer,
                audioSource: _audioSource,
                semanticsLabel: 'Roboter aktivieren',
                onActivate: () => setState(() => _activations++),
                onReactionStart: () => setState(() => _reaction = true),
                onReactionEnd: () => setState(() => _reaction = false),
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spaceContentActionGap),
        KText(_state.name, variant: KTextVariant.heading3),
        KText(_descriptions[_state]!),
        SizedBox(height: tokens.spaceContentActionGap),
        KInline(
          gap: KLayoutGap.action,
          wrap: true,
          children: [
            KButton(
              label: _paused ? 'Fortsetzen' : 'Pause',
              variant: KButtonVariant.secondary,
              onPressed: () => setState(() => _paused = !_paused),
            ),
            KButton(
              label: 'Reaktion auslösen',
              variant: KButtonVariant.secondary,
              onPressed: _controller.react,
            ),
            KButton(
              label: 'Zurücksetzen',
              variant: KButtonVariant.ghost,
              onPressed: () {
                _controller.reset();
                setState(() => _reaction = false);
              },
            ),
          ],
        ),
        SizedBox(height: tokens.spaceContentActionGap),
        KText(
          '${_audioPlaying
              ? 'Audio läuft'
              : _audioSource != null
              ? 'Audio bereit / still'
              : 'Synthetische Animation'}'
          ' · $_activations Aktivierungen${_reaction ? ' · Reaktion aktiv' : ''}',
          variant: KTextVariant.label,
        ),
        SizedBox(height: tokens.spaceContentActionGap),
        RobotHeadAudioFixture(
          onSourceChanged: (source) => setState(() => _audioSource = source),
          onPlayingChanged: (playing) {
            setState(() {
              _audioPlaying = playing;
              if (playing && _state != KRobotHeadState.listening) {
                _state = KRobotHeadState.speaking;
              }
            });
          },
        ),
        SizedBox(height: tokens.spaceContentActionGap),
        KInline(
          wrap: true,
          children: [
            for (final state in KRobotHeadState.values)
              KButton(
                label: state.name,
                variant: state == _state
                    ? KButtonVariant.primary
                    : KButtonVariant.ghost,
                onPressed: () => setState(() => _state = state),
              ),
          ],
        ),
      ],
    );
  }

  Widget _controls(KDesignTokens tokens) => KSurface(
    radius: KSurfaceRadius.card,
    child: Padding(
      padding: EdgeInsets.all(tokens.spaceCardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KSelect(
            label: 'Form',
            value: _shape.name,
            options: [
              for (final shape in KRobotHeadShape.values)
                KSelectOption(value: shape.name, label: shape.name),
            ],
            onChanged: (value) =>
                setState(() => _shape = KRobotHeadShape.values.byName(value!)),
          ),
          SizedBox(height: tokens.spaceContentActionGap),
          const KText('Gehäuse', variant: KTextVariant.label),
          SizedBox(height: tokens.spaceControlGap),
          KInline(
            wrap: true,
            children: [
              for (final shell in _shells)
                KButton(
                  label: shell.$1,
                  leading: _swatch(tokens, shell.$2),
                  variant: shell.$2 == _color
                      ? KButtonVariant.primary
                      : KButtonVariant.ghost,
                  onPressed: () => setState(() => _color = shell.$2),
                ),
            ],
          ),
          SizedBox(height: tokens.spaceContentActionGap),
          KSelect(
            label: 'Metallfarbe',
            value: _trimColor.toARGB32().toRadixString(16),
            options: _colorOptions(tokens, _defaultTrim),
            onChanged: (value) => setState(
              () => _trimColor = Color(int.parse(value!, radix: 16)),
            ),
          ),
          SizedBox(height: tokens.spaceControlGap),
          KSelect(
            label: 'LED-Farbe',
            value: _screenColor.toARGB32().toRadixString(16),
            options: _colorOptions(tokens, _defaultScreen),
            onChanged: (value) => setState(
              () => _screenColor = Color(int.parse(value!, radix: 16)),
            ),
          ),
          SizedBox(height: tokens.spaceContentActionGap),
          KText('Geschwindigkeit · ${_speed.toStringAsFixed(1)}×'),
          KSlider(
            label: 'Geschwindigkeit',
            min: 0,
            max: 3,
            divisions: 30,
            value: _speed,
            onChanged: (value) => setState(() => _speed = value),
          ),
          KText('Größe · ${_size.round()} px'),
          KSlider(
            label: 'Größe',
            min: 64,
            max: _maxHeadSize,
            divisions: 27,
            value: _size,
            onChanged: (value) => setState(() => _size = value),
          ),
          KSwitch(
            label: 'Antenne',
            value: _antenna,
            onChanged: (value) => setState(() => _antenna = value),
          ),
          KSwitch(
            label: 'Bodenschatten',
            value: _shadow,
            onChanged: (value) => setState(() => _shadow = value),
          ),
          KSwitch(
            label: 'Interaktion',
            value: _interactive,
            onChanged: (value) => setState(() => _interactive = value),
          ),
          KSwitch(
            label: 'Bewegung reduzieren',
            value: _reducedMotion,
            onChanged: (value) => setState(() => _reducedMotion = value),
          ),
          SizedBox(height: tokens.spaceContentActionGap),
          KSelect(
            label: 'Blicksteuerung',
            value: _tracking.name,
            options: const [
              KSelectOption(value: 'pointer', label: 'Maus / Finger'),
              KSelectOption(value: 'external', label: 'Externer Zielpunkt'),
              KSelectOption(value: 'off', label: 'Keine Verfolgung'),
            ],
            onChanged: (value) =>
                setState(() => _tracking = _Tracking.values.byName(value!)),
          ),
          if (_tracking == _Tracking.external) ...[
            KText('Ziel X · ${_target.dx.toStringAsFixed(2)}'),
            KSlider(
              label: 'Ziel X',
              min: -1,
              max: 1,
              divisions: 40,
              value: _target.dx,
              onChanged: (value) =>
                  setState(() => _target = Offset(value, _target.dy)),
            ),
            KText('Ziel Y · ${_target.dy.toStringAsFixed(2)}'),
            KSlider(
              label: 'Ziel Y',
              min: -1,
              max: 1,
              divisions: 40,
              value: _target.dy,
              onChanged: (value) =>
                  setState(() => _target = Offset(_target.dx, value)),
            ),
          ],
        ],
      ),
    ),
  );
}

enum _Tracking { pointer, external, off }

List<KSelectOption> _colorOptions(KDesignTokens tokens, Color initial) => [
  for (final (label, color) in [('Standard', initial), ..._shells])
    KSelectOption(
      value: color.toARGB32().toRadixString(16),
      label: label,
      leading: _swatch(tokens, color),
    ),
];

Widget _swatch(KDesignTokens tokens, Color color) => SizedBox.square(
  dimension: tokens.sizeIconDefault,
  child: DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  ),
);
