import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget buildTypographyPrimary(BuildContext context) {
  return const Center(child: KText('Designing software with clarity'));
}

Widget buildTypographyBalancedMobile(BuildContext context) => _balanced(340);
Widget buildTypographyBalancedTablet(BuildContext context) => _balanced(680);
Widget buildTypographyBalancedLargeText(BuildContext context) => MediaQuery(
  data: MediaQuery.of(
    context,
  ).copyWith(textScaler: const TextScaler.linear(1.5)),
  child: _balanced(340),
);

Widget _balanced(double width) => SingleChildScrollView(
  child: Center(
    child: SizedBox(
      width: width,
      child: const KStack(
        gap: KLayoutGap.section,
        children: [
          KText(
            'Bereit für einen entspannteren Arbeitsalltag und mehr Umsatz?',
            variant: KTextVariant.heading1,
            textWrap: KTextWrap.balance,
            align: TextAlign.center,
          ),
          KText(
            'Ready for a calmer working day and more revenue?',
            variant: KTextVariant.heading1,
            textWrap: KTextWrap.balance,
            align: TextAlign.center,
          ),
          KText(
            'Prêt pour des journées plus sereines et un meilleur chiffre d’affaires ?',
            variant: KTextVariant.heading1,
            textWrap: KTextWrap.balance,
            align: TextAlign.center,
          ),
        ],
      ),
    ),
  ),
);

Widget buildTypographyScale(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  return SingleChildScrollView(
    padding: EdgeInsets.all(tokens.spaceLayoutGutter),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: KStack(
          gap: KLayoutGap.section,
          children: [
            const KText(
              'H1 · Product direction',
              variant: KTextVariant.heading1,
            ),
            const KText(
              'H2 · Planning and strategy',
              variant: KTextVariant.heading2,
            ),
            const KText(
              'H3 · Project overview',
              variant: KTextVariant.heading3,
            ),
            const KText(
              'H4 · Current milestone',
              variant: KTextVariant.heading4,
            ),
            const KText(
              'H5 · Work in progress',
              variant: KTextVariant.heading5,
            ),
            const KText(
              'H6 · Supporting section',
              variant: KTextVariant.heading6,
            ),
            const KText(
              'Body · Clear interface copy supports fast reading across '
              'product and editorial contexts.',
            ),
            const KText(
              'Body small · Secondary information remains legible without '
              'competing with the main content.',
              variant: KTextVariant.bodySmall,
            ),
            const KText('Label · ASSIGNEE', variant: KTextVariant.label),
            const KText(
              'Caption · Updated moments ago',
              variant: KTextVariant.caption,
            ),
          ],
        ),
      ),
    ),
  );
}
