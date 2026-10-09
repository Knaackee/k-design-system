import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Static preview data, with no account connection or actions.
class AgentWorkspaceUsage extends StatelessWidget {
  const AgentWorkspaceUsage({
    super.key,
    this.resetExpiries = const ['21. Oktober 2026', '28. Oktober 2026'],
  });
  final List<String> resetExpiries;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(
      Theme.of(context).extension<KDesignTokens>()!.spaceLayoutGutter,
    ),
    child: KUsageDetails(
      title: 'Codex',
      sourceLabel: 'demo@example.com',
      statusLabel: 'Beispieldaten · Verbunden',
      observedLabel: 'Gerade eben · Demo',
      windows: [
        KUsageWindow(
          id: 'seven-days',
          label: '7 Tage',
          valueLabel: '68 % Rest',
          progress: 68,
          extraResetCount: resetExpiries.length,
          renewalLabel: 'Reset in 3 Tagen 13 Std.',
        ),
      ],
      extraResetsLabel: 'Zusatzresets',
      extraResets: [
        for (final expiry in resetExpiries)
          KUsageValue(
            id: expiry,
            label: 'Verfällt am $expiry',
            valueLabel: '1 Reset',
          ),
      ],
    ),
  );
}
