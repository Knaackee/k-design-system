import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../markdown/k_markdown_renderer.dart';
import '../markdown/k_markdown_options.dart';

/// Chat composition of the shared renderer; the host owns actions and images.
class KChatMarkdown extends StatelessWidget {
  const KChatMarkdown({
    required this.text,
    this.streaming = false,
    this.onLinkActivate,
    this.markdownOptions = const KMarkdownOptions(),
    this.allowedElements,
    super.key,
  });

  final String text;
  final bool streaming;
  final ValueChanged<Uri>? onLinkActivate;
  final KMarkdownOptions markdownOptions;
  final Set<String>? allowedElements;

  @override
  Widget build(BuildContext context) {
    final inputMode =
        KAdaptive.maybeOf(context)?.inputMode ??
        resolveKAdaptiveConfiguration(
          width: MediaQuery.sizeOf(context).width,
          platform: Theme.of(context).platform,
        ).inputMode;
    return KMarkdownRenderer(
      content: text,
      profile: KMarkdownProfile.chat,
      streaming: streaming,
      onLinkActivate: onLinkActivate ?? markdownOptions.onLinkActivate,
      imageBuilder: markdownOptions.imageBuilder,
      allowedElements: allowedElements ?? markdownOptions.allowedElements,
      // Keep one-finger drag available to the parent chat on touch.
      selectable: markdownOptions.selectable ?? inputMode == KInputMode.pointer,
      onCopy: markdownOptions.onCopy,
      copyLabel: markdownOptions.copyLabel,
      tableLabel: markdownOptions.tableLabel,
      completedTaskLabel: markdownOptions.completedTaskLabel,
      incompleteTaskLabel: markdownOptions.incompleteTaskLabel,
      alertLabels: markdownOptions.alertLabels,
    );
  }
}
