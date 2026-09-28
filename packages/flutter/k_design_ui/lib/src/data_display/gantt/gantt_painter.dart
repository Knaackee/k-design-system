import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'gantt_model.dart';

class GanttGeometry {
  GanttGeometry({
    required List<GanttTask> tasks,
    required DateTime start,
    required DateTime end,
    required this.width,
    required this.height,
    required this.rowHeight,
    required this.scale,
    required this.scroll,
    Set<String>? expanded,
  }) {
    this.start = scale == 'weeks'
        ? ganttAddDays(start, -(start.weekday % 7))
        : DateTime(start.year, start.month, start.day);
    final boundary = scale == 'weeks'
        ? ganttAddDays(end, (7 - end.weekday % 7) % 7)
        : end;
    span = math.max(1, ganttDayIndex(boundary) - ganttDayIndex(this.start));
    dayWidth = math.max(
      scale == 'days'
          ? 64.0
          : scale == 'weeks'
          ? 32.0
          : 16.0,
      width / span,
    );
    contentWidth = span * dayWidth;
    final byId = {for (final task in tasks) task.id: task};
    visible = tasks.where((task) {
      if (expanded == null) return true;
      var parent = task.parent;
      final visited = <String>{task.id};
      while (parent != null && byId.containsKey(parent)) {
        if (!visited.add(parent) || !expanded.contains(parent)) return false;
        parent = byId[parent]!.parent;
      }
      return true;
    }).toList();
    contentHeight = axisHeight + visible.length * rowHeight;
    for (var i = 0; i < visible.length; i++) {
      rects[visible[i].id] = rectFor(
        visible[i],
        axisHeight + i * rowHeight + 4 - scroll.dy,
      );
    }
  }

  static const double axisHeight = 56;
  final double width, height, rowHeight;
  final String scale;
  final Offset scroll;
  late final DateTime start;
  late final int span;
  late final double dayWidth, contentWidth, contentHeight;
  late final List<GanttTask> visible;
  final Map<String, Rect> rects = {};

  double x(DateTime date) =>
      (ganttDayIndex(date) - ganttDayIndex(start)) * dayWidth - scroll.dx;

  Rect rectFor(GanttTask task, double top) {
    final barHeight = rowHeight - 7;
    if (task.type == 'milestone') {
      return Rect.fromLTWH(
        x(task.start) - barHeight / 2,
        top,
        barHeight,
        barHeight,
      );
    }
    return Rect.fromLTWH(
      x(task.start),
      top,
      math.max(
            1,
            ganttDayIndex(task.end ?? ganttAddDays(task.start, 1)) -
                ganttDayIndex(task.start),
          ) *
          dayWidth,
      barHeight,
    );
  }
}

class GanttPainter extends CustomPainter {
  GanttPainter({
    required this.tokens,
    required this.geometry,
    required this.links,
    this.selected,
    this.editing,
    this.preview,
    this.monthLabel,
  });
  final KDesignTokens tokens;
  final GanttGeometry geometry;
  final List<GanttLink> links;
  final String? selected, editing;
  final GanttTask? preview;
  final String Function(DateTime)? monthLabel;

