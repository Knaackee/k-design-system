import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Matching Web/Flutter fixture: segmented-single-selection.
class SegmentedRadioFixture extends StatefulWidget {
  const SegmentedRadioFixture({super.key});

  @override
  State<SegmentedRadioFixture> createState() => _SegmentedRadioFixtureState();
}

class _SegmentedRadioFixtureState extends State<SegmentedRadioFixture> {
  String? status = 'draft', precision = 'exact';

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.all(
      Theme.of(context).extension<KDesignTokens>()!.spaceCardPadding,
    ),
    child: KStack(
      gap: KLayoutGap.section,
      align: KLayoutAlign.stretch,
      children: [
        KRadioGroup<String>(
          label: 'Status',
          appearance: KRadioGroupAppearance.segmented,
          value: status,
          onChanged: (value) => setState(() => status = value),
          items: const [
            KRadioOption(value: 'draft', label: 'Draft'),
            KRadioOption(value: 'active', label: 'Active'),
            KRadioOption(value: 'archived', label: 'Archived', disabled: true),
          ],
        ),
        KRadioGroup<String>(
          label: 'Construction date',
          appearance: KRadioGroupAppearance.segmented,
          value: precision,
          onChanged: (value) => setState(() => precision = value),
          items: const [
            KRadioOption(value: 'exact', label: 'Exact year'),
            KRadioOption(value: 'range', label: 'Known period'),
            KRadioOption(
              value: 'estimate',
              label: 'Estimated construction period',
            ),
          ],
        ),
        KText('Selected: $status / $precision'),
      ],
    ),
  );
}
