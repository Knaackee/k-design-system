import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'overlay_fixtures.dart';

class NeutralDesignFixture extends StatelessWidget {
  const NeutralDesignFixture({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLayoutGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KText(
            'Ruhige Flächen. Klare Aktionen.',
            variant: KTextVariant.heading3,
          ),
          SizedBox(height: tokens.spaceControlGap),
          const KText('Neutrale Aktionsfarben und Radien von 6, 8 und 12 px.'),
          SizedBox(height: tokens.spaceLayoutGutter),
          Wrap(
            spacing: tokens.spaceControlGap,
            runSpacing: tokens.spaceControlGap,
            children: [
              KButton(
                label: 'Standardaktion',
                variant: KButtonVariant.secondary,
                onPressed: () {},
              ),
              KButton(label: 'Änderungen speichern', onPressed: () {}),
              KButton(
                label: 'Abbrechen',
                variant: KButtonVariant.ghost,
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: tokens.spaceLayoutGutter),
          Wrap(
            spacing: tokens.spaceControlGap,
            runSpacing: tokens.spaceControlGap,
            children: const [
              KButton(label: 'Nicht verfügbar', onPressed: null),
              KButton(
                label: 'Wird gespeichert',
                loading: true,
                onPressed: null,
              ),
            ],
          ),
          const OverlayFixture(),
        ],
      ),
    );
  }
}
