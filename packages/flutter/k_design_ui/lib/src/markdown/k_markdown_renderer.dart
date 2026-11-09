import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/json.dart';

import '../basic_feedback.dart';
import '../forms/k_checkbox.dart';
import '../primitives/k_button.dart';
import 'markdown_streaming.dart';
import 'markdown_styles.dart';

part 'markdown_code_block.dart';

enum KMarkdownProfile { document, chat }

/// Token-driven Markdown. Navigation and clipboard writes belong to the host.
class KMarkdownRenderer extends StatefulWidget {
  const KMarkdownRenderer({
    required this.content,
    this.profile = KMarkdownProfile.document,
    this.streaming = false,
    this.allowedElements,
    this.onLinkActivate,
    this.imageBuilder,
    this.selectable = true,
    this.copyLabel = 'Copy',
    this.tableLabel = 'Table',
    this.completedTaskLabel = 'Completed',
    this.incompleteTaskLabel = 'Not completed',
    this.alertLabels = const {},
    this.onCopy,
    this.semanticLabel,
    super.key,
  });

  final String content;
  final KMarkdownProfile profile;

  /// Keeps unfinished blocks literal while incoming content is incomplete.
  final bool streaming;

  /// HTML tag names. Excluded wrappers are unwrapped; excluded images disappear.
  final Set<String>? allowedElements;
  final ValueChanged<Uri>? onLinkActivate;
  final Widget Function(Uri uri, String? alt, String? title)? imageBuilder;
  final bool selectable;
  final String copyLabel;
  final String tableLabel;
  final String completedTaskLabel;
  final String incompleteTaskLabel;
  final Map<String, String> alertLabels;
  final ValueChanged<String>? onCopy;
  final String? semanticLabel;

  @override
  State<KMarkdownRenderer> createState() => _KMarkdownRendererState();
}

