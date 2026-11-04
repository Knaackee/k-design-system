import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';

class KBookingFlowChoice extends StatelessWidget {
  const KBookingFlowChoice({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final String value;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final mode in ['guided', 'free']) ...[
          if (mode == 'free') SizedBox(width: t.spaceControlGap),
          Expanded(
            child: Semantics(
              button: true,
              selected: mode == value,
              child: InkWell(
                onTap: onChanged == null ? null : () => onChanged!(mode),
                borderRadius: BorderRadius.circular(t.radiusCard),
                child: Container(
                  padding: EdgeInsets.all(t.spaceContentActionGap),
                  decoration: BoxDecoration(
                    color: t.colorSurfaceRaised,
                    borderRadius: BorderRadius.circular(t.radiusCard),
                    border: Border.all(
                      color: mode == value
                          ? t.colorActionPrimaryBackground
                          : t.colorBorderDefault,
                      width: mode == value
                          ? t.borderWidthStrong
                          : t.borderWidthDefault,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: t.sizeAvatarLarge,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: mode == 'guided'
                              ? const [
                                  KIcon(KIconName.square),
                                  KIcon(KIconName.arrowRight, size: 16),
                                  KIcon(KIconName.square),
                                  KIcon(KIconName.arrowRight, size: 16),
                                  KIcon(KIconName.square),
                                ]
                              : const [
                                  KIcon(KIconName.layoutGrid, size: 32),
                                  KIcon(KIconName.arrowRight, size: 20),
                                  KIcon(KIconName.shoppingCart, size: 32),
                                ],
                        ),
                      ),
                      SizedBox(height: t.spaceControlGap),
                      Text(
                        mode == 'guided' ? 'Geführt' : 'Freie Auswahl',
                        style: TextStyle(
                          fontSize: t.fontHeading5Size,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: t.spaceControlGap),
                      Text(
                        mode == 'guided'
                            ? 'Kategorien nacheinander, Schritt für Schritt.'
                            : 'Beliebig wechseln, alles gemeinsam buchen.',
                        style: TextStyle(
                          fontSize: t.fontBodySmallSize,
                          height:
                              t.fontBodySmallLineHeight / t.fontBodySmallSize,
                          color: t.colorTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
