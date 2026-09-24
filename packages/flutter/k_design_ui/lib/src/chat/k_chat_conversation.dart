import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_components.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import 'k_agent_parts.dart';
import 'k_chat_markdown.dart';
import 'k_chat_types.dart';

typedef KChatPartRenderer =
    Widget? Function(
      BuildContext context,
      KChatMessagePart part,
      KChatMessageValue message,
    );

typedef KChatAvatarBuilder =
    Widget? Function(
      BuildContext context,
      KChatMessageValue message,
      String author,
    );

enum KChatMessageMetadataMode { always, grouped, hidden }

class KChatLabels {
  const KChatLabels({
    this.emptyTitle = 'Start a conversation',
    this.emptyDescription = 'Send a message to begin.',
    this.loadOlder = 'Load earlier messages',
    this.newContent = 'Jump to newest message',
    this.assistant = 'Assistant',
    this.user = 'You',
    this.system = 'System',
    this.sending = 'Sending…',
    this.sent = 'Sent',
    this.failed = 'Not sent',
  });
  final String emptyTitle;
  final String emptyDescription;
  final String loadOlder;
  final String newContent;
  final String assistant;
  final String user;
  final String system;
  final String sending;
  final String sent;
  final String failed;
}

class KChatConversation extends StatefulWidget {
  const KChatConversation({
    required this.messages,
    this.runState = KChatRunState.idle,
    this.hasOlder = false,
    this.loadingOlder = false,
    this.onLoadOlder,
    this.labels = const KChatLabels(),
    this.emptyState,
    this.renderPart,
    this.renderMessageActions,
    this.toolRenderers = const {},
    this.onLinkActivate,
    this.onApprovalResponse,
    this.onQuestionResponse,
    this.onAttachmentActivate,
    this.onSourceActivate,
    this.onArtifactActivate,
    this.formatTimestamp,
    this.metadataMode = KChatMessageMetadataMode.always,
    this.metadataByRole = const {},
    this.showTimestamps = true,
    this.avatarBuilder,
    super.key,
  });
  final List<KChatMessageValue> messages;
  final KChatRunState runState;
  final bool hasOlder;
  final bool loadingOlder;
  final VoidCallback? onLoadOlder;
  final KChatLabels labels;
  final Widget? emptyState;
  final KChatPartRenderer? renderPart;
  final Widget? Function(BuildContext context, KChatMessageValue message)?
  renderMessageActions;
  final Map<String, KAgentToolRenderer> toolRenderers;
  final ValueChanged<Uri>? onLinkActivate;
  final ValueChanged<KAgentApprovalResponse>? onApprovalResponse;
  final ValueChanged<KAgentQuestionResponse>? onQuestionResponse;
  final ValueChanged<KChatAttachmentPart>? onAttachmentActivate;
  final ValueChanged<KAgentSourcePart>? onSourceActivate;
  final ValueChanged<KAgentArtifactPart>? onArtifactActivate;
  final String Function(DateTime value)? formatTimestamp;
  final KChatMessageMetadataMode metadataMode;
  final Map<KChatRole, KChatMessageMetadataMode> metadataByRole;
  final bool showTimestamps;
  final KChatAvatarBuilder? avatarBuilder;

  @override
  State<KChatConversation> createState() => _KChatConversationState();
}

