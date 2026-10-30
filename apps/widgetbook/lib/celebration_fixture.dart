import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

class CelebrationFixture extends StatefulWidget {
  const CelebrationFixture({super.key});
  @override
  State<CelebrationFixture> createState() => _CelebrationFixtureState();
}

class _CelebrationFixtureState extends State<CelebrationFixture> {
  int _revision = 0;
  @override
  Widget build(BuildContext context) => Center(
    child: KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.center,
      children: [
        KCelebration(
          key: ValueKey(_revision),
          active: context.knobs.boolean(label: 'active', initialValue: true),
          durationMs: context.knobs.int.input(
            label: 'durationMs',
            initialValue: 1100,
          ),
          particleCount: context.knobs.int.input(
            label: 'particleCount',
            initialValue: 24,
          ),
          child: const KAvatar(
            alt: 'Alex',
            fallback: Text('A'),
            size: KAvatarSize.large,
          ),
        ),
        const KText(
          'Das sieht schon nach dir aus.',
          variant: KTextVariant.heading2,
        ),
        KButton(
          onPressed: () => setState(() => _revision++),
          label: 'Erneut ansehen',
        ),
      ],
    ),
  );
}
