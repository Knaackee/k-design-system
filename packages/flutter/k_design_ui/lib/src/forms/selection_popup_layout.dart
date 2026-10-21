import 'dart:math' as math;
import 'dart:ui' show FlutterView;
import 'package:flutter/material.dart';

/// Overlay-local placement within the window's unobscured viewport.
class SelectionPopupLayout {
  SelectionPopupLayout(
    RenderBox anchor,
    RenderBox overlay,
    FlutterView view,
    double gap, {
    double? preferredWidth,
  }) {
    final origin = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final overlayOrigin = overlay.localToGlobal(Offset.zero);
    final screen = overlay.size;
    // Read window metrics: a dialog may remove inherited viewInsets after
    // resizing its body, while its popup still uses the full route overlay.
    final media = MediaQueryData.fromView(view);
    final viewportTop = math.max(
      8.0,
      media.viewPadding.top - overlayOrigin.dy + 8,
    );
    final viewportBottom = math.max(
      viewportTop,
      math.min(
        screen.height - 8,
        media.size.height - media.viewInsets.bottom - overlayOrigin.dy - 8,
      ),
    );
    final belowTop = (origin.dy + anchor.size.height + gap).clamp(
      viewportTop,
      viewportBottom,
    );
    final aboveBottom = (origin.dy - gap).clamp(viewportTop, viewportBottom);
    final below = viewportBottom - belowTop;
    final above = aboveBottom - viewportTop;
    final opensAbove = below < 120 && above > below;
    width = math.max(
      0.0,
      math.min(
        math.max(anchor.size.width, preferredWidth ?? 0),
        screen.width - 16,
      ),
    );
    left = origin.dx.clamp(8.0, math.max(8.0, screen.width - width - 8));
    top = opensAbove ? null : belowTop;
    bottom = opensAbove ? screen.height - aboveBottom : null;
    maxHeight = math.min(280.0, opensAbove ? above : below);
  }

  late final double width, left, maxHeight;
  late final double? top, bottom;
}
