import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget buildSemanticColors(BuildContext context) {
  final tokens = Theme.of(context).extension<KDesignTokens>()!;
  final roles = [
    (
      'Primary',
      'Brand and principal actions',
      tokens.colorBrandPrimaryAccent,
      tokens.colorBrandPrimaryBackground,
      tokens.colorBrandPrimaryForeground,
      tokens.colorBrandPrimaryBorder,
    ),
    (
      'Secondary',
      'Supporting brand emphasis',
      tokens.colorBrandSecondaryAccent,
      tokens.colorBrandSecondaryBackground,
      tokens.colorBrandSecondaryForeground,
      tokens.colorBrandSecondaryBorder,
    ),
    (
      'Info',
      'Neutral system information',
      tokens.colorStatusInfoAccent,
      tokens.colorStatusInfoBackground,
      tokens.colorStatusInfoForeground,
      tokens.colorStatusInfoBorder,
    ),
    (
      'Success',
      'Completed or healthy state',
      tokens.colorStatusSuccessAccent,
      tokens.colorStatusSuccessBackground,
      tokens.colorStatusSuccessForeground,
      tokens.colorStatusSuccessBorder,
    ),
    (
      'Warning',
      'Attention without failure',
      tokens.colorStatusWarningAccent,
      tokens.colorStatusWarningBackground,
      tokens.colorStatusWarningForeground,
      tokens.colorStatusWarningBorder,
    ),
    (
      'Error',
      'Failure or destructive state',
      tokens.colorStatusErrorAccent,
      tokens.colorStatusErrorBackground,
      tokens.colorStatusErrorForeground,
      tokens.colorStatusErrorBorder,
    ),
  ];

  return SingleChildScrollView(
    padding: EdgeInsets.all(tokens.spaceLayoutGutter),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: KInline(
          wrap: true,
          children: [
            for (final role in roles)
              _ColorRoleCard(
                name: role.$1,
                description: role.$2,
                accent: role.$3,
                background: role.$4,
                foreground: role.$5,
                border: role.$6,
              ),
          ],
        ),
      ),
    ),
  );
}

class _ColorRoleCard extends StatelessWidget {
  const _ColorRoleCard({
    required this.name,
    required this.description,
    required this.accent,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String name;
  final String description;
  final Color accent;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      width: 340,
      constraints: const BoxConstraints(minHeight: 88),
      padding: EdgeInsets.all(tokens.spaceCardPadding),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(tokens.radiusControl),
      ),
      child: KInline(
        align: KLayoutAlign.center,
        children: [
          Container(
            width: 8,
            height: 54,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Expanded(
            child: KStack(
              children: [
                KText(
                  name,
                  variant: KTextVariant.label,
                  style: TextStyle(color: foreground),
                ),
                KText(
                  description,
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
