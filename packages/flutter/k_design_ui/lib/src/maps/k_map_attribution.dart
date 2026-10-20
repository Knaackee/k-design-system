import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:maplibre/maplibre.dart' as maplibre;
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';

/// Compact source attribution for use inside [maplibre.MapLibreMap.children].
class KMapAttribution extends StatefulWidget {
  const KMapAttribution({super.key});

  @override
  State<KMapAttribution> createState() => _KMapAttributionState();
}

class _KMapAttributionState extends State<KMapAttribution> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    if (_expanded) {
      return maplibre.SourceAttribution(
        padding: EdgeInsets.all(tokens.spaceCardPadding),
        keepExpanded: true,
      );
    }

    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceCardPadding),
          child: PointerInterceptor(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.colorSurfaceRaised,
                border: Border.all(
                  color: tokens.colorBorderDefault,
                  width: tokens.borderWidthDefault,
                ),
                borderRadius: BorderRadius.circular(tokens.radiusControl),
              ),
              child: KIconButton(
                label: 'Kartenquellen anzeigen',
                icon: KIconName.info,
                onPressed: () => setState(() => _expanded = true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
