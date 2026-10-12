import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_text.dart';

/// The consumer owns session state, preview transport and actions.
class KBrowserTaskCard extends StatelessWidget {
  const KBrowserTaskCard({
    required this.title,
    required this.description,
    required this.preview,
    required this.actions,
    super.key,
  });
  final String title, description;
  final Widget preview, actions;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KSurface(
      tone: KSurfaceTone.raised,
      radius: KSurfaceRadius.card,
      child: Padding(
        padding: EdgeInsets.all(t.spaceControlGap * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            KText(title, variant: KTextVariant.heading4),
            SizedBox(height: t.spaceControlGap),
            KText(description, style: TextStyle(color: t.colorTextMuted)),
            SizedBox(height: t.spaceControlGap * 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(t.radiusControl),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: t.colorBorderDefault,
                    width: t.borderWidthDefault,
                  ),
                  borderRadius: BorderRadius.circular(t.radiusControl),
                ),
                child: AspectRatio(aspectRatio: 16 / 9, child: preview),
              ),
            ),
            SizedBox(height: t.spaceControlGap * 2),
            Divider(
              color: t.colorBorderDefault,
              height: t.borderWidthDefault,
              thickness: t.borderWidthDefault,
            ),
            SizedBox(height: t.spaceControlGap),
            actions,
          ],
        ),
      ),
    );
  }
}
