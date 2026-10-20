import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:maplibre/maplibre.dart' as maplibre;
import 'package:web/web.dart' as web;

/// Applies a CSS filter to the exact platform view owned by this controller.
/// No document query or creation-order assumption is used, so multiple maps
/// can be filtered independently.
void applyKMapBlur(maplibre.MapController controller, double sigma) {
  if (controller case final State state when state.mounted) {
    final viewId = _platformViewId(state.context as Element);
    if (viewId == null) return;
    final element =
        ui_web.platformViewRegistry.getViewById(viewId) as web.HTMLElement;
    element.style.filter = sigma > 0 ? 'blur(${sigma}px)' : '';
  }
}

class KMapNativeBlurOverlay extends StatelessWidget {
  const KMapNativeBlurOverlay({required this.sigma, super.key});
  final double sigma;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

int? _platformViewId(Element root) {
  int? result;
  void visit(Element element) {
    if (result != null) return;
    if (element.widget case final PlatformViewSurface surface) {
      result = surface.controller.viewId;
      return;
    }
    element.visitChildElements(visit);
  }

  root.visitChildElements(visit);
  return result;
}
