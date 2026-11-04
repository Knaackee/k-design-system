import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_surface.dart';

enum KMediaPlacement { top, responsive }

/// Edge-to-edge media, a single rounded boundary and one content inset.
class KMediaCard extends StatelessWidget {
  const KMediaCard({
    required this.media,
    required this.child,
    this.mediaOverlay,
    this.mediaPlacement = KMediaPlacement.top,
    this.mediaHeight = 192,
    this.elevation = KSurfaceElevation.low,
    super.key,
  });
  final Widget media;
  final Widget child;
  final Widget? mediaOverlay;
  final KMediaPlacement mediaPlacement;
  final double mediaHeight;
  final KSurfaceElevation elevation;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final visual = SizedBox(
      height: mediaHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          media,
          if (mediaOverlay != null)
            Positioned(
              top: t.spaceContentActionGap,
              left: t.spaceContentActionGap,
              child: mediaOverlay!,
            ),
        ],
      ),
    );
    final body = Padding(
      padding: EdgeInsets.all(t.spaceCardPadding),
      child: child,
    );
    return KSurface(
      radius: KSurfaceRadius.card,
      elevation: elevation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radiusCard),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (mediaPlacement == KMediaPlacement.responsive &&
                constraints.maxWidth >= 576) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: visual),
                  Expanded(flex: 2, child: body),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [visual, body],
            );
          },
        ),
      ),
    );
  }
}