class _KMarkdownRendererState extends State<KMarkdownRenderer>
    implements MarkdownBuilderDelegate {
  final _recognizers = <TapGestureRecognizer>[];
  List<md.Node>? _nodes;
  List<md.Node>? _preparedNodes;
  String? _parsedContent;
  late (String, String) _display;

  @override
  void initState() {
    super.initState();
    _updateDisplay();
  }

  @override
  void didUpdateWidget(KMarkdownRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.streaming != widget.streaming) {
      _updateDisplay();
    }
    if (!setEquals(oldWidget.allowedElements, widget.allowedElements)) {
      _preparedNodes = null;
    }
  }

  void _updateDisplay() {
    _display = widget.streaming
        ? splitStreamingMarkdown(widget.content)
        : (widget.content, '');
    if (_parsedContent == _display.$1) return;
    _parsedContent = _display.$1;
    _nodes = null;
    _preparedNodes = null;
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final uri = href == null ? null : Uri.tryParse(href);
    final onLinkActivate = widget.onLinkActivate;
    final recognizer = TapGestureRecognizer();
    if (onLinkActivate != null && uri != null && _safe(uri, link: true)) {
      recognizer.onTap = () => onLinkActivate(uri);
    }
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) =>
      TextSpan(text: code, style: styleSheet.code);

  List<md.Node> _prepare(List<md.Node> nodes, {bool insideList = false}) =>
      nodes.expand<md.Node>((node) {
        if (node is! md.Element) return [node];
        if (widget.allowedElements != null &&
            !widget.allowedElements!.contains(node.tag)) {
          return node.tag == 'img'
              ? <md.Node>[]
              : _prepare(node.children ?? [], insideList: insideList);
        }
        final isList = const {'ul', 'ol'}.contains(node.tag);
        final copy = md.Element(
          node.tag,
          _prepare(node.children ?? [], insideList: insideList || isList),
        );
        copy.attributes.addAll(node.attributes);
        if (isList && !insideList) {
          return [
            md.Element('klist', copy.children)
              ..attributes.addAll(copy.attributes)
              ..attributes['data-list-tag'] = node.tag,
          ];
        }
        if (node.tag == 'pre') {
          final block = md.Element('kcode', node.children);
          return [block];
        }
        if (node.tag == 'div' &&
            (node.attributes['class'] ?? '').contains('markdown-alert')) {
          final alert = md.Element('kalert', copy.children);
          alert.attributes.addAll(node.attributes);
          return [alert];
        }
        return [copy];
      }).toList();

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    _nodes ??= md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
      blockSyntaxes: [const _SkipHtmlBlock(), const md.AlertBlockSyntax()],
      inlineSyntaxes: [_SkipInlineHtml()],
    ).parseLines(const LineSplitter().convert(_display.$1));
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final style = markdownStyles(context, widget.profile);
    List<Widget> render(
      List<md.Node> nodes, {
      MarkdownStyleSheet? overrideStyle,
    }) => MarkdownBuilder(
      delegate: this,
      fitContent: widget.profile == KMarkdownProfile.chat,
      selectable: widget.selectable,
      styleSheet: overrideStyle ?? style,
      imageDirectory: null,
      imageBuilder: (uri, title, alt) {
        if (!_safe(uri)) return const SizedBox.shrink();
        return widget.imageBuilder?.call(uri, alt, title) ??
            ClipRRect(
              borderRadius: BorderRadius.circular(t.radiusCard),
              child: Image.network(
                uri.toString(),
                semanticLabel: alt,
                errorBuilder: (_, error, stack) =>
                    Text(alt ?? '', style: style.p),
              ),
            );
      },
      checkboxBuilder: (checked) => Semantics(
        label: checked ? widget.completedTaskLabel : widget.incompleteTaskLabel,
        child: SizedBox(
          height: math.max(
            t.sizeContent,
            MediaQuery.textScalerOf(context).scale(t.fontBodySize) *
                t.fontBodyLineHeight /
                t.fontBodySize,
          ),
          child: KCheckbox(label: '', value: checked, onChanged: null),
        ),
      ),
      bulletBuilder: null,
      builders: {
        'klist': _BlockBuilder((element) {
          final list = md.Element(
            element.attributes['data-list-tag']!,
            element.children,
          )..attributes.addAll(element.attributes);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: render([
              list,
            ], overrideStyle: style.copyWith(blockSpacing: t.spaceTight * 2)),
          );
        }),
        for (var level = 1; level <= 6; level++)
          'h$level': _BlockBuilder(
            (element) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: t.textScaleMaxHeading,
              child: Semantics(
                header: true,
                headingLevel: level,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: render([
                    md.Element('p', element.children),
                  ], overrideStyle: style.copyWith(p: style.styles['h$level'])),
                ),
              ),
            ),
          ),
        'kcode': _BlockBuilder(
          (element) => _CodeBlock(
            element: element,
            style: style.code!,
            tokens: t,
            selectable: widget.selectable,
            copyLabel: widget.copyLabel,
            onCopy: widget.onCopy,
          ),
        ),
        'kalert': _BlockBuilder((element) {
          final kind = (element.attributes['class'] ?? '')
              .split('markdown-alert-')
              .last;
          final children = element.children ?? [];
          return KAlert(
            title: Text(
              widget.alertLabels[kind.toUpperCase()] ?? kind.toUpperCase(),
            ),
            tone: switch (kind) {
              'tip' => KStatusTone.success,
              'warning' => KStatusTone.warning,
              'caution' => KStatusTone.error,
              _ => KStatusTone.info,
            },
            liveRegion: false,
            description: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: render(children.skip(1).toList()),
            ),
          );
        }),
      },
      paddingBuilders: const {},
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
      softLineBreak: false,
    ).build(nodes);
    final prepared = _preparedNodes ??= _prepare(_nodes!);
    final children = <Widget>[];
    for (var index = 0; index < prepared.length; index++) {
      final node = prepared[index];
      if (node is md.Element && node.tag == 'table' && widget.onCopy != null) {
        final rows = <String>[];
        void collect(md.Node current) {
          if (current is md.Element && current.tag == 'tr') {
            rows.add(
              (current.children ?? [])
                  .map((cell) => cell.textContent)
                  .join('\t'),
            );
          } else if (current is md.Element) {
            for (final child in current.children ?? <md.Node>[]) {
              collect(child);
            }
          }
        }

        collect(node);
        children.add(
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: KButton(
              label: widget.copyLabel,
              variant: KButtonVariant.ghost,
              onPressed: () => widget.onCopy!(rows.join('\n')),
            ),
          ),
        );
      }
      if (node is md.Element && node.tag == 'table') {
        children.add(
          Semantics(
            label: widget.tableLabel,
            child: _MarkdownTableScroll(
              child: render(
                [node],
                overrideStyle: style.copyWith(
                  // Preserve intrinsic widths while delegating scrolling to
                  // our wrapper, which supplies the viewport as minimum width.
                  tableColumnWidth: const MaxColumnWidth(
                    IntrinsicColumnWidth(),
                    FixedColumnWidth(0),
                  ),
                ),
              ).single,
            ),
          ),
        );
      } else {
        // The upstream builder expects block roots even for unwrapped text.
        children.addAll(
          render([
            node is md.Text ? md.Element('p', [node]) : node,
          ]),
        );
      }
      if (index < prepared.length - 1 || _display.$2.isNotEmpty) {
        final next = index < prepared.length - 1 ? prepared[index + 1] : null;
        final nextHeading =
            next is md.Element && RegExp(r'^h[1-6]$').hasMatch(next.tag);
        final currentHeading =
            node is md.Element && RegExp(r'^h[1-6]$').hasMatch(node.tag);
        children.add(
          SizedBox(
            height: nextHeading
                ? widget.profile == KMarkdownProfile.chat
                      ? t.spaceMediumInset
                      : t.spaceLayoutSectionGap
                : currentHeading
                ? t.spaceControlGap
                : style.blockSpacing,
          ),
        );
      }
    }
    if (_display.$2.isNotEmpty) {
      children.add(
        widget.selectable
            ? SelectableText(_display.$2, style: style.p)
            : Text(_display.$2, style: style.p),
      );
    }
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: t.textScaleMaxBody,
      child: Semantics(
        label: widget.semanticLabel,
        liveRegion: false,
        child: Column(
          crossAxisAlignment: widget.profile == KMarkdownProfile.chat
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

class _MarkdownTableScroll extends StatefulWidget {
  const _MarkdownTableScroll({required this.child});

  final Widget child;

  @override
  State<_MarkdownTableScroll> createState() => _MarkdownTableScrollState();
}

class _MarkdownTableScrollState extends State<_MarkdownTableScroll> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Scrollbar(
      controller: _controller,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.hasBoundedWidth ? constraints.maxWidth : 0,
          ),
          child: widget.child,
        ),
      ),
    ),
  );
}

bool _safe(Uri uri, {bool link = false}) =>
    uri.scheme.isEmpty ||
    {'http', 'https', if (link) 'mailto'}.contains(uri.scheme.toLowerCase());

class _SkipHtmlBlock extends md.HtmlBlockSyntax {
  const _SkipHtmlBlock();
  @override
  md.Node parse(md.BlockParser parser) {
    super.parse(parser);
    return md.Text('');
  }
}

class _SkipInlineHtml extends md.InlineHtmlSyntax {
  @override
  bool onMatch(md.InlineParser parser, Match match) => true;
}

class _BlockBuilder extends MarkdownElementBuilder {
  _BlockBuilder(this.builder);
  final Widget Function(md.Element) builder;
  @override
  bool isBlockElement() => true;
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => builder(element);
}
