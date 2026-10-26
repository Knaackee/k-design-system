import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Measures layout, including wrapping after a viewport width change.
class KNotificationHeight extends SingleChildRenderObjectWidget {
  const KNotificationHeight({
    required this.onHeightChanged,
    required super.child,
    super.key,
  });
  final ValueChanged<double>? onHeightChanged;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _HeightReporter(onHeightChanged);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _HeightReporter).callback = onHeightChanged;
  }
}

class _HeightReporter extends RenderProxyBox {
  _HeightReporter(this.callback);
  ValueChanged<double>? callback;
  double? _height;
  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (_height == height) return;
    _height = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) callback?.call(height);
    });
  }
}
