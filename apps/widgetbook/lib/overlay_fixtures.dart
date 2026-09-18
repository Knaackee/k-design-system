import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class OverlayFixture extends StatefulWidget {
  const OverlayFixture({this.sheet = false, super.key});

  final bool sheet;

  @override
  State<OverlayFixture> createState() => _OverlayFixtureState();
}

class _OverlayFixtureState extends State<OverlayFixture> {
  String message = 'No selection';

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KText(
          widget.sheet ? 'Bottom sheet' : 'Modal dialog',
          variant: KTextVariant.heading4,
        ),
        const SizedBox(height: 16),
        KButton(
          label: widget.sheet ? 'Open sheet' : 'Open dialog',
          onPressed: () {
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                KButton(
                  label: 'Save',
                  onPressed: () {
                    setState(() => message = 'Saved');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
            if (widget.sheet) {
              KBottomSheet.show<void>(
                context: context,
                title: const Text('Share project'),
                description: const Text('Project settings'),
                actions: actions,
                child: const KText(
                  'Choose how this project should be shared with your team.',
                ),
              );
            } else {
              KDialog.show<void>(
                context: context,
                title: const Text('Share project'),
                description: const Text('Project settings'),
                actions: actions,
                child: const KText(
                  'Choose how this project should be shared with your team.',
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        KText(message),
      ],
    ),
  );
}
