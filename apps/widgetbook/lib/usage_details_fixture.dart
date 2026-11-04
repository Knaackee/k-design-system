import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class UsageDetailsFixture extends StatelessWidget {
  const UsageDetailsFixture({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: SingleChildScrollView(
      child: KUsageDetails(
        title: 'Account-Kontingent',
        sourceLabel: 'Codex · Subscription-Kontingent',
        statusLabel: 'Aktuell gemeldet',
        observedLabel: 'Aktualisiert: 07.10.26, 14:00.',
        windows: [
          KUsageWindow(
            id: 'primary',
            label: '5 Stunden',
            valueLabel: '41 % frei',
            progress: 41,
            extraResetCount: 2,
            renewalLabel: 'Nächste Aufladung in 1 Std. 20 Min.',
            renewalExact: 'Nächster Reset laut Anbieter: 07.10.26, 15:20',
          ),
          KUsageWindow(
            id: 'secondary',
            label: '7 Tage',
            valueLabel: '76 % frei',
            progress: 76,
            renewalLabel: 'Nächste Aufladung in 5 Tagen 2 Std.',
            renewalExact: 'Nächster Reset laut Anbieter: 12.10.26, 16:00',
          ),
        ],
        balances: [
          KUsageValue(
            id: 'credits',
            label: 'Credits',
            valueLabel: '12,5 Credits',
          ),
        ],
        extraResetsLabel: 'Zusatz-Resets',
        extraResets: [
          KUsageValue(
            id: 'expiry',
            label: 'Ablaufdatum: 22.10.26, 22:51',
            valueLabel: '2 Resets',
            detail: 'Läuft in 15 Tagen 8 Std. ab',
          ),
        ],
      ),
    ),
  );
}
