import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_editor_types.dart';

/// Capture re_editor's actual laid-out paragraphs without altering its text.
class KCodeParagraphCapture extends StatefulWidget {
  const KCodeParagraphCapture({
    required this.source,
    required this.target,
    required this.child,
    super.key,
  });
  final CodeIndicatorValueNotifier source;
  final ValueNotifier<CodeIndicatorValue?> target;
  final Widget child;
  @override
  State<KCodeParagraphCapture> createState() => _CaptureState();
}

class _CaptureState extends State<KCodeParagraphCapture> {
  @override
  void initState() {
    super.initState();
    widget.source.addListener(_changed);
    _changed();
  }

  @override
  void didUpdateWidget(KCodeParagraphCapture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      oldWidget.source.removeListener(_changed);
      widget.source.addListener(_changed);
      _changed();
    }
  }

  void _changed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.target.value = widget.source.value;
    });
  }

  @override
  void dispose() {
    widget.source.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(child: widget.child);
}

/// Carets use paragraph geometry, including syntax metrics, wrapping and scroll.
class KCodeRemoteCarets extends StatelessWidget {
  const KCodeRemoteCarets({
    required this.paragraphs,
    required this.scrollController,
    required this.selections,
    required this.source,
    required this.indicatorKey,
    required this.dividerWidth,
    required this.width,
    super.key,
  });
  final ValueNotifier<CodeIndicatorValue?> paragraphs;
  final CodeScrollController scrollController;
  final List<KRemoteSelection> selections;
  final String source;
  final GlobalKey indicatorKey;
  final double dividerWidth, width;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: Listenable.merge([
        paragraphs,
        scrollController.verticalScroller,
        scrollController.horizontalScroller,
      ]),
      builder: (context, _) {
        final tokens =
            Theme.of(context).extension<KDesignTokens>() ??
            KDesignTokens.orbitLight;
        final indicator = indicatorKey.currentContext?.findRenderObject();
        final gutter = indicator is RenderBox && indicator.hasSize
            ? indicator.size.width
            : 0.0;
        return CustomPaint(
          painter: _CaretPainter(
            paragraphs: paragraphs.value?.paragraphs ?? const [],
            selections: selections,
            source: source,
            width: width,
            tokens: tokens,
            origin: Offset(gutter + dividerWidth, 0),
          ),
        );
      },
    ),
  );
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter({
    required this.paragraphs,
    required this.selections,
    required this.source,
    required this.origin,
    required this.width,
    required this.tokens,
  });
  final KDesignTokens tokens;
  final List<CodeLineRenderParagraph> paragraphs;
  final List<KRemoteSelection> selections;
  final String source;
  final Offset origin;
  final double width;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final viewport = Rect.fromLTWH(
      origin.dx,
      0,
      (size.width - origin.dx).clamp(0.0, double.infinity),
      size.height,
    );
    canvas.clipRect(viewport);
    final lines = source.split(RegExp(r'\r\n|\r|\n')), starts = <int>[];
    final separators = RegExp(r'\r\n|\r|\n').allMatches(source).toList();
    var start = 0;
    for (var index = 0; index < lines.length; index++) {
      starts.add(start);
      start +=
          lines[index].length +
          (index < separators.length ? separators[index].group(0)!.length : 0);
    }
    for (final selection in selections) {
      if (selection.isCollapsed ||
          selection.start < 0 ||
          selection.end > source.length) {
        continue;
      }
      for (final paragraph in paragraphs) {
        if (paragraph.index >= lines.length) continue;
        final lineStart = starts[paragraph.index],
            length = lines[paragraph.index].length;
        final from = (selection.start - lineStart).clamp(0, length),
            to = (selection.end - lineStart).clamp(0, length);
        if (to <= from) continue;
        for (final rect in paragraph.getRangeRects(
          TextRange(start: from, end: to),
        )) {
          canvas.drawRect(
            rect.shift(paragraph.offset + origin),
            Paint()
              ..color = selection.participant.color.withValues(
                alpha: tokens.opacityMedium,
              ),
          );
        }
      }
    }
    for (final selection in selections) {
      if (selection.head < 0 || selection.head > source.length) continue;
      var line = 0;
      for (var index = 1; index < starts.length; index++) {
        if (starts[index] <= selection.head) line = index;
      }
      final column = (selection.head - starts[line]).clamp(
        0,
        lines[line].length,
      );
      for (final paragraph in paragraphs) {
        if (paragraph.index != line) continue;
        final caret = paragraph.getOffset(TextPosition(offset: column));
        if (caret == null) continue;
        final position = caret + paragraph.offset + origin;
        if (position.dx < viewport.left ||
            position.dx > viewport.right ||
            position.dy + paragraph.paragraph.preferredLineHeight < 0 ||
            position.dy > size.height) {
          continue;
        }
        canvas.drawRect(
          Rect.fromLTWH(
            position.dx,
            position.dy,
            width,
            paragraph.paragraph.preferredLineHeight,
          ),
          Paint()..color = selection.participant.color,
        );
        final label =
            TextPainter(
              text: TextSpan(
                text: selection.participant.name,
                style: TextStyle(
                  color:
                      selection.participant.foregroundColor ??
                      tokens.componentEditorCaretForeground,
                  fontSize: tokens.fontCaptionSize,
                  fontFamily: tokens.fontFamily,
                  fontWeight: tokens.fontLabelWeight,
                  height: tokens.componentEditorCaretLineHeight,
                ),
              ),
              textDirection: TextDirection.ltr,
              maxLines: 1,
              ellipsis: '…',
            )..layout(
              maxWidth: (viewport.width - tokens.spaceControlGap * 2).clamp(
                0.0,
                double.infinity,
              ),
            );
        final labelWidth = label.width + tokens.spaceControlGap * 2;
        final labelHeight = label.height + tokens.spaceMicro * 2;
        final labelLeft = position.dx.clamp(
          viewport.left,
          (size.width - labelWidth).clamp(viewport.left, double.infinity),
        );
        final labelTop = (position.dy - labelHeight).clamp(
          0.0,
          (size.height - labelHeight).clamp(0.0, double.infinity),
        );
        final box = Rect.fromLTWH(labelLeft, labelTop, labelWidth, labelHeight);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            box,
            topLeft: Radius.circular(tokens.radiusSmall),
            topRight: Radius.circular(tokens.radiusSmall),
            bottomRight: Radius.circular(tokens.radiusSmall),
          ),
          Paint()..color = selection.participant.color,
        );
        label.paint(
          canvas,
          Offset(
            labelLeft + tokens.spaceControlGap,
            labelTop + tokens.spaceMicro,
          ),
        );
        label.dispose();
        break;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) => true;
}
