import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'timeline_model.dart';

class TimelineGeometry {
  TimelineGeometry(
    List<TimelineEntry> entries,
    List<TimelineGroup> groups,
    this.width,
    this.start,
    int days,
    this.barHeight,
    this.gap,
    this.scroll,
  ) : labelWidth = width <= 480 ? 96 : 120,
      span = math.max(1, days) {
    final layout = layoutTimeline(
      entries,
      groups,
      minimumGapDays: 10 / dayWidth,
      pointSpanDays: 94 / dayWidth,
    );
    var top = axisHeight - scroll;
    for (final group in groups) {
      final height =
          math.max(1, layout.laneCounts[group.id] ?? 1) * (barHeight + 10) +
          (group == groups.first ? 15 : 0);
      groupRects[group.id] = Rect.fromLTWH(0, top, width, height);
      top += height;
    }
    contentHeight = top + scroll;
    for (final placed in layout.entries) {
      final group = groupRects[placed.entry.group];
      if (group == null) continue;
      rects[placed.entry.id] = rectFor(
        placed.entry,
        group.top +
            (placed.entry.group == groups.first.id ? 20 : 5) +
            placed.lane * (barHeight + 10),
      );
    }
  }
  static const double axisHeight = 64;
  final double width, labelWidth, barHeight, gap, scroll;
  final DateTime start;
  final int span;
  late final double contentHeight;
  final Map<String, Rect> groupRects = {}, rects = {};
  double get dayWidth => math.max(1, width - labelWidth) / span;
  double x(DateTime date) =>
      labelWidth + (dayIndex(date) - dayIndex(start)) * dayWidth;
  Rect rectFor(TimelineEntry entry, double top) => Rect.fromLTWH(
    x(entry.start),
    top,
    entry.end == null
        ? 94
        : math.max(
            2,
            (dayIndex(entry.end!) - dayIndex(entry.start)) * dayWidth,
          ),
    barHeight,
  );
  String? groupAt(double y) {
    for (final entry in groupRects.entries) {
      if (y >= entry.value.top && y < entry.value.bottom) return entry.key;
    }
    return null;
  }
}

class TimelinePainter extends CustomPainter {
  TimelinePainter(
    this.t,
    this.g,
    this.entries,
    this.groups,
    this.selected,
    this.editing,
    this.preview,
    this.today,
  );
  final KDesignTokens t;
  final TimelineGeometry g;
  final List<TimelineEntry> entries;
  final List<TimelineGroup> groups;
  final String? selected, editing;
  final TimelineEntry? preview;
  final DateTime today;

