import 'package:flutter/widgets.dart';
import 'k_map_overlays.dart';

/// Captures the grab offset once, independently of controlled marker echoes.
class KMapPinDragSession {
  KMapPinDragSession({
    required this.pointer,
    required Offset projected,
    required Rect viewport,
  }) : grabOffset = projected - (pointer - viewport.topLeft);
  Offset pointer;
  final Offset grabOffset;
  Offset localAnchor(Rect viewport) => pointer - viewport.topLeft + grabOffset;
}

Offset kMapEdgePanVelocity(
  Offset pointer,
  Size size,
  KMapPinEdgePanOptions options,
) {
  double axis(double value, double length) {
    if (value < options.padding) {
      return -options.maxSpeed *
          (1 - value.clamp(0, options.padding) / options.padding);
    }
    if (value > length - options.padding) {
      return options.maxSpeed *
          (1 - (length - value).clamp(0, options.padding) / options.padding);
    }
    return 0;
  }

  return Offset(axis(pointer.dx, size.width), axis(pointer.dy, size.height));
}

/// Edge navigation never zooms in when the host starts below the floor.
double kMapEdgePanZoom(
  double zoom,
  KMapPinEdgePanOptions options,
  double seconds,
) => zoom <= options.minZoom
    ? zoom
    : (zoom - options.zoomOutPerSecond * seconds)
          .clamp(options.minZoom, zoom)
          .toDouble();
