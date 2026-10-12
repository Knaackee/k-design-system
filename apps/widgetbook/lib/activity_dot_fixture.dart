import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

const _purple = Color(0xff8b5cf6);

enum _ActivityDotEasing { linear, easeInOut, easeOutCubic }

Widget buildActivityDotPlayground(BuildContext context) {
  final state = context.knobs.object.dropdown<KActivityDotState>(
    label: 'State',
    options: KActivityDotState.values,
    initialOption: KActivityDotState.working,
    labelBuilder: (value) => value.name,
  );
  final animation = context.knobs.object.dropdown<KActivityDotAnimation>(
    label: 'Animation',
    options: KActivityDotAnimation.values,
    initialOption: KActivityDotAnimation.auto,
    labelBuilder: (value) => value.name,
  );
  final easing = context.knobs.object.dropdown<_ActivityDotEasing>(
    label: 'Easing',
    options: _ActivityDotEasing.values,
    initialOption: _ActivityDotEasing.linear,
    labelBuilder: (value) => value.name,
  );

  return Center(
    child: KActivityDot(
      state: state,
      label: '${state.name} activity',
      size: context.knobs.double.slider(
        label: 'Size',
        initialValue: 16,
        min: 8,
        max: 48,
      ),
      coreSize: context.knobs.double.slider(
        label: 'Core size',
        initialValue: 8,
        min: 2,
        max: 32,
      ),
      ringWidth: context.knobs.double.slider(
        label: 'Ring width',
        initialValue: 2,
        min: 1,
        max: 8,
      ),
      dotColor: context.knobs.color(label: 'Dot color', initialValue: _purple),
      ringColor: context.knobs.colorOrNull(label: 'Ring color'),
      ringTrackColor: context.knobs.colorOrNull(label: 'Ring track color'),
      animation: animation,
      animationCurve: switch (easing) {
        _ActivityDotEasing.linear => Curves.linear,
        _ActivityDotEasing.easeInOut => Curves.easeInOut,
        _ActivityDotEasing.easeOutCubic => Curves.easeOutCubic,
      },
      animationDuration: Duration(
        milliseconds: context.knobs.int.slider(
          label: 'Duration (ms)',
          initialValue: 1000,
          min: 100,
          max: 3000,
        ),
      ),
      animationRepeatCount: context.knobs.intOrNull.slider(
        label: 'Repeat count',
        min: 1,
        max: 10,
        defaultToNull: true,
      ),
      reducedMotion: context.knobs.boolean(label: 'Reduced motion'),
    ),
  );
}

class ActivityDotStatesFixture extends StatelessWidget {
  const ActivityDotStatesFixture({super.key});

  static const examples = [
    ('Alex', KActivityDotState.idle),
    ('Sam', KActivityDotState.working),
    ('Robin', KActivityDotState.question),
    ('Taylor', KActivityDotState.error),
  ];

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final example in examples)
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  KActivityDot(
                    state: example.$2,
                    label: '${example.$2.name} activity',
                    size: 16,
                    coreSize: 8,
                    ringWidth: 2,
                    dotColor: _purple,
                    animationDuration: const Duration(milliseconds: 1000),
                  ),
                  const SizedBox(width: 12),
                  Text(example.$1),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

Widget buildActivityDotConsumerTheme(BuildContext context) => const Center(
  child: SizedBox(
    width: 180,
    height: 120,
    child: Center(
      child: KActivityDot(
        state: KActivityDotState.question,
        label: 'Question activity',
        size: 16,
        coreSize: 8,
        ringWidth: 2,
        dotColor: _purple,
        ringColor: Color(0xff22d3ee),
        ringTrackColor: Color(0xffcbd5e1),
        animation: KActivityDotAnimation.pulse,
        animationDuration: Duration(milliseconds: 1600),
        animationCurve: Curves.easeOutCubic,
      ),
    ),
  ),
);
