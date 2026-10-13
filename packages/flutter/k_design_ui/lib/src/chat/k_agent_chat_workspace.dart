import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_animated_icon.dart';
import '../primitives/k_icon.dart';
import '../overlays/k_popover.dart';
import '../overlays/k_overlays.dart';
part 'k_agent_chat_identity.dart';
part 'k_agent_chat_right_sidebar.dart';

typedef KAgentChatWorkspaceSidebarBuilder =
    Widget Function(
      BuildContext context,
      KAgentChatWorkspaceSidebarControls controls,
    );

class KAgentChatWorkspaceSidebarControls {
  const KAgentChatWorkspaceSidebarControls({required this.close});

  final VoidCallback close;
}

class KAgentChatWorkspaceLabels {
  const KAgentChatWorkspaceLabels({
    this.agents = 'Agents',
    this.closeAgents = 'Close agents',
  });

  final String agents;
  final String closeAgents;
}

/// Full-screen, responsive composition for an agent conversation.
///
/// The consumer owns agents, sessions, messages, drafts, and actions. This
/// pattern only owns the responsive desktop sidebar and mobile drawer shell.
class KAgentChatWorkspace extends StatefulWidget {
  const KAgentChatWorkspace({
    required this.avatar,
    required this.title,
    required this.conversation,
    required this.composer,
    this.dockBuilder,
    this.dockMaximized = false,
    this.sidebar,
    this.sidebarBuilder,
    this.status,
    this.conversationHeader,
    this.actions,
    this.avatarSizeMobile = 80,
    this.avatarSizeDesktop = 104,
    this.avatarSizeCompact = 52,
    this.avatarBackdropBlur = 12,
    this.avatarTransitionDuration,
    this.showTitle = false,
    this.conversationEmpty = false,
    this.avatarSizeEmpty = 240,
    this.avatarLabel,
    this.avatarPopover,
    this.avatarPopoverLabel = 'Account and usage',
    this.contentMaxWidth = 920,
    this.rightSidebar,
    this.rightSidebarOpen = false,
    this.rightSidebarWidth,
    this.rightSidebarTitle = 'Details',
    this.onRightSidebarOpenChange,
    this.sidebarCollapsed,
    this.defaultSidebarCollapsed = false,
    this.onSidebarCollapsedChanged,
    this.sidebarToggleBuilder,
    this.labels = const KAgentChatWorkspaceLabels(),
    super.key,
  }) : assert(
         (sidebar == null) != (sidebarBuilder == null),
         'Provide exactly one of sidebar or sidebarBuilder.',
       );

  static const desktopBreakpoint = 768.0;
  static const desktopSidebarWidth = 280.0;

  final Widget? sidebar;
  final KAgentChatWorkspaceSidebarBuilder? sidebarBuilder;
  final Widget avatar;
  final Widget title;
  final Widget? status;

  /// Consumer call/session strip below the toolbar and above the avatar stage.
  final Widget? conversationHeader;
  final Widget? actions;
  final double avatarSizeMobile, avatarSizeDesktop, avatarSizeCompact;
  final double avatarBackdropBlur;
  final Duration? avatarTransitionDuration;

  /// Hide the visual heading while retaining the conversation identity for AT.
  final bool showTitle;
  final bool conversationEmpty;
  final double avatarSizeEmpty;
  final Widget? avatarLabel, avatarPopover;
  final String avatarPopoverLabel;
  final double contentMaxWidth;
  final Widget? rightSidebar;
  final bool rightSidebarOpen;
  final double? rightSidebarWidth;
  final String rightSidebarTitle;
  final ValueChanged<bool>? onRightSidebarOpenChange;
  final bool? sidebarCollapsed;
  final bool defaultSidebarCollapsed;
  final ValueChanged<bool>? onSidebarCollapsedChanged;
  final Widget Function(
    BuildContext context,
    bool collapsed,
    VoidCallback toggle,
  )?
  sidebarToggleBuilder;
  final Widget conversation;
  final Widget composer;