  void text(
    Canvas c,
    String value,
    Offset pos,
    double width, {
    Color? color,
    bool caption = false,
    bool crop = false,
  }) {
    if (!crop && width <= 0) return;
    final p = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: t.fontFamily,
          fontSize: caption ? t.fontCaptionSize : t.fontBodySmallSize,
          height: caption
              ? t.fontCaptionLineHeight / t.fontCaptionSize
              : t.fontBodySmallLineHeight / t.fontBodySmallSize,
          color: color ?? t.colorTextMuted,
        ),
      ),
      maxLines: 1,
      ellipsis: crop ? null : '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: crop ? double.infinity : width);
    p.paint(c, pos);
  }

  Color accent(TimelineEntry e) => switch (e.tone) {
    'info' => t.colorStatusInfoAccent,
    'success' => t.colorStatusSuccessAccent,
    _ => t.colorActionPrimaryBackground,
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = t.colorSurfaceCanvas);
    final border = Paint()
      ..color = t.colorBorderDefault
      ..strokeWidth = t.borderWidthDefault;
    final plot = Rect.fromLTWH(
      g.labelWidth,
      TimelineGeometry.axisHeight,
      size.width - g.labelWidth,
      size.height - TimelineGeometry.axisHeight,
    );
    canvas.save();
    canvas.clipRect(plot);
    final step = math.max(1, (28 / g.dayWidth).ceil());
    for (var i = 0; i <= g.span; i++) {
      if ((addTimelineDays(g.start, i).day - 1) % step != 0) continue;
      final x = g.labelWidth + i * g.dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), border);
    }
    for (final rect in g.groupRects.values) {
      canvas.drawLine(
        Offset(g.labelWidth, rect.bottom),
        Offset(size.width, rect.bottom),
        border,
      );
    }
    final todayX = g.x(today);
    canvas.drawLine(
      Offset(todayX, 0),
      Offset(todayX, size.height),
      Paint()
        ..color = t.colorActionPrimaryBackground
        ..strokeWidth = t.borderWidthStrong,
    );
    for (final entry in entries) {
      if (preview?.id == entry.id) continue;
      final rect = g.rects[entry.id];
      if (rect != null) item(canvas, entry, rect, false);
    }
    if (preview case final p?) {
      final original = g.rects[p.id];
      final group = g.groupRects[p.group];
      if (original != null && group != null) {
        final top = p.group == entries.firstWhere((e) => e.id == p.id).group
            ? original.top
            : group.top + 10;
        item(canvas, p, g.rectFor(p, top), true);
      }
    }
    canvas.restore();
    // Frozen labels and axis paint last, clipping overflowing bars and handles.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, g.labelWidth, size.height),
      Paint()..color = t.colorSurfaceRaised,
    );
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        0,
        TimelineGeometry.axisHeight,
        g.labelWidth,
        size.height - TimelineGeometry.axisHeight,
      ),
    );
    for (final group in groups) {
      final rect = g.groupRects[group.id]!;
      text(
        canvas,
        group.label,
        Offset(t.spaceControlInsetInline, rect.top + t.spaceControlInsetInline),
        g.labelWidth - 2 * t.spaceControlInsetInline,
      );
      canvas.drawLine(
        Offset(0, rect.bottom),
        Offset(g.labelWidth, rect.bottom),
        border,
      );
    }
    canvas.restore();
    canvas.drawRect(
      Rect.fromLTWH(
        g.labelWidth,
        0,
        size.width - g.labelWidth,
        TimelineGeometry.axisHeight,
      ),
      Paint()..color = t.colorSurfaceCanvas,
    );
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        g.labelWidth,
        0,
        size.width - g.labelWidth,
        TimelineGeometry.axisHeight,
      ),
    );
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    for (var i = 0; i <= g.span; i++) {
      final date = addTimelineDays(g.start, i);
      if ((date.day - 1) % step != 0) continue;
      final x = g.labelWidth + i * g.dayWidth;
      canvas.drawLine(
        Offset(x, 32),
        Offset(x, TimelineGeometry.axisHeight),
        border,
      );
      text(
        canvas,
        '${date.day}',
        Offset(x + t.spaceControlGap, 40),
        math.max(24, g.dayWidth * step - 2),
        caption: true,
      );
    }
    var month = DateTime(g.start.year, g.start.month);
    final end = addTimelineDays(g.start, g.span);
    while (!month.isAfter(end)) {
      text(
        canvas,
        '${months[month.month - 1]} ${month.year}',
        Offset(g.x(month) + t.spaceControlGap, 8),
        120,
        caption: true,
      );
      month = DateTime(month.year, month.month + 1);
    }
    canvas.restore();
    canvas.drawLine(
      Offset(0, TimelineGeometry.axisHeight),
      Offset(size.width, TimelineGeometry.axisHeight),
      border,
    );
    canvas.drawLine(
      Offset(g.labelWidth, 0),
      Offset(g.labelWidth, size.height),
      border,
    );
    canvas.drawLine(Offset.zero, Offset(size.width, 0), border);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      border,
    );
    if (todayX >= g.labelWidth && todayX <= size.width) {
      canvas.drawLine(
        Offset(todayX, 0),
        Offset(todayX, size.height),
        Paint()
          ..color = t.colorActionPrimaryBackground
          ..strokeWidth = t.borderWidthStrong,
      );
    }
  }

  void item(Canvas c, TimelineEntry e, Rect rect, bool ghost) {
    final color = accent(e);
    final active = editing == e.id;
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(t.radiusControl),
    );
    c.drawRRect(
      shape,
      Paint()
        ..color = Color.lerp(
          t.colorSurfaceRaised,
          color,
          active ? .26 : .16,
        )!.withValues(alpha: ghost ? .7 : 1),
    );
    final outline = Paint()
      ..color = color.withValues(alpha: active ? 1 : .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? t.borderWidthStrong : t.borderWidthDefault;
    if (e.readOnly) {
      final path = Path()..addRRect(shape);
      for (final metric in path.computeMetrics()) {
        for (var start = 0.0; start < metric.length; start += 7) {
          c.drawPath(
            metric.extractPath(start, math.min(start + 4, metric.length)),
            outline,
          );
        }
      }
    } else {
      c.drawRRect(shape, outline);
    }
    c.save();
    c.clipRRect(shape);
    if (e.end == null) {
      c.save();
      c.translate(rect.left + 7, rect.center.dy);
      c.rotate(math.pi / 4);
      c.drawRect(const Rect.fromLTWH(-3, -3, 6, 6), Paint()..color = color);
      c.restore();
    }
    final inset = t.spaceControlInsetInline + (e.end == null ? 5 : 0);
    text(
      c,
      e.label,
      Offset(rect.left + inset, rect.center.dy - t.fontBodySmallLineHeight / 2),
      rect.width - inset * 2,
      color: t.colorTextPrimary,
      crop: true,
    );
    c.restore();
    if (editing == e.id && !e.readOnly && e.end != null) {
      for (final x in [rect.left, rect.right]) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, rect.center.dy),
              width: 6,
              height: 20,
            ),
            Radius.circular(t.radiusFull),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) => true;
}
