import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class AnimatedIconFixture extends StatefulWidget {
  const AnimatedIconFixture({super.key});
  @override
  State<AnimatedIconFixture> createState() => _AnimatedIconFixtureState();
}

class _AnimatedIconFixtureState extends State<AnimatedIconFixture> {
  KAnimatedIconSpring _spring = KAnimatedIconSpring.snappy;
  final _active = [false, false, false, false];
  KIconName _from = KIconName.sun, _to = KIconName.moon;
  double _progress = .5;
  bool _destination = false;
  String _status = 'Ready';
  static const _pairs = [
    (KIconName.sun, KIconName.moon, 'Theme'),
    (KIconName.menu, KIconName.x, 'Menu'),
    (KIconName.play, KIconName.pause, 'Playback'),
    (KIconName.heart, KIconName.check, 'Status'),
  ];

  void _setStatus(String value) {
    if (mounted && _status != value) setState(() => _status = value);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final gap = t.spaceLayoutSectionGap;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: EdgeInsets.all(t.spaceCardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const KText('Animated icons', variant: KTextVariant.heading3),
                const KText(
                  'Lucide · Web + Flutter',
                  variant: KTextVariant.bodySmall,
                ),
                SizedBox(height: gap),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: t.spaceControlGap,
                    runSpacing: t.spaceControlGap,
                    children: [
                      for (var i = 0; i < _pairs.length; i++)
                        SizedBox(
                          width: (constraints.maxWidth - t.spaceControlGap) / 2,
                          child: Semantics(
                            toggled: _active[i],
                            child: KButton(
                              label: _pairs[i].$3,
                              variant: KButtonVariant.secondary,
                              leading: KAnimatedIcon(
                                _active[i] ? _pairs[i].$2 : _pairs[i].$1,
                                size: 24,
                                spring: _spring,
                              ),
                              onPressed: () =>
                                  setState(() => _active[i] = !_active[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: gap),
                KSelect(
                  label: 'Motion',
                  value: _spring.name,
                  options: [
                    for (final s in KAnimatedIconSpring.values)
                      KSelectOption(
                        value: s.name,
                        label:
                            '${s.name[0].toUpperCase()}${s.name.substring(1)}',
                      ),
                  ],
                  onChanged: (v) => setState(
                    () => _spring = KAnimatedIconSpring.values.byName(v!),
                  ),
                ),
                SizedBox(height: gap),
                const KText('Try any pair', variant: KTextVariant.heading4),
                SizedBox(height: gap),
                Row(
                  children: [
                    Expanded(
                      child: KCombobox(
                        label: 'From',
                        value: _from.name,
                        options: _options,
                        onChanged: (v) =>
                            setState(() => _from = KIconName.values.byName(v!)),
                      ),
                    ),
                    SizedBox(width: t.spaceControlGap),
                    Expanded(
                      child: KCombobox(
                        label: 'To',
                        value: _to.name,
                        options: _options,
                        onChanged: (v) =>
                            setState(() => _to = KIconName.values.byName(v!)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: 112,
                  child: Center(
                    child: KAnimatedIcon(
                      _destination ? _to : _from,
                      size: 64,
                      spring: _spring,
                      label: 'Animated preview',
                      onAnimationStart: () => _setStatus('Animating'),
                      onAnimationEnd: () => _setStatus('Ready'),
                    ),
                  ),
                ),
                SizedBox(height: gap),
                KButton(
                  label: 'Animate',
                  variant: KButtonVariant.secondary,
                  onPressed: () => setState(() => _destination = !_destination),
                ),
                SizedBox(height: gap),
                KText(_status, variant: KTextVariant.bodySmall),
                SizedBox(height: gap),
                const KText(
                  'Controlled progress',
                  variant: KTextVariant.heading4,
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: 80,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: KAnimatedIcon(
                      _to,
                      from: _from,
                      progress: _progress,
                      size: 64,
                      label: 'Controlled preview',
                    ),
                  ),
                ),
                SizedBox(height: gap),
                KSlider(
                  value: _progress,
                  min: 0,
                  max: 1,
                  label: 'Progress',
                  valueLabel: (v) => '${(v * 100).round()}%',
                  onChanged: (v) => setState(() => _progress = v),
                ),
                SizedBox(height: gap),
                KText(
                  '${(_progress * 100).round()}% · ${KIconName.values.length} bundled icons · Additional Lucide SVGs supported',
                  variant: KTextVariant.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<KSelectOption> get _options => [
    for (final icon in KIconName.values)
      KSelectOption(value: icon.name, label: icon.name, icon: icon),
  ];
}
