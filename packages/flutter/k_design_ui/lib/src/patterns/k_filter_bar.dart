import 'package:flutter/material.dart';
import '../forms/form_style.dart';
import '../primitives/k_button.dart';

class KFilterBar extends StatelessWidget {
  const KFilterBar({
    required this.label,
    required this.children,
    this.onReset,
    this.resetLabel = 'Reset all',
    this.resetEnabled = true,
    super.key,
  });
  final String label;
  final List<Widget> children;
  final VoidCallback? onReset;
  final String resetLabel;
  final bool resetEnabled;
  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    return Semantics(
      label: label,
      container: true,
      child: Wrap(
        spacing: t.spaceContentActionGap,
        runSpacing: t.spaceContentActionGap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...children,
          if (onReset != null)
            KButton(
              label: resetLabel,
              onPressed: resetEnabled ? onReset : null,
              variant: KButtonVariant.ghost,
            ),
        ],
      ),
    );
  }
}
