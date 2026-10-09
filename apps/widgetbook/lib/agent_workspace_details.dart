import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

class AgentWorkspaceDetails extends StatelessWidget {
  const AgentWorkspaceDetails({super.key});
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kontext'),
        SizedBox(height: tokens.spaceLayoutGutter),
        const Text('Dateien'),
        SizedBox(height: tokens.spaceControlGap),
        const Text('Projektbrief.pdf'),
        SizedBox(height: tokens.spaceLayoutGutter),
        const Text('Ergebnisse'),
        SizedBox(height: tokens.spaceControlGap),
        const Text('Hier erscheinen später geteilte Inhalte des Agenten.'),
      ],
    );
  }
}

