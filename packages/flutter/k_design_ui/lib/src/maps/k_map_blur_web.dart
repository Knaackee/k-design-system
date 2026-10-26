import 'dart:ui_web' as ui_web;
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:maplibre/maplibre.dart' as maplibre;
import 'package:web/web.dart' as web;

final _resizeObservers = Expando<web.ResizeObserver>();
final _resizePending = Expando<bool>();
final _resizeTarget = Expando<String>();
final _resizeAttempts = Expando<int>();

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

/// Lets MapLibre measure its platform view after Flutter has attached it.
///
/// The web plugin creates the map while its element is temporarily attached to
/// the document body, so its first canvas size can reflect the whole window.
void requestKMapRendererResize(maplibre.MapController controller) {
  if (controller case final State state when state.mounted) {
    final viewId = _platformViewId(state.context as Element);
    if (viewId == null) return;
    final element =
        ui_web.platformViewRegistry.getViewById(viewId) as web.HTMLElement;
    void resize() {
      if (!state.mounted ||
          !element.isConnected ||
          element.clientWidth <= 1 ||
          element.clientHeight <= 0 ||
          _resizePending[state] == true) {
        return;
      }
      final canvas = element.querySelector('canvas') as web.HTMLCanvasElement?;
      if (canvas == null ||
          (canvas.clientWidth == element.clientWidth &&
              canvas.clientHeight == element.clientHeight)) {
        return;
      }
      final target = '${element.clientWidth}x${element.clientHeight}';
      if (_resizeTarget[state] != target) {
        _resizeTarget[state] = target;
        _resizeAttempts[state] = 0;
      }
      if ((_resizeAttempts[state] ?? 0) >= 2) return;
      _resizeAttempts[state] = (_resizeAttempts[state] ?? 0) + 1;
      _resizePending[state] = true;
      // MapLibre 5.24 ignores its first ResizeObserver callback. Flutter attaches
      // this platform view after construction, so that ignored callback can be
      // the final viewport size. The Dart plugin has no public resize method.
      // One temporary container resize wakes MapLibre's own observer, which
      // calls its real map.resize(). Restore the exact width on the next frame;
      // never style the canvas, and cap retries for each actual viewport size.
      final width = element.style.width;
      element.style.width = '${element.getBoundingClientRect().width - 1}px';
      web.window.requestAnimationFrame(
        ((num _) {
          element.style.width = width;
          web.window.requestAnimationFrame(
            ((num _) {
              _resizePending[state] = false;
            }).toJS,
          );
        }).toJS,
      );
    }

    if (_resizeObservers[state] == null) {
      final observer = web.ResizeObserver(
        ((
              JSArray<web.ResizeObserverEntry> entries,
              web.ResizeObserver observer,
            ) {
              if (!state.mounted) {
                observer.disconnect();
                return;
              }
              resize();
            })
            .toJS,
      );
      _resizeObservers[state] = observer;
      observer.observe(element);
    }
    resize();
  }
}

Future<void> waitForKMapRendererResize(
  maplibre.MapController controller,
) async {
  requestKMapRendererResize(controller);
  for (var frame = 0; frame < 10; frame++) {
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    if (controller case final State state when state.mounted) {
      final viewId = _platformViewId(state.context as Element);
      if (viewId == null) continue;
      final element =
          ui_web.platformViewRegistry.getViewById(viewId) as web.HTMLElement;
      final canvas = element.querySelector('canvas') as web.HTMLCanvasElement?;
      if (canvas != null &&
          _resizePending[state] != true &&
          canvas.clientWidth == element.clientWidth &&
          canvas.clientHeight == element.clientHeight) {
        return;
      }
    } else {
      return;
    }
  }
}

void releaseKMapRendererResize(maplibre.MapController controller) {
  if (controller case final State state) {
    _resizeObservers[state]?.disconnect();
    _resizeObservers[state] = null;
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
