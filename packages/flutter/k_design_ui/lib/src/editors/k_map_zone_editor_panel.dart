import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../forms/k_field.dart';
import '../forms/k_input.dart';
import '../maps/k_map_polygon.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_text.dart';
import 'k_map_zone_editor_labels.dart';

class KMapZoneEditorPanel extends StatelessWidget {
  const KMapZoneEditorPanel({
    required this.labels,
    required this.zones,
    required this.selectedZoneId,
    required this.editing,
    required this.drawing,
    required this.disabled,
    required this.pending,
    required this.canUndo,
    required this.nameController,
    required this.errorCode,
    required this.onSelect,
    required this.onEdit,
    required this.onAdd,
    required this.onNameChanged,
    required this.onDrawingChanged,
    required this.onRemoveVertex,
    required this.onUndo,
    required this.onCancel,
    required this.onApply,
    super.key,
  });

  final KMapZoneEditorLabels labels;
  final List<KMapZone> zones;
  final String? selectedZoneId;
  final bool editing;
  final bool drawing;
  final bool disabled;
  final bool pending;
  final bool canUndo;
  final TextEditingController nameController;
  final String? errorCode;
  final ValueChanged<String?> onSelect;
  final VoidCallback onEdit;
  final VoidCallback onAdd;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<bool> onDrawingChanged;
  final ValueChanged<int> onRemoveVertex;
  final VoidCallback onUndo;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  KMapZone? get selected {
    for (final zone in zones) {
      if (zone.id == selectedZoneId) return zone;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      type: MaterialType.transparency,
      child: KSurface(
        radius: KSurfaceRadius.card,
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLayoutGutter),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: editing && selected != null
                      ? _draft(tokens, selected!)
                      : _list(tokens),
                ),
              ),
              SizedBox(height: tokens.spaceControlGap),
              _actions(tokens, selected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(KDesignTokens tokens) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: tokens.spaceControlGap,
    children: [
      for (final zone in zones)
        Semantics(
          button: true,
          selected: zone.id == selectedZoneId,
          label: zone.name,
          child: Material(
            color: zone.id == selectedZoneId
                ? tokens.colorBrandPrimaryBackground
                : tokens.colorActionGhostBackground,
            borderRadius: BorderRadius.circular(tokens.radiusControl),
            child: InkWell(
              onTap: disabled ? null : () => onSelect(zone.id),
              hoverColor: tokens.colorActionGhostHover,
              borderRadius: BorderRadius.circular(tokens.radiusControl),
              child: Container(
                constraints: BoxConstraints(minHeight: tokens.sizeControl),
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceControlInsetInline,
                  vertical: tokens.spaceControlGap,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: zone.id == selectedZoneId
                        ? tokens.colorBorderStrong
                        : tokens.colorActionGhostBorder,
                    width: tokens.borderWidthDefault,
                  ),
                  borderRadius: BorderRadius.circular(tokens.radiusControl),
                ),
                child: Row(
                  children: [
                    Container(
                      width: tokens.sizeIndicatorSmall,
                      height: tokens.sizeIndicatorSmall,
                      decoration: BoxDecoration(
                        color: _zoneColor(zone.color, tokens),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: tokens.spaceControlGap),
                    Expanded(
                      child: KText(
                        zone.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _draft(KDesignTokens tokens, KMapZone zone) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: tokens.spaceControlGap,
    children: [
      KField(
        label: labels.zoneName,
        child: KInput(
          controller: nameController,
          enabled: !disabled && !pending,
          onChanged: onNameChanged,
        ),
      ),
      KText(
        labels.addVertexHint,
        style: TextStyle(color: tokens.colorTextMuted),
      ),
      if (errorCode != null)
        KText(
          labels.validationMessage(errorCode!),
          style: TextStyle(color: tokens.colorStatusErrorForeground),
        ),
      Wrap(
        spacing: tokens.spaceControlGap,
        children: [
          KButton(
            label: labels.move,
            variant: drawing
                ? KButtonVariant.secondary
                : KButtonVariant.primary,
            onPressed: disabled || pending
                ? null
                : () => onDrawingChanged(false),
          ),
          KButton(
            label: labels.draw,
            variant: drawing
                ? KButtonVariant.primary
                : KButtonVariant.secondary,
            onPressed: disabled || pending
                ? null
                : () => onDrawingChanged(true),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          KText(labels.vertices, variant: KTextVariant.label),
          KText('${zone.coordinates.length}'),
        ],
      ),
      for (var i = 0; i < zone.coordinates.length; i++)
        Row(
          children: [
            Expanded(
              child: KText(
                '${i + 1}. ${zone.coordinates[i].longitude.toStringAsFixed(5)}, '
                '${zone.coordinates[i].latitude.toStringAsFixed(5)}',
              ),
            ),
            KIconButton(
              label: '${labels.removePoint} ${i + 1}',
              icon: KIconName.trash,
              onPressed: disabled || pending ? null : () => onRemoveVertex(i),
            ),
          ],
        ),
    ],
  );

  Widget _actions(KDesignTokens tokens, KMapZone? zone) => Wrap(
    alignment: WrapAlignment.end,
    spacing: tokens.spaceControlGap,
    runSpacing: tokens.spaceControlGap,
    children: editing && zone != null
        ? [
            KButton(
              label: labels.undo,
              variant: KButtonVariant.secondary,
              onPressed: canUndo && !pending ? onUndo : null,
            ),
            KButton(
              label: labels.cancel,
              variant: KButtonVariant.secondary,
              onPressed: disabled ? null : onCancel,
            ),
            KButton(
              label: labels.apply,
              onPressed:
                  disabled ||
                      pending ||
                      zone.name.trim().isEmpty ||
                      errorCode != null
                  ? null
                  : onApply,
            ),
          ]
        : [
            KButton(
              label: labels.editZone,
              variant: KButtonVariant.secondary,
              onPressed: disabled || selected == null ? null : onEdit,
            ),
            KButton(label: labels.addZone, onPressed: disabled ? null : onAdd),
          ],
  );
}

Color _zoneColor(String? value, KDesignTokens tokens) {
  if (value == null) return tokens.colorBrandPrimaryAccent;
  final hex = value.startsWith('#') ? value.substring(1) : value;
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    return tokens.colorBrandPrimaryAccent;
  }
  return Color(int.parse('ff$hex', radix: 16));
}
