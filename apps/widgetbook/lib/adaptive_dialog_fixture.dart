import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class AdaptiveDialogFixture extends StatelessWidget {
  const AdaptiveDialogFixture({super.key});

  @override
  Widget build(BuildContext context) => Navigator(
    onGenerateRoute: (_) => MaterialPageRoute<void>(
      builder: (context) => Center(
        child: KButton(
          label: 'Adaptiven Dialog öffnen',
          onPressed: () => KAdaptiveDialog.show<void>(
            context: context,
            useRootNavigator: false,
            builder: (route) => KAdaptiveDialog(
              title: const Text('Zugang bearbeiten'),
              description: const Text(
                'Unter 600 px als Bottom Sheet, darüber als Dialog.',
              ),
              onClose: () => Navigator.of(route).pop(),
              actions: Wrap(
                spacing: 8,
                children: [
                  KButton(
                    label: 'Abbrechen',
                    variant: KButtonVariant.ghost,
                    onPressed: () => Navigator.of(route).pop(),
                  ),
                  KButton(
                    label: 'Speichern',
                    onPressed: () => Navigator.of(route).pop(),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const KField(
                    label: 'Name',
                    child: KInput(placeholder: 'Mein Zugang'),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 1; i <= 16; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Einstellung $i · Inhalt scrollt, Aktionen bleiben erreichbar.',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
