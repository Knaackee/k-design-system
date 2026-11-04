import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

class OnboardingNavigationFixture extends StatefulWidget {
  const OnboardingNavigationFixture({super.key});
  @override
  State<OnboardingNavigationFixture> createState() => _NavigationState();
}

class _NavigationState extends State<OnboardingNavigationFixture> {
  int step = 1;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<KDesignTokens>()!;
    final size = context.knobs.double.slider(
      label: 'Control size',
      initialValue: 56,
      min: 48,
      max: 72,
    );
    final icon = context.knobs.double.slider(
      label: 'Icon size',
      initialValue: 24,
      min: 16,
      max: 32,
    );
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((value) => value is! KDesignTokens),
          tokens.copyWith(sizeControl: size, sizeHitTarget: size),
        ],
      ),
      child: KIconSizeScope(
        size: icon,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                KIconButton(
                  label: 'Back',
                  icon: KIconName.arrowLeft,
                  onPressed: step == 0 ? null : () => setState(() => step--),
                ),
                KProgressDots(count: 3, activeIndex: step, label: 'Setup'),
                KIconButton(
                  label: 'Next',
                  icon: KIconName.arrowRight,
                  variant: KButtonVariant.primary,
                  onPressed: step == 2 ? null : () => setState(() => step++),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
