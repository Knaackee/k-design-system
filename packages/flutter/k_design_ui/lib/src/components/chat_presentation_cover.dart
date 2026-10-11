part of 'chat_presentations.dart';

// Supports intrinsic sizing in a carousel while retaining the cover ratio.
class _CoverFrame extends SingleChildRenderObjectWidget {
  const _CoverFrame({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _CoverRender();
}

class _CoverRender extends RenderProxyBox {
  double _height(double width) =>
      width.isFinite ? math.max(280, width * 9 / 16) : 280;

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(_height(width), super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(_height(width), super.computeMaxIntrinsicHeight(width));

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      constraints.copyWith(
        minHeight: math.min(
          constraints.maxHeight,
          math.max(constraints.minHeight, _height(constraints.maxWidth)),
        ),
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(
    child!.getDryLayout(_childConstraints(constraints)),
  );

  @override
  void performLayout() {
    child!.layout(_childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(child!.size);
  }
}
