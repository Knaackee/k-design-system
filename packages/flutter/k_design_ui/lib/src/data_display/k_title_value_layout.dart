import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Places a row's copy and its trailing value side by side when both fit on
/// one line, and stacks the value under the copy otherwise (iOS value cell,
/// `UIListContentConfiguration.prefersSideBySideTextAndSecondaryText`).
///
/// Neither part is cut: the copy keeps every word whole, the value starts
/// under the copy when space runs out (Decision 0015).
class KTitleValueLayout extends MultiChildRenderObjectWidget {
  KTitleValueLayout({
    required Widget copy,
    required Widget value,
    required this.gap,
    required this.stackGap,
    required this.band,
    this.stacked = false,
    super.key,
  }) : super(children: [copy, value]);

  /// Space between copy and value side by side.
  final double gap;

  /// Space between copy and value when stacked.
  final double stackGap;

  /// Height of the first copy line; a side-by-side value centres on it.
  final double band;

  /// Always stack (Material rows, large text).
  final bool stacked;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderKTitleValue(
    gap: gap,
    stackGap: stackGap,
    band: band,
    stacked: stacked,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderKTitleValue renderObject,
  ) {
    renderObject
      ..gap = gap
      ..stackGap = stackGap
      ..band = band
      ..stacked = stacked
      ..textDirection = Directionality.of(context);
  }
}

class _TitleValueParentData extends ContainerBoxParentData<RenderBox> {}

class RenderKTitleValue extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TitleValueParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TitleValueParentData> {
  RenderKTitleValue({
    required double gap,
    required double stackGap,
    required double band,
    required bool stacked,
    required TextDirection textDirection,
  }) : _gap = gap, // ignore: prefer_initializing_formals
       _stackGap = stackGap, // ignore: prefer_initializing_formals
       _band = band, // ignore: prefer_initializing_formals
       _stacked = stacked, // ignore: prefer_initializing_formals
       _textDirection = textDirection; // ignore: prefer_initializing_formals

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _stackGap;
  set stackGap(double value) {
    if (value == _stackGap) return;
    _stackGap = value;
    markNeedsLayout();
  }

  double _band;
  set band(double value) {
    if (value == _band) return;
    _band = value;
    markNeedsLayout();
  }

  bool _stacked;
  set stacked(bool value) {
    if (value == _stacked) return;
    _stacked = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Whether the last layout placed the value beside the copy.
  bool sideBySide = false;

  RenderBox get _copy => firstChild!;
  RenderBox get _value => childAfter(firstChild!)!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TitleValueParentData) {
      child.parentData = _TitleValueParentData();
    }
  }

  bool _fits(double width) {
    if (_stacked) return false;
    final copy = _copy.getMaxIntrinsicWidth(double.infinity);
    final value = _value.getMaxIntrinsicWidth(double.infinity);
    return copy + _gap + value <= width;
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _copy.getMinIntrinsicWidth(height),
    _value.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _copy.getMaxIntrinsicWidth(height) +
      _gap +
      _value.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _measure(width, (box, w) => box.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _measure(width, (box, w) => box.getMaxIntrinsicHeight(w));

  double _measure(double width, double Function(RenderBox, double) height) {
    if (_fits(width)) {
      final value = _value.getMaxIntrinsicWidth(double.infinity);
      return math.max(
        height(_copy, width - value - _gap),
        height(_value, value),
      );
    }
    return height(_copy, width) + _stackGap + height(_value, width);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (_fits(width)) {
      final valueWidth = _value.getMaxIntrinsicWidth(double.infinity);
      final copy = _copy.getDryLayout(
        BoxConstraints(maxWidth: width - valueWidth - _gap),
      );
      final value = _value.getDryLayout(BoxConstraints(maxWidth: valueWidth));
      return constraints.constrain(
        Size(width, math.max(copy.height, value.height)),
      );
    }
    final copy = _copy.getDryLayout(BoxConstraints(maxWidth: width));
    final value = _value.getDryLayout(BoxConstraints(maxWidth: width));
    return constraints.constrain(
      Size(width, copy.height + _stackGap + value.height),
    );
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final copyData = _copy.parentData! as _TitleValueParentData;
    final valueData = _value.parentData! as _TitleValueParentData;
    final rtl = _textDirection == TextDirection.rtl;
    sideBySide = _fits(width);
    if (sideBySide) {
      final valueWidth = _value.getMaxIntrinsicWidth(double.infinity);
      _value.layout(BoxConstraints(maxWidth: valueWidth), parentUsesSize: true);
      _copy.layout(
        BoxConstraints(maxWidth: math.max(0, width - valueWidth - _gap)),
        parentUsesSize: true,
      );
      final dy = math.max(0.0, (_band - _value.size.height) / 2);
      copyData.offset = Offset(rtl ? width - _copy.size.width : 0, 0);
      valueData.offset = Offset(rtl ? 0 : width - _value.size.width, dy);
      size = constraints.constrain(
        Size(width, math.max(_copy.size.height, dy + _value.size.height)),
      );
      return;
    }
    _copy.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
    _value.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
    copyData.offset = Offset(rtl ? width - _copy.size.width : 0, 0);
    valueData.offset = Offset(
      rtl ? width - _value.size.width : 0,
      _copy.size.height + _stackGap,
    );
    size = constraints.constrain(
      Size(width, _copy.size.height + _stackGap + _value.size.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
