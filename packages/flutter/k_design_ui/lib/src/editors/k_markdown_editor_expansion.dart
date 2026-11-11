part of 'k_markdown_editor.dart';

extension _MarkdownEditorExpansion on KMarkdownEditorState {
  void _moveSurface(bool expanded) {
    // Web's detachment traversal skips old siblings after a reparented node.
    // Retire the old semantics tree for one frame, preserving the live editor.
    _rebuild(() {
      _movingSurface = kIsWeb;
      _expanded = expanded;
    });
    if (!kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _movingSurface) {
        _rebuild(() => _movingSurface = false);
      }
    });
  }

  void _toggleExpanded() {
    if (_expanded) {
      _expandedRoute?.navigator?.pop();
      return;
    }
    final theme = InheritedTheme.capture(
      from: context,
      to: Navigator.of(context).context,
    );
    final route = RawDialogRoute<void>(
      requestFocus: false,
      barrierDismissible: false,
      transitionDuration: Duration.zero,
      pageBuilder: (routeContext, _, _) => theme.wrap(
        PopScope<void>(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop && mounted) {
              _expandedRoute = null;
              _moveSurface(false);
            }
          },
          child: ValueListenableBuilder<int>(
            valueListenable: _surfaceRevision,
            builder: (context, _, _) => !_expanded
                ? const SizedBox.shrink()
                : SafeArea(
                    child: KDialog(
                      title: KText(widget.semanticLabel),
                      closeLabel: widget.collapseLabel,
                      onClose: _toggleExpanded,
                      maxWidth: double.infinity,
                      maxHeight: MediaQuery.sizeOf(context).height,
                      expandBody: true,
                      child: _buildAccessibleSurface(context),
                    ),
                  ),
          ),
        ),
      ),
    );
    _expandedRoute = route;
    _moveSurface(true);
    Navigator.of(context).push(route);
  }
}
