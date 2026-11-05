import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Same fixture as Storybook Navigation/BackButton/back-button, plus the
/// iOS back swipe: open the detail and swipe right from anywhere in it.
class BackButtonFixture extends StatelessWidget {
  const BackButtonFixture({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: Padding(
            padding: EdgeInsets.all(t.spaceLayoutGutter),
            child: KStack(
              gap: KLayoutGap.section,
              align: KLayoutAlign.start,
              children: [
                const KText('Portfolios', variant: KTextVariant.heading4),
                KButton(
                  label: 'Open Riverside',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const _Detail()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(t.spaceLayoutGutter),
        child: KStack(
          gap: KLayoutGap.section,
          align: KLayoutAlign.stretch,
          children: [
            const KInline(
              gap: KLayoutGap.control,
              children: [
                KBackButton(label: 'Back to Portfolios'),
                Flexible(
                  child: KText('Riverside', variant: KTextVariant.heading4),
                ),
              ],
            ),
            const KText(
              'The chevron alone; screen readers hear "Back to Portfolios". '
              'On iOS, swipe right from the edge or from anywhere here.',
              variant: KTextVariant.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
