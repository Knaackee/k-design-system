import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../localization/k_localization.dart';
import '../primitives/k_text.dart';

/// One shape in a [KAvatarPicker]. The app draws the [icon], so its own
/// avatars (Rive, SVG, DiceBear) stay its own.
class KAvatarShape {
  const KAvatarShape({
    required this.id,
    required this.label,
    required this.icon,
  });
  final String id;
  final String label;
  final Widget icon;
}

/// One colour in a [KAvatarPicker].
class KAvatarColor {
  const KAvatarColor({required this.value, required this.label});
  final Color value;
  final String label;
}

/// Shape and colour of an avatar (Decision 0017): a grid of shape tiles and
/// a row of colour swatches. Show the result in the surrounding header.
class KAvatarPicker extends StatelessWidget {
  const KAvatarPicker({
    required this.shapes,
    required this.colors,
    required this.shape,
    required this.color,
    required this.onShapeChanged,
    required this.onColorChanged,
    super.key,
  });

  final List<KAvatarShape> shapes;
  final List<KAvatarColor> colors;
  final String shape;
  final Color color;
  final ValueChanged<String> onShapeChanged;
  final ValueChanged<Color> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final l = KLocalization.of(context);
    Widget label(String text) => Padding(
      padding: EdgeInsets.only(bottom: t.spaceControlGap),
      child: KText(
        text,
        variant: KTextVariant.label,
        style: TextStyle(color: t.colorTextMuted),
      ),
    );
    final radius = BorderRadius.circular(t.radiusControl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label(l.text('avatarShape')),
        Wrap(
          spacing: t.spaceTight,
          runSpacing: t.spaceTight,
          children: [
            for (final option in shapes)
              Semantics(
                button: true,
                selected: option.id == shape,
                label: option.label,
                excludeSemantics: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    key: ValueKey('k-avatar-shape:${option.id}'),
                    borderRadius: radius,
                    onTap: () => onShapeChanged(option.id),
                    child: Container(
                      width: t.componentAvatarPickerTileWidth,
                      padding: EdgeInsets.symmetric(vertical: t.spaceTight),
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        color: option.id == shape ? t.colorSurfaceSubtle : null,
                        border: Border.all(
                          color: option.id == shape
                              ? t.colorActionPrimaryBackground
                              : Colors.transparent,
                          width: t.borderWidthDefault,
                        ),
                      ),
                      child: Column(
                        spacing: t.spaceMicro,
                        children: [
                          SizedBox.square(
                            dimension: t.sizeIconDefault,
                            child: option.icon,
                          ),
                          KText(
                            option.label,
                            variant: KTextVariant.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: t.spaceContentActionGap),
        label(l.text('avatarColor')),
        Wrap(
          spacing: t.spaceControlGap,
          runSpacing: t.spaceControlGap,
          children: [
            for (final option in colors)
              Semantics(
                button: true,
                selected: option.value == color,
                label: option.label,
                excludeSemantics: true,
                child: GestureDetector(
                  key: ValueKey('k-avatar-color:${option.label}'),
                  onTap: () => onColorChanged(option.value),
                  child: Container(
                    width: t.componentAvatarPickerSwatchSize,
                    height: t.componentAvatarPickerSwatchSize,
                    decoration: BoxDecoration(
                      color: option.value,
                      shape: BoxShape.circle,
                      border: option.value == color
                          ? Border.all(
                              color: t.colorTextPrimary,
                              width: t.borderWidthStrong,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
