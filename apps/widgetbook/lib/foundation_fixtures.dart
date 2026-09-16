import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Matches the Web fixture frame: viewport gutter, max width, and columns.
class FoundationGrid extends StatelessWidget {
  const FoundationGrid({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(
          0.0,
          math.min(760.0, constraints.maxWidth - 2 * tokens.spaceLayoutGutter),
        );
        final columns = constraints.maxWidth < 600 ? 1 : 2;
        final itemWidth =
            (width - (columns - 1) * tokens.spaceLayoutSectionGap) / columns;
        return SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceLayoutGutter),
          child: Center(
            child: SizedBox(
              width: width,
              child: KInline(
                wrap: true,
                gap: KLayoutGap.section,
                children: [
                  for (final child in children)
                    SizedBox(width: itemWidth, child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget buildCardVariants(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  Widget card(KSurfaceTone tone, String title, String copy, String action) =>
      KCard(
        tone: tone,
        child: KStack(
          gap: KLayoutGap.action,
          children: [
            KStack(
              children: [
                KText(title, variant: KTextVariant.heading4),
                KText(
                  copy,
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(color: tokens.colorTextMuted),
                ),
              ],
            ),
            KButton(
              label: action,
              variant: tone == KSurfaceTone.subtle
                  ? KButtonVariant.ghost
                  : KButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
      );
  return FoundationGrid(
    children: [
      card(
        KSurfaceTone.raised,
        'Project settings',
        'Default cards use a fine border and no shadow.',
        'Configure',
      ),
      card(
        KSurfaceTone.subtle,
        'Quiet grouping',
        'Subtle tone separates content without added depth.',
        'View details',
      ),
    ],
  );
}

Widget buildSurfaceTones(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  return FoundationGrid(
    children: [
      for (final (tone, title, copy) in [
        (KSurfaceTone.canvas, 'Canvas', 'Application background'),
        (KSurfaceTone.raised, 'Raised', 'Cards and panels'),
        (KSurfaceTone.subtle, 'Subtle', 'Quiet grouping and selection'),
      ])
        KSurface(
          tone: tone,
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceCardPadding),
            child: KStack(
              children: [
                KText(title, variant: KTextVariant.label),
                KText(
                  copy,
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(color: tokens.colorTextMuted),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

Widget buildRadiusScale(BuildContext context) => FoundationGrid(
  children: [
    for (final (radius, title) in [
      (KSurfaceRadius.none, 'None · 0'),
      (KSurfaceRadius.small, 'Small · 4'),
      (KSurfaceRadius.medium, 'Medium · 6'),
      (KSurfaceRadius.large, 'Large · 8'),
      (KSurfaceRadius.extraLarge, 'Extra large · 12'),
      (KSurfaceRadius.full, 'Full'),
    ])
      KStack(
        align: KLayoutAlign.stretch,
        children: [
          SizedBox(
            height: 72,
            child: KSurface(radius: radius, child: const SizedBox()),
          ),
          KText(title, variant: KTextVariant.caption),
        ],
      ),
  ],
);

Widget buildElevationLevels(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  return FoundationGrid(
    children: [
      for (final (level, title, copy) in [
        (KSurfaceElevation.none, 'None', 'Default cards and in-flow surfaces'),
        (KSurfaceElevation.low, 'Low', 'Floating utility controls'),
        (KSurfaceElevation.medium, 'Medium', 'Menus and popovers'),
        (KSurfaceElevation.overlay, 'Overlay', 'Dialogs and modal layers'),
      ])
        KSurface(
          border: level == KSurfaceElevation.none
              ? KSurfaceBorder.standard
              : KSurfaceBorder.none,
          elevation: level,
          radius: level == KSurfaceElevation.overlay
              ? KSurfaceRadius.overlay
              : KSurfaceRadius.medium,
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceCardPadding),
            child: KStack(
              children: [
                KText(title, variant: KTextVariant.label),
                KText(
                  copy,
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(color: tokens.colorTextMuted),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

Widget buildLayoutComposition(BuildContext context) => const FoundationGrid(
  children: [
    KCard(
      child: KStack(
        gap: KLayoutGap.section,
        children: [
          KText('Shared composition', variant: KTextVariant.heading4),
          KInline(
            wrap: true,
            gap: KLayoutGap.action,
            children: [KText('First'), KText('Second'), KText('Third')],
          ),
          KText(
            'Density updates every semantic gap without replacing children.',
            variant: KTextVariant.bodySmall,
          ),
        ],
      ),
    ),
  ],
);