  void _text(Canvas canvas, String value, Rect rect, {bool caption = false}) {
    if (rect.width <= 0) return;
    final t = tokens;
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: t.fontFamily,
          fontSize: caption ? t.fontCaptionSize : t.fontBodySmallSize,
          color: caption ? t.colorTextMuted : t.colorTextPrimary,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = tokens;
    final g = geometry;
    final border = Paint()
      ..color = t.colorBorderDefault
      ..strokeWidth = t.borderWidthDefault;
    canvas.drawRect(Offset.zero & size, Paint()..color = t.colorSurfaceCanvas);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        0,
        GanttGeometry.axisHeight,
        size.width,
        math.max(0, size.height - GanttGeometry.axisHeight),
      ),
    );
    final step = g.scale == 'months' ? 7 : 1;
    for (var day = 0; day <= g.span; day += step) {
      final x = day * g.dayWidth - g.scroll.dx;
      canvas.drawLine(
        Offset(x, GanttGeometry.axisHeight),
        Offset(x, size.height),
        border,
      );
    }
    for (var row = 0; row <= g.visible.length; row++) {
      final y = GanttGeometry.axisHeight + row * g.rowHeight - g.scroll.dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), border);
      if (row < g.visible.length && g.visible[row].id == selected) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, g.rowHeight),
          Paint()
            ..color = t.colorActionPrimaryBackground.withValues(alpha: .08),
        );
      }
    }
    for (final link in links) {
      final source = g.rects[link.source], target = g.rects[link.target];
      if (source != null && target != null) _link(canvas, link, source, target);
    }
    for (final task in g.visible) {
      if (task.id == preview?.id) continue;
      _bar(canvas, task, g.rects[task.id]!);
    }
    final ghost = preview;
    if (ghost != null && g.rects.containsKey(ghost.id)) {
      canvas.saveLayer(
        null,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: .65),
      );
      _bar(canvas, ghost, g.rectFor(ghost, g.rects[ghost.id]!.top));
      canvas.restore();
    }
    canvas.restore();
    _axis(canvas, size, border);
  }

  void _bar(Canvas canvas, GanttTask task, Rect rect) {
    final t = tokens;
    final active = editing == task.id;
    if (task.type == 'milestone') {
      final path = Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.center.dx, rect.bottom)
        ..lineTo(rect.left, rect.center.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = t.colorStatusSuccessAccent);
      return;
    }
    final summary = task.type == 'summary';
    final accent = summary
        ? t.colorStatusInfoAccent
        : t.colorActionPrimaryBackground;
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(t.radiusControl),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..color = summary
            ? t.colorSurfaceRaised
            : Color.lerp(t.colorSurfaceRaised, accent, .14)!,
    );
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width * task.progress.clamp(0, 100) / 100,
        rect.height,
      ),
      Paint()
        ..color = Color.lerp(
          t.colorSurfaceRaised,
          accent,
          summary ? .28 : .32,
        )!,
    );
    _text(canvas, task.text, rect.deflate(t.spaceControlInsetInline));
    canvas.restore();
    canvas.drawRRect(
      shape,
      Paint()
        ..color = summary ? t.colorBorderDefault : accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? t.borderWidthStrong : t.borderWidthDefault,
    );
    if (active && !task.readOnly && !summary) {
      for (final x in [rect.left, rect.right]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, rect.center.dy),
              width: 6,
              height: 20,
            ),
            Radius.circular(t.radiusFull),
          ),
          Paint()..color = accent,
        );
      }
    }
  }

  void _link(Canvas canvas, GanttLink link, Rect source, Rect target) {
    final fromEnd = link.type.startsWith('e');
    final toEnd = link.type.endsWith('e');
    final a = Offset(fromEnd ? source.right : source.left, source.center.dy);
    final b = Offset(toEnd ? target.right : target.left, target.center.dy);
    final out = a.dx + (fromEnd ? 12 : -12);
    final into = b.dx + (toEnd ? 12 : -12);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(out, a.dy);
    if (fromEnd != toEnd && (fromEnd ? out <= into : out >= into)) {
      final middle = (out + into) / 2;
      path
        ..lineTo(middle, a.dy)
        ..lineTo(middle, b.dy);
    } else {
      final middleY = source.bottom + 3;
      path
        ..lineTo(out, middleY)
        ..lineTo(into, middleY)
        ..lineTo(into, b.dy);
    }
    path.lineTo(b.dx, b.dy);
    final paint = Paint()
      ..color = tokens.colorTextMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.borderWidthDefault;
    canvas.drawPath(path, paint);
    final back = b.dx + (toEnd ? 5 : -5);
    canvas.drawPath(
      Path()
        ..moveTo(back, b.dy - 3)
        ..lineTo(b.dx, b.dy)
        ..lineTo(back, b.dy + 3),
      paint,
    );
  }

  void _axis(Canvas canvas, Size size, Paint border) {
    final g = geometry;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, GanttGeometry.axisHeight));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, GanttGeometry.axisHeight),
      Paint()..color = tokens.colorSurfaceCanvas,
    );
    const months = [
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
    var month = DateTime(g.start.year, g.start.month);
    final end = ganttAddDays(g.start, g.span);
    while (month.isBefore(end)) {
      final next = DateTime(month.year, month.month + 1);
      final left = math.max(-g.scroll.dx, g.x(month));
      final right = math.min(g.contentWidth - g.scroll.dx, g.x(next));
      _text(
        canvas,
        monthLabel?.call(month) ?? '${months[month.month - 1]} ${month.year}',
        Rect.fromLTRB(left, 0, right, 28),
        caption: true,
      );
      canvas.drawLine(Offset(right, 0), Offset(right, 28), border);
      month = next;
    }
    final step = g.scale == 'months' ? 7 : 1;
    for (var day = 0; day < g.span; day += step) {
      final x = day * g.dayWidth - g.scroll.dx;
      final width = math.min(step, g.span - day) * g.dayWidth;
      _text(
        canvas,
        '${ganttAddDays(g.start, day).day}',
        Rect.fromLTWH(x, 28, width, 28),
        caption: true,
      );
      canvas.drawLine(
        Offset(x, 28),
        Offset(x, GanttGeometry.axisHeight),
        border,
      );
    }
    canvas.restore();
    for (final y in [28.0, GanttGeometry.axisHeight]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), border);
    }
  }

  @override
  bool shouldRepaint(covariant GanttPainter oldDelegate) => true;
}
