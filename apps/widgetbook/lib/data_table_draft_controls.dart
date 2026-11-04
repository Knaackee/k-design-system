import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class DraftFixtureControls<T> extends StatelessWidget {
  const DraftFixtureControls({
    required this.controller,
    required this.boundaries,
    required this.delay,
    required this.fail,
    required this.onDelay,
    required this.onFail,
    super.key,
  });
  final KDataTableDraftController<T> controller;
  final Map<String, KDataTableDraftBoundary> boundaries;
  final bool delay, fail;
  final ValueChanged<bool> onDelay, onFail;
  @override
  Widget build(BuildContext context) => KStack(
    align: KLayoutAlign.stretch,
    children: [
      KInline(
        wrap: true,
        children: [
          KCheckbox(
            label: 'Delay save',
            value: delay,
            onChanged: (v) => onDelay(v ?? false),
          ),
          KCheckbox(
            label: 'Fail save',
            value: fail,
            onChanged: (v) => onFail(v ?? false),
          ),
        ],
      ),
      for (final draft in controller.drafts)
        KDataTableDraftCellBoundary(
          boundary: boundaries[draft.id],
          child: KInline(
            children: [
              KText('${draft.id}: ${draft.status.name}'),
              KButton(
                label: 'Save ${draft.id}',
                onPressed: draft.status == KDataTableDraftStatus.saving
                    ? null
                    : () => controller.commit(draft.id, reason: 'action'),
              ),
              KButton(
                label: 'Cancel ${draft.id}',
                onPressed: draft.status == KDataTableDraftStatus.saving
                    ? null
                    : () => controller.cancel(draft.id, reason: 'action'),
              ),
            ],
          ),
        ),
    ],
  );
}
