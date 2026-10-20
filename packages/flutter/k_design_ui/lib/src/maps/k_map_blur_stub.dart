import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart' as maplibre;

void applyKMapBlur(maplibre.MapController controller, double sigma) {}

class KMapNativeBlurOverlay extends StatelessWidget {
  const KMapNativeBlurOverlay({required this.sigma, super.key});
  final double sigma;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: const ColoredBox(color: Colors.transparent),
    ),
  );
}
