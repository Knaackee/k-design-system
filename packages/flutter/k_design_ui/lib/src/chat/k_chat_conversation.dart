import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_components.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import 'k_agent_parts.dart';
import 'k_agent_ask_tools.dart';
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
    this.approvalNote = 'Add a note (optional)',
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
  final String approvalNote;
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
    this.contentPadding,
    this.renderPart,
    this.renderMessageActions,
    this.toolRenderers = const {},
    this.onLinkActivate,
    this.onApprovalResponse,
    this.onQuestionResponse,
    this.onFormResponse,
    this.onExternalAction,
    this.onAttachmentRequest,
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

  /// Insets inside the message list that scroll with its content.
  /// Empty-state content retains its own consumer-controlled spacing.
  final EdgeInsetsGeometry? contentPadding;
  final KChatPartRenderer? renderPart;
  final Widget? Function(BuildContext context, KChatMessageValue message)?
  renderMessageActions;
  final Map<String, KAgentToolRenderer> toolRenderers;
  final ValueChanged<Uri>? onLinkActivate;
  final ValueChanged<KAgentApprovalResponse>? onApprovalResponse;
  final ValueChanged<KAgentQuestionResponse>? onQuestionResponse;
  final ValueChanged<KAgentFormResponse>? onFormResponse;
  final ValueChanged<KAgentExternalActionResponse>? onExternalAction;
  final ValueChanged<KAgentAttachmentRequestResponse>? onAttachmentRequest;
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
  double? _viewportDimension;
  bool _jumpScheduled = false;
  bool _adjustingFocusedField = false;
  int _scrollIntent = 0;
  bool _userScrolling = false;

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
      _scheduleJumpToEnd();
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
    if (_adjustingFocusedField) return;
    final position = _scroll.position;
    final viewportChanged =
        _viewportDimension != null &&
        _viewportDimension != position.viewportDimension;
    _viewportDimension = position.viewportDimension;
    if (viewportChanged) {
      if (!_userScrolling) _scheduleFocusedFieldIntoView();
      if (!_userScrolling &&
          _focusedScrollableContext() == null &&
          _following) {
        _scheduleJumpToEnd();
      }
      return;
    }
    final following = position.extentAfter < 32;
    // Content growth and our own animation must not cancel follow mode.
    if (!following && !_userScrolling) return;
    if (following == _following) return;
    setState(() {
      _following = following;
      _showNewest = !following;
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _scrollIntent++;
      _userScrolling = true;
    } else if (notification is ScrollEndNotification) {
      _userScrolling = false;
    } else if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      _scrollIntent++;
      _userScrolling = true;
      _onScroll();
    }
    return false;
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final previousViewport = _viewportDimension;
    _viewportDimension = notification.metrics.viewportDimension;
    if (_userScrolling) return false;
    final focusedContext = _focusedScrollableContext();
    if (focusedContext != null &&
        previousViewport != null &&
        notification.metrics.viewportDimension < previousViewport) {
      _scheduleFocusedFieldIntoView();
    } else if (_following) {
      _scheduleJumpToEnd();
    }
    return false;
  }

  void _scheduleJumpToEnd() {
    if (_jumpScheduled) return;
    _jumpScheduled = true;
    final intent = _scrollIntent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpScheduled = false;
      if (mounted &&
          intent == _scrollIntent &&
          !_userScrolling &&
          _following &&
          _focusedScrollableContext() == null) {
        // Streaming content changes the target continuously; animate only an
        // explicit jump requested by the user.
        _jumpToEnd(jump: true);
      }
    });
  }

  void _scheduleFocusedFieldIntoView() {
    final context = _focusedScrollableContext();
    if (context == null || _userScrolling) return;
    final intent = _scrollIntent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !context.mounted ||
          _userScrolling ||
          intent != _scrollIntent) {
        return;
      }
      _adjustingFocusedField = true;
      Scrollable.ensureVisible(context, alignment: 1, duration: Duration.zero);
      _adjustingFocusedField = false;
    });
  }

  BuildContext? _focusedScrollableContext() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null || !_scroll.hasClients) return null;
    var belongsToConversation = false;
    BuildContext target = context;
    context.visitAncestorElements((element) {
      if (element.widget is TextField) target = element;
      if (element is StatefulElement &&
          element.state is ScrollableState &&
          (element.state as ScrollableState).position == _scroll.position) {
        belongsToConversation = true;
        return false;
      }
      return true;
    });
    return belongsToConversation ? target : null;
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
        duration: Theme.of(
          context,
        ).extension<KDesignTokens>()!.motion(KMotionRole.control).settle,
        curve: Theme.of(
          context,
        ).extension<KDesignTokens>()!.motion(KMotionRole.control).curve,
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
        Positioned.fill(
          child: Semantics(
            liveRegion: true,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: const {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.invertedStylus,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: widget.messages.isEmpty && !widget.hasOlder
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(t.spaceLayoutGutter),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                widget.emptyState ??
                                    _EmptyState(labels: widget.labels),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : NotificationListener<ScrollMetricsNotification>(
                      onNotification: _onMetrics,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: ListView.builder(
                          controller: _scroll,
                          padding:
                              widget.contentPadding ??
                              EdgeInsets.all(t.spaceLayoutGutter),
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
                            final messageIndex =
                                index - (widget.hasOlder ? 1 : 0);
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
                                metadataMode ==
                                    KChatMessageMetadataMode.always ||
                                (metadataMode ==
                                        KChatMessageMetadataMode.grouped &&
                                    startsGroup);
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: t.spaceLayoutSectionGap,
                              ),
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
                                  crossAxisAlignment:
                                      message.parts.every(
                                        (part) => part is KChatTextPart,
                                      )
                                      ? CrossAxisAlignment.start
                                      : CrossAxisAlignment.stretch,
                                  children: _buildMessageParts(
                                    context,
                                    widget.messages[messageIndex],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (_showNewest)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.all(t.spaceControlGap),
              child: Center(
                child: KButton(
                  label: widget.labels.newContent,
                  leading: const KIcon(KIconName.arrowDown),
                  variant: KButtonVariant.secondary,
                  onPressed: _jumpToEnd,
                ),
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

  List<Widget> _buildMessageParts(
    BuildContext context,
    KChatMessageValue message,
  ) {
    final children = <Widget>[];
    final t = Theme.of(context).extension<KDesignTokens>()!;
    for (var index = 0; index < message.parts.length; index++) {
      final part = message.parts[index];
      Widget? content;
      if (widget.renderPart == null &&
          part is KAgentToolPart &&
          !widget.toolRenderers.containsKey(part.toolName)) {
        bool canGroup(KChatMessagePart candidate) =>
            candidate is KAgentToolPart &&
            candidate.toolName == part.toolName &&
            candidate.error == null &&
            candidate.state != KAgentToolState.failed &&
            candidate.state != KAgentToolState.approvalRequired;
        if (canGroup(part)) {
          final group = <KAgentToolPart>[part];
          while (index + 1 < message.parts.length &&
              canGroup(message.parts[index + 1])) {
            group.add(message.parts[++index] as KAgentToolPart);
          }
          if (group.length > 1) content = KAgentToolGroup(parts: group);
        }
      }
      children.add(
        Padding(
          key: ValueKey(part.id),
          padding: EdgeInsets.only(
            bottom: index < message.parts.length - 1 ? t.spaceControlGap : 0,
          ),
          child:
              content ??
              widget.renderPart?.call(context, part, message) ??
              _buildPart(context, part),
        ),
      );
    }
    return children;
  }

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
      return KAgentApproval(
        part: part,
        reasonLabel: widget.labels.approvalNote,
        onResponse: widget.onApprovalResponse,
      );
    }
    if (part is KAgentQuestionPart) {
      return KAgentQuestion(part: part, onResponse: widget.onQuestionResponse);
    }
    if (part is KAgentFormPart) {
      return KAgentForm(part: part, onResponse: widget.onFormResponse);
    }
    if (part is KAgentExternalActionPart) {
      return KAgentExternalAction(
        part: part,
        onResponse: widget.onExternalAction,
      );
    }
    if (part is KAgentAttachmentRequestPart) {
      return KAgentAttachmentRequest(
        part: part,
        onResponse: widget.onAttachmentRequest,
      );
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
    final avatar = showMetadata
        ? avatarBuilder == null
              ? KAvatar(alt: author, size: KAvatarSize.small)
              : avatarBuilder!(context, message, author)
        : null;
    final textOnly = message.parts.every((part) => part is KChatTextPart);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMetadata || (showTimestamp && message.timestamp != null)) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: message.role == KChatRole.user
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (showMetadata)
                Text(
                  author,
                  style: TextStyle(
                    fontWeight: t.fontLabelWeight,
                    fontSize: t.fontCaptionSize,
                  ),
                ),
              if (showTimestamp && message.timestamp != null) ...[
                if (showMetadata) SizedBox(width: t.spaceControlGap),
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
        if (textOnly && (message.role != KChatRole.assistant || avatar != null))
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
                  color: t.colorSurfaceRaised,
                  border: Border.all(color: t.colorBorderDefault),
                  borderRadius: BorderRadius.circular(t.radiusCard),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: t.colorTextPrimary),
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
            alignment: message.role == KChatRole.user
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: t.fontHeading5Size,
              fontWeight: t.fontHeadingWeight,
            ),
          ),
          Text(
            labels.emptyDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.colorTextMuted),
          ),
        ],
      ),
    );
  }
}