  /// Mounted between the scrolling conversation and composer. The supplied
  /// height is the available workspace height, including the dock itself.
  final Widget Function(BuildContext context, double availableHeight)?
  dockBuilder;
  final bool dockMaximized;
  final KAgentChatWorkspaceLabels labels;

  @override
  State<KAgentChatWorkspace> createState() => _KAgentChatWorkspaceState();
}

class _KAgentChatWorkspaceState extends State<KAgentChatWorkspace> {
  final _avatarPopoverAnchor = GlobalKey();
  final _rightContent = ValueNotifier<Widget>(const SizedBox.shrink());
  BuildContext? _rightRouteContext;
  bool _rightSheetOpen = false;
  bool _rightSyncScheduled = false;
  @override
  void didUpdateWidget(covariant KAgentChatWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rightContent.value = widget.rightSidebar ?? const SizedBox.shrink();
  }

  @override
  void dispose() {
    if (_rightSheetOpen) {
      final routeContext = _rightRouteContext;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (routeContext?.mounted == true) Navigator.of(routeContext!).pop();
      });
    } else {
      _rightContent.dispose();
    }
    super.dispose();
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late bool _internalCollapsed = widget.defaultSidebarCollapsed;
  bool get _collapsed => widget.sidebarCollapsed ?? _internalCollapsed;
  void _toggleSidebar() {
    final next = !_collapsed;
    setState(() => _internalCollapsed = next);
    widget.onSidebarCollapsedChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    // Scaffold removes the consumed IME inset from its body's MediaQuery.
    // Capture keyboard visibility here, even on tall screens whose remaining
    // viewport still exceeds the compact-height breakpoint.
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop =
            constraints.maxWidth >= KAgentChatWorkspace.desktopBreakpoint;
        final rightDocked = constraints.maxWidth >= 1024;
        _scheduleRightSidebar(rightDocked);
        final body = SafeArea(
          child: desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedContainer(
                      key: const ValueKey('k-agent-chat-workspace-sidebar'),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : tokens.motionEmphasis,
                      curve: Curves.easeInOut,
                      width: _collapsed || widget.dockMaximized
                          ? 0
                          : KAgentChatWorkspace.desktopSidebarWidth,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: KAgentChatWorkspace.desktopSidebarWidth,
                          maxWidth: KAgentChatWorkspace.desktopSidebarWidth,
                          child: ExcludeSemantics(
                            excluding: _collapsed || widget.dockMaximized,
                            child: ExcludeFocus(
                              excluding: _collapsed || widget.dockMaximized,
                              child: IgnorePointer(
                                ignoring: _collapsed || widget.dockMaximized,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      height:
                                          tokens.sizeHitTarget +
                                          tokens.spaceControlGap,
                                    ),
                                    Expanded(child: _sidebar(context)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _chat(
                        desktop: true,
                        keyboardVisible: keyboardVisible,
                      ),
                    ),
                    if (rightDocked && widget.rightSidebar != null)
                      _dockedRightSidebar(context),
                  ],
                )
              : _chat(desktop: false, keyboardVisible: keyboardVisible),
        );
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: tokens.colorSurfaceCanvas,
          drawer: desktop
              ? null
              : Drawer(
                  shape: const RoundedRectangleBorder(),
                  width: math.min(
                    KAgentChatWorkspace.desktopSidebarWidth,
                    constraints.maxWidth,
                  ),
                  backgroundColor: tokens.colorSurfaceRaised,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Padding(
                            padding: EdgeInsets.all(tokens.spaceControlGap),
                            child: KIconButton(
                              label: widget.labels.closeAgents,
                              icon: KIconName.x,
                              onPressed: _closeAgents,
                            ),
                          ),
                        ),
                        Expanded(child: _sidebar(context)),
                      ],
                    ),
                  ),
                ),
          body: body,
        );
      },
    );
  }

  Widget _chat({
    required bool desktop,
    required bool keyboardVisible,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final tokens = Theme.of(context).extension<KDesignTokens>()!;
      final compact = constraints.maxHeight < 620 || keyboardVisible;
      final avatarSize = compact
          ? widget.avatarSizeCompact
          : desktop
          ? widget.avatarSizeDesktop
          : widget.avatarSizeMobile;
      final reducedMotion = MediaQuery.disableAnimationsOf(context);
      return Column(
        children: [
          Offstage(
            offstage: widget.dockMaximized,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      widget.contentMaxWidth + 2 * tokens.spaceLayoutGutter,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLayoutGutter,
                    tokens.spaceControlGap,
                    tokens.spaceLayoutGutter + tokens.spaceControlGap,
                    tokens.spaceControlGap,
                  ),
                  child: Row(
                    children: [
                      widget.sidebarToggleBuilder != null && desktop
                          ? widget.sidebarToggleBuilder!(
                              context,
                              _collapsed,
                              _toggleSidebar,
                            )
                          : KIconButton(
                              key: const ValueKey(
                                'k-agent-chat-workspace-agents',
                              ),
                              label: desktop && !_collapsed
                                  ? widget.labels.closeAgents
                                  : widget.labels.agents,
                              icon: KIconName.arrowRight,
                              iconContent: KAnimatedIcon(
                                desktop && !_collapsed
                                    ? KIconName.arrowLeft
                                    : KIconName.arrowRight,
                              ),
                              onPressed: () => desktop
                                  ? _toggleSidebar()
                                  : _scaffoldKey.currentState?.openDrawer(),
                            ),
                      if (widget.actions case final actions?)
                        Expanded(
                          child: ExcludeFocus(
                            excluding: widget.dockMaximized,
                            child: actions,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ?widget.conversationHeader,
          Expanded(
            child: Offstage(
              offstage: widget.dockMaximized,
              child: LayoutBuilder(
                builder: (context, stage) {
                  final duration = reducedMotion
                      ? Duration.zero
                      : widget.avatarTransitionDuration ?? tokens.motionLong;
                  final targetSize = widget.conversationEmpty && !compact
                      ? math.min(
                          widget.avatarSizeEmpty,
                          math.min(
                            stage.maxWidth * .6,
                            MediaQuery.sizeOf(context).height * .4,
                          ),
                        )
                      : avatarSize;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          child: SizedBox(
                            width: math.min(
                              stage.maxWidth,
                              widget.contentMaxWidth +
                                  2 * tokens.spaceLayoutGutter,
                            ),
                            height: stage.maxHeight,
                            child: ExcludeFocus(
                              excluding: widget.dockMaximized,
                              child: widget.conversation,
                            ),
                          ),
                        ),
                      ),
                      if (!widget.showTitle)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: 0,
                              alwaysIncludeSemantics: true,
                              child: Semantics(
                                header: true,
                                child: widget.title,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: widget.avatarPopover == null,
                          child: AnimatedAlign(
                            alignment: widget.conversationEmpty
                                ? Alignment.center
                                : Alignment.topCenter,
                            duration: duration,
                            curve: Curves.easeInOut,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: targetSize),
                              duration: duration,
                              curve: Curves.easeInOut,
                              child: widget.avatar,
                              builder: (context, size, avatar) => ExcludeFocus(
                                excluding: widget.dockMaximized,
                                child: _floatingIdentity(
                                  context,
                                  size,
                                  avatar!,
                                  duration,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (widget.dockBuilder != null)
            Align(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.dockMaximized
                      ? constraints.maxWidth
                      : widget.contentMaxWidth + 2 * tokens.spaceLayoutGutter,
                ),
                child: widget.dockBuilder!(context, constraints.maxHeight),
              ),
            ),
          Offstage(
            offstage: widget.dockMaximized,
            child: ColoredBox(
              color: tokens.colorSurfaceCanvas,
              child: Align(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        widget.contentMaxWidth + 2 * tokens.spaceLayoutGutter,
                  ),
                  child: ExcludeFocus(
                    excluding: widget.dockMaximized,
                    child: widget.composer,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _sidebar(BuildContext context) =>
      widget.sidebarBuilder?.call(
        context,
        KAgentChatWorkspaceSidebarControls(close: _closeAgents),
      ) ??
      widget.sidebar!;

  void _closeAgents() {
    final scaffold = _scaffoldKey.currentState;
    if (scaffold?.isDrawerOpen ?? false) scaffold!.closeDrawer();
  }
}
