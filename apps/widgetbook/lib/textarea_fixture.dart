import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class TextareaFixture extends StatefulWidget {
  const TextareaFixture({super.key});
  @override
  State<TextareaFixture> createState() => _TextareaFixtureState();
}

class _TextareaFixtureState extends State<TextareaFixture> {
  final notes = TextEditingController(
    text: 'Inspect the roof.\nDocument the findings.',
  );
  final readOnly = TextEditingController(
    text: 'Approved scope.\nAwaiting inspection.',
  );
  final unavailable = TextEditingController(text: 'Not available.');

  @override
  void dispose() {
    notes.dispose();
    readOnly.dispose();
    unavailable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: t.spaceLayoutGutter),
      child: KContainer(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            const KText('Multiline notes', variant: KTextVariant.heading4),
            KField(
              label: 'Description',
              required: true,
              helperText: 'Use Enter for a new line. Up to 240 characters.',
              child: KTextarea(controller: notes, maxLength: 240),
            ),
            const KField(
              label: 'Required notes',
              required: true,
              errorText: 'Enter a description.',
              child: KTextarea(placeholder: 'Describe the next steps…'),
            ),
            KField(
              label: 'Read only',
              child: KTextarea(controller: readOnly, readOnly: true),
            ),
            KField(
              label: 'Unavailable',
              child: KTextarea(controller: unavailable, enabled: false),
            ),
          ],
        ),
      ),
    );
  }
}
