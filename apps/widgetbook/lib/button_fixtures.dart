import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget buildButtonPrimary(BuildContext context) {
  return Center(
    child: KButton(label: 'Continue', onPressed: () {}),
  );
}

Widget buildButtonVariants(BuildContext context) {
  return Center(
    child: KInline(
      wrap: true,
      align: KLayoutAlign.center,
      children: [
        KButton(label: 'Create issue', onPressed: () {}),
        KButton(
          label: 'Cancel',
          variant: KButtonVariant.secondary,
          onPressed: () {},
        ),
        KButton(
          label: 'Dismiss',
          variant: KButtonVariant.ghost,
          onPressed: () {},
        ),
      ],
    ),
  );
}

Widget buildButtonStates(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  return SingleChildScrollView(
    padding: EdgeInsets.all(tokens.spaceLayoutGutter),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: KStack(
          gap: KLayoutGap.section,
          children: [
            KStack(
              children: [
                const KText(
                  'Adaptive foundation',
                  variant: KTextVariant.heading3,
                ),
                KText(
                  'Compare density, typography, input target and window spacing with the controls.',
                  style: TextStyle(color: tokens.colorTextMuted),
                ),
              ],
            ),
            const KStack(
              children: [
                _ButtonStateRow(variant: KButtonVariant.primary),
                _ButtonStateRow(variant: KButtonVariant.secondary),
                _ButtonStateRow(variant: KButtonVariant.ghost),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ButtonStateRow extends StatelessWidget {
  const _ButtonStateRow({required this.variant});

  final KButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    return KInline(
      wrap: true,
      align: KLayoutAlign.center,
      children: [
        SizedBox(
          width: 72,
          child: KText(
            variant.name.toUpperCase(),
            variant: KTextVariant.caption,
            style: TextStyle(
              color: Theme.of(
                context,
              ).extension<KDesignTokens>()!.colorTextMuted,
            ),
          ),
        ),
        KButton(label: 'Continue', variant: variant, onPressed: () {}),
        KButton(label: 'Disabled', variant: variant, onPressed: null),
        KButton(
          label: 'Saving',
          variant: variant,
          loading: true,
          onPressed: () {},
        ),
      ],
    );
  }
}
