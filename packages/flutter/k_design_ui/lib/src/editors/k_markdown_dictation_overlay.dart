import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import '../forms/k_dictation_action.dart';

/// Internal source-renderer bridge; dictation is a Markdown editor feature.
class KMarkdownSourceGeometry extends InheritedWidget {
  const KMarkdownSourceGeometry({
    required this.scrollController,
    required this.paragraphs,
    required super.child,
    this.bottomInset = 0,
    super.key,
  });

  final double bottomInset;
  final CodeScrollController scrollController;
  final ValueNotifier<CodeIndicatorValue?> paragraphs;

  static KMarkdownSourceGeometry? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KMarkdownSourceGeometry>();

  Widget capture(CodeIndicatorValueNotifier notifier) =>
      _Capture(source: notifier, target: paragraphs);

  @override
  bool updateShouldNotify(KMarkdownSourceGeometry oldWidget) =>
      scrollController != oldWidget.scrollController ||
      paragraphs != oldWidget.paragraphs ||
      bottomInset != oldWidget.bottomInset;
}

class _Capture extends StatefulWidget {
  const _Capture({required this.source, required this.target});
  final CodeIndicatorValueNotifier source;
  final ValueNotifier<CodeIndicatorValue?> target;

  @override
  State<_Capture> createState() => _CaptureState();
}

class _CaptureState extends State<_Capture> {
  @override
  void initState() {
    super.initState();
    widget.source.addListener(_changed);
    _changed();
  }

  @override
  void didUpdateWidget(_Capture oldWidget) {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class KMarkdownDictationOverlay extends StatelessWidget {
  const KMarkdownDictationOverlay({
    required this.scrollController,
    required this.paragraphs,
    required this.source,
    required this.offset,
    required this.state,
    super.key,
  });

  final CodeScrollController scrollController;
  final ValueNotifier<CodeIndicatorValue?> paragraphs;
  final String source;
  final int offset;
  final KDictationState state;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      paragraphs,
      scrollController.verticalScroller,
      scrollController.horizontalScroller,
    ]),
    builder: (context, _) {
      final before = source.substring(0, offset.clamp(0, source.length));
      final line = '\n'.allMatches(before).length;
      final column = before.length - before.lastIndexOf('\n') - 1;
      CodeLineRenderParagraph? paragraph;
      for (final candidate
          in paragraphs.value?.paragraphs ?? <CodeLineRenderParagraph>[]) {
        if (candidate.index == line) paragraph = candidate;
      }
      final caret = paragraph?.getOffset(TextPosition(offset: column));
      if (paragraph == null || caret == null) return const SizedBox.shrink();
      final vertical = scrollController.verticalScroller;
      final horizontal = scrollController.horizontalScroller;
      final position =
          caret +
          paragraph.offset -
          Offset(
            horizontal.hasClients ? horizontal.offset : 0,
            vertical.hasClients ? vertical.offset : 0,
          );
      return Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            height: paragraph.preferredLineHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: KDictationAnchor(state: state),
            ),
          ),
        ],
      );
    },
  );
}
