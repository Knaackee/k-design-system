part of 'k_agent_chat_workspace.dart';

extension _KAgentChatRightSidebar on _KAgentChatWorkspaceState {
  Widget _dockedRightSidebar(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final width =
        widget.rightSidebarWidth ?? KAgentChatWorkspace.desktopSidebarWidth;
    return AnimatedContainer(
      key: const ValueKey('k-agent-chat-workspace-right-sidebar'),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : tokens.motion(KMotionRole.control).settle,
      curve: tokens.motion(KMotionRole.control).curve,
      width: widget.rightSidebarOpen ? width : 0,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topRight,
          minWidth: width,
          maxWidth: width,
          child: ExcludeSemantics(
            excluding: !widget.rightSidebarOpen,
            child: ExcludeFocus(
              excluding: !widget.rightSidebarOpen,
              child: IgnorePointer(
                ignoring: !widget.rightSidebarOpen,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.colorSurfaceRaised,
                    border: Border(
                      left: BorderSide(
                        color: tokens.colorBorderDefault,
                        width: tokens.borderWidthDefault,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(tokens.spaceLayoutGutter),
                    child: widget.rightSidebar!,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleRightSidebar(bool docked) {
    if (_rightSyncScheduled) return;
    _rightSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rightSyncScheduled = false;
      if (!mounted) return;
      final shouldOpen =
          !docked && widget.rightSidebarOpen && widget.rightSidebar != null;
      if (!shouldOpen && _rightRouteContext?.mounted == true) {
        Navigator.of(_rightRouteContext!).pop();
      } else if (shouldOpen && !_rightSheetOpen) {
        _showRightSidebar();
      }
    });
  }

  Future<void> _showRightSidebar() async {
    _rightSheetOpen = true;
    _rightContent.value = widget.rightSidebar!;
    await KBottomSheet.show<void>(
      context: context,
      title: Text(widget.rightSidebarTitle),
      expandBody: true,
      child: Builder(
        builder: (routeContext) {
          _rightRouteContext = routeContext;
          if (!mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (routeContext.mounted) Navigator.of(routeContext).pop();
            });
          }
          return ValueListenableBuilder<Widget>(
            valueListenable: _rightContent,
            builder: (context, content, _) => SingleChildScrollView(
              padding: EdgeInsets.all(
                Theme.of(context).extension<KDesignTokens>()!.spaceLayoutGutter,
              ),
              child: content,
            ),
          );
        },
      ),
    );
    _rightRouteContext = null;
    _rightSheetOpen = false;
    if (!mounted) {
      _rightContent.dispose();
      return;
    }
    if (mounted &&
        widget.rightSidebarOpen &&
        MediaQuery.sizeOf(context).width < 1024) {
      widget.onRightSidebarOpenChange?.call(false);
    }
  }
}
