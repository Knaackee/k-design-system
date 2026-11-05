import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Matching Web/Flutter fixture: compact-sheet-fixed-actions.
class CompactSheetFixture extends StatefulWidget {
  const CompactSheetFixture({super.key});

  @override
  State<CompactSheetFixture> createState() => _CompactSheetFixtureState();
}

class _CompactSheetFixtureState extends State<CompactSheetFixture> {
  bool longContent = false;
  bool distinctSurface = false;
  String result = 'No selection';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<KDesignTokens>()!;
    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((value) => value is! KDesignTokens),
          tokens.copyWith(
            colorSurfaceOverlay: distinctSurface
                ? tokens.colorSurfaceCanvas
                : tokens.colorSurfaceOverlay,
          ),
        ],
      ),
      child: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: buildContent),
      ),
    );
  }

  Widget buildContent(BuildContext context) => Center(
    child: KStack(
      children: [
        KCheckbox(
          label: 'Long form',
          value: longContent,
          onChanged: (value) => setState(() => longContent = value ?? false),
        ),
        KButton(
          label: 'Open sheet',
          onPressed: () async {
            final saved = await KAdaptiveDialog.show<bool>(
              context: context,
              useRootNavigator: false,
              builder: (route) => KAdaptiveDialog(
                expandBody: false,
                title: const KText('Project settings'),
                description: const KText('Only the fields scroll.'),
                onClose: () => Navigator.of(route).pop(false),
                actions: KInline(
                  gap: KLayoutGap.action,
                  children: [
                    KButton(
                      label: 'Cancel',
                      variant: KButtonVariant.secondary,
                      onPressed: () => Navigator.of(route).pop(false),
                    ),
                    KButton(
                      label: 'Save',
                      onPressed: () => Navigator.of(route).pop(true),
                    ),
                  ],
                ),
                child: KStack(
                  gap: KLayoutGap.action,
                  align: KLayoutAlign.stretch,
                  children: [
                    const KField(label: 'Name', child: KInput()),
                    const KField(
                      label: 'Description',
                      child: KTextarea(rows: 3),
                    ),
                    if (longContent)
                      for (var i = 1; i <= 8; i++)
                        KField(label: 'Setting $i', child: const KInput()),
                  ],
                ),
              ),
            );
            if (mounted) {
              setState(() => result = saved == true ? 'Saved' : 'Cancelled');
            }
          },
        ),
        KText(result),
        KCheckbox(
          label: 'Distinct overlay surface',
          value: distinctSurface,
          onChanged: (value) =>
              setState(() => distinctSurface = value ?? false),
        ),
      ],
    ),
  );
}