class _KChatConversationState extends State<KChatConversation> {
  final _scroll = ScrollController();
  bool _following = true;
  bool _showNewest = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd(jump: true));
  }

  @override
  void didUpdateWidget(covariant KChatConversation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages != widget.messages && _following) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final following = _scroll.position.extentAfter < 32;
    if (following == _following) return;
    setState(() {
      _following = following;
      _showNewest = !following;
    });
  }

  void _jumpToEnd({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    _following = true;
    if (jump || MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: Theme.of(context).extension<KDesignTokens>()!.motionFast,
        curve: Curves.easeOut,
      );
    }
    if (_showNewest && mounted) setState(() => _showNewest = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final entries = widget.messages.length + (widget.hasOlder ? 1 : 0);
    return Stack(
      children: [
        Semantics(
          liveRegion: true,
          child: widget.messages.isEmpty && !widget.hasOlder
              ? widget.emptyState ?? _EmptyState(labels: widget.labels)
              : ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.all(t.spaceLayoutGutter),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: entries,
                  itemBuilder: (context, index) {
                    if (widget.hasOlder && index == 0) {
                      return Align(
                        child: KButton(
                          label: widget.labels.loadOlder,
                          loading: widget.loadingOlder,
                          variant: KButtonVariant.ghost,
                          onPressed: widget.onLoadOlder,
                        ),
                      );
                    }
                    final messageIndex = index - (widget.hasOlder ? 1 : 0);
                    final message = widget.messages[messageIndex];
                    final previous = messageIndex > 0
                        ? widget.messages[messageIndex - 1]
                        : null;
                    final author = _authorFor(message);
                    final startsGroup =
                        previous == null ||
                        previous.role != message.role ||
                        _authorFor(previous) != author;
                    final metadataMode =
                        widget.metadataByRole[message.role] ??
                        widget.metadataMode;
                    final showMetadata =
                        metadataMode == KChatMessageMetadataMode.always ||
                        (metadataMode == KChatMessageMetadataMode.grouped &&
                            startsGroup);
                    return Padding(
                      padding: EdgeInsets.only(bottom: t.spaceLayoutSectionGap),
                      child: _Message(
                        message: message,
                        labels: widget.labels,
                        author: author,
                        showMetadata: showMetadata,
                        showTimestamp: widget.showTimestamps,
                        avatarBuilder: widget.avatarBuilder,
                        formatTimestamp: widget.formatTimestamp,
                        actions: widget.renderMessageActions?.call(
                          context,
                          widget.messages[messageIndex],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final part
                                in widget.messages[messageIndex].parts)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: t.spaceControlGap,
                                ),
                                child:
                                    widget.renderPart?.call(
                                      context,
                                      part,
                                      widget.messages[messageIndex],
                                    ) ??
                                    _buildPart(context, part),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_showNewest)
          PositionedDirectional(
            bottom: t.spaceLayoutGutter,
            start: t.spaceLayoutGutter,
            end: t.spaceLayoutGutter,
            child: Center(
              child: KButton(
                label: widget.labels.newContent,
                leading: const KIcon(KIconName.arrowDown),
                variant: KButtonVariant.secondary,
                onPressed: _jumpToEnd,
              ),
            ),
          ),
      ],
    );
  }

  String _authorFor(KChatMessageValue message) =>
      message.authorLabel ??
      switch (message.role) {
        KChatRole.user => widget.labels.user,
        KChatRole.assistant => widget.labels.assistant,
        KChatRole.system => widget.labels.system,
      };

  Widget _buildPart(BuildContext context, KChatMessagePart part) {
    if (part is KChatTextPart) {
      return KChatMarkdown(
        text: part.text,
        streaming: part.streaming,
        onLinkActivate: widget.onLinkActivate,
      );
    }
    if (part is KChatAttachmentPart) {
      return KAttachment(
        title: Text(part.title),
        description: part.description == null ? null : Text(part.description!),
        state: switch (part.state) {
          KChatAttachmentPartState.ready => KAttachmentState.ready,
          KChatAttachmentPartState.uploading => KAttachmentState.uploading,
          KChatAttachmentPartState.processing => KAttachmentState.processing,
          KChatAttachmentPartState.error => KAttachmentState.error,
          KChatAttachmentPartState.complete => KAttachmentState.complete,
        },
        progress: part.progress,
        onActivate: widget.onAttachmentActivate == null
            ? null
            : () => widget.onAttachmentActivate!(part),
      );
    }
    if (part is KAgentToolPart) {
      return KAgentToolCall(
        part: part,
        renderer: widget.toolRenderers[part.toolName],
      );
    }
    if (part is KAgentApprovalPart) {
      return KAgentApproval(part: part, onResponse: widget.onApprovalResponse);
    }
    if (part is KAgentQuestionPart) {
      return KAgentQuestion(part: part, onResponse: widget.onQuestionResponse);
    }
    if (part is KAgentTaskPart) return KAgentTaskGroup(part: part);
    if (part is KAgentActivityPart) return KAgentActivity(part: part);
    if (part is KAgentSourcePart) {
      return KAgentReference(
        title: part.title,
        description: part.description,
        onActivate: widget.onSourceActivate == null
            ? null
            : () => widget.onSourceActivate!(part),
      );
    }
    if (part is KAgentArtifactPart) {
      return KAgentReference(
        title: part.title,
        description: part.description,
        artifact: true,
        onActivate: widget.onArtifactActivate == null
            ? null
            : () => widget.onArtifactActivate!(part),
      );
    }
    return KAgentStatus(part: part as KAgentStatusPart);
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.message,
    required this.labels,
    required this.child,
    required this.author,
    required this.showMetadata,
    required this.showTimestamp,
    this.actions,
    this.formatTimestamp,
    this.avatarBuilder,
  });
  final KChatMessageValue message;
  final KChatLabels labels;
  final Widget child;
  final String author;
  final bool showMetadata;
  final bool showTimestamp;
  final Widget? actions;
  final String Function(DateTime value)? formatTimestamp;
  final KChatAvatarBuilder? avatarBuilder;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final status = switch (message.status) {
      KChatMessageStatus.sending => labels.sending,
      KChatMessageStatus.sent => labels.sent,
      KChatMessageStatus.failed => labels.failed,
      null => null,
    };
    final textOnly = message.parts.every((part) => part is KChatTextPart);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMetadata || (showTimestamp && message.timestamp != null)) ...[
          Row(
            mainAxisAlignment: message.role == KChatRole.user
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (showMetadata)
                Text(author, style: TextStyle(fontWeight: t.fontLabelWeight)),
              if (showTimestamp && message.timestamp != null) ...[
                SizedBox(width: t.spaceControlGap),
                Text(
                  formatTimestamp?.call(message.timestamp!) ??
                      TimeOfDay.fromDateTime(
                        message.timestamp!,
                      ).format(context),
                  style: TextStyle(
                    color: t.colorTextMuted,
                    fontSize: t.fontCaptionSize,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: t.spaceControlGap),
        ],
        if (textOnly)
          LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: message.role == KChatRole.user
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.88,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: t.spaceControlInsetInline,
                  vertical: t.spaceControlGap,
                ),
                decoration: BoxDecoration(
                  color: message.role == KChatRole.user
                      ? t.colorBrandPrimaryBackground
                      : t.colorSurfaceRaised,
                  border: Border.all(
                    color: message.role == KChatRole.user
                        ? t.colorBrandPrimaryBorder
                        : t.colorBorderDefault,
                  ),
                  borderRadius: BorderRadius.circular(t.radiusCard),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: message.role == KChatRole.user
                        ? t.colorBrandPrimaryForeground
                        : t.colorTextPrimary,
                  ),
                  child: child,
                ),
              ),
            ),
          )
        else
          child,
        if (status != null) ...[
          SizedBox(height: t.spaceControlGap),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              status,
              style: TextStyle(
                color: message.status == KChatMessageStatus.failed
                    ? t.colorStatusErrorForeground
                    : t.colorTextMuted,
                fontSize: t.fontCaptionSize,
              ),
            ),
          ),
        ],
        if (actions != null) ...[SizedBox(height: t.spaceControlGap), actions!],
      ],
    );
    final avatar = showMetadata
        ? avatarBuilder == null
              ? KAvatar(alt: author, size: KAvatarSize.small)
              : avatarBuilder!(context, message, author)
        : null;
    return Semantics(
      label: author,
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.role == KChatRole.user
            ? [
                Expanded(child: body),
                if (avatar != null) ...[
                  SizedBox(width: t.spaceControlGap),
                  avatar,
                ],
              ]
            : [
                if (avatar != null) ...[
                  avatar,
                  SizedBox(width: t.spaceControlGap),
                ],
                Expanded(child: body),
              ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.labels});
  final KChatLabels labels;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KIcon(
            KIconName.info,
            size: t.sizeAvatarLarge,
            color: t.colorTextMuted,
          ),
          SizedBox(height: t.spaceControlGap),
          Text(
            labels.emptyTitle,
            style: TextStyle(
              fontSize: t.fontHeading5Size,
              fontWeight: t.fontHeadingWeight,
            ),
          ),
          Text(
            labels.emptyDescription,
            style: TextStyle(color: t.colorTextMuted),
          ),
        ],
      ),
    );
  }
}
