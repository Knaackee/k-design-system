import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Future<void> showOrbitDemoDetails({
  required BuildContext context,
  required KOrbitNode node,
  required String? pinnedNodeId,
  required ValueChanged<String?> onPinnedChange,
}) => KResponsiveDrawer.show<void>(
  context: context,
  useRootNavigator: true,
  title: Text(node.label),
  description: node.description == null ? null : Text(node.description!),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KText('Stable ID: ${node.id}'),
      KText(
        'Parent: ${node.parentId ?? 'None'}',
        variant: KTextVariant.bodySmall,
      ),
      KText(
        'Level: ${node.levelId ?? 'Center'}',
        variant: KTextVariant.bodySmall,
      ),
      if (node.progress != null)
        KText(
          'Progress: ${node.progress!.round()}%',
          variant: KTextVariant.bodySmall,
        ),
      SizedBox(
        height: Theme.of(
          context,
        ).extension<KDesignTokens>()!.spaceContentActionGap,
      ),
      KButton(
        label: pinnedNodeId == node.id ? 'Stop following' : 'Follow node',
        onPressed: () {
          onPinnedChange(pinnedNodeId == node.id ? null : node.id);
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    ],
  ),
);
