part of 'k_symbol_picker.dart';

class _SymbolPickerAnchor extends StatefulWidget {
  const _SymbolPickerAnchor({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.builder,
    required this.width,
    required this.height,
    this.open,
    this.onOpenChange,
    this.triggerContent,
  });
  final String label;
  final KIconName icon;
  final bool enabled;
  final double width, height;
  final bool? open;
  final ValueChanged<bool>? onOpenChange;
  final Widget? triggerContent;
  final Widget Function(VoidCallback close, FocusNode searchFocus) builder;
  @override
  State<_SymbolPickerAnchor> createState() => _SymbolPickerAnchorState();
}

class _SymbolPickerAnchorState extends State<_SymbolPickerAnchor> {
  final _portal = OverlayPortalController();
  final _focus = FocusNode();
  final _searchFocus = FocusNode();
  final _scope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  bool _localOpen = false;
  Widget? _panel;
  bool get _open => widget.enabled && (widget.open ?? _localOpen);

  @override
  void initState() {
    super.initState();
    // Prepare only this picker's visible viewport after the trigger's first
    // frame. The portal stays mounted, but hidden content is inert.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _portal.show();
      if (_open) _focusSearch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _panel = null;
  }

  @override
  void didUpdateWidget(covariant _SymbolPickerAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _panel = null;
    final wasOpen = oldWidget.enabled && (oldWidget.open ?? _localOpen);
    if (!wasOpen && _open) _focusSearch();
    if (wasOpen && !_open) _focus.requestFocus();
  }

  void _focusSearch() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _open) _searchFocus.requestFocus();
  });

  void _change(bool open) {
    if (!widget.enabled || open == _open) return;
    if (widget.open == null) setState(() => _localOpen = open);
    widget.onOpenChange?.call(open);
    if (open) {
      _portal.show(); // Bring this picker above other prepared portals.
      _focusSearch();
    } else {
      Tooltip.dismissAllToolTips();
      _focus.requestFocus();
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _searchFocus.dispose();
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _panel ??= widget.builder(() => _change(false), _searchFocus);
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: (context, info) {
        final scale = info.childPaintTransform.getMaxScaleOnAxis();
        final anchor = MatrixUtils.transformRect(
          info.childPaintTransform,
          Offset.zero & info.childSize,
        );
        final media = MediaQuery.of(context);
        final availableHeight = math.max(
          0.0,
          info.overlaySize.height - media.viewInsets.bottom * scale,
        );
        final width = math
            .min(
              widget.width,
              math.min(
                media.size.width - 16,
                info.overlaySize.width / scale - 16,
              ),
            )
            .clamp(0.0, double.infinity);
        final height = math
            .min(
              widget.height,
              math.min(media.size.height - 16, availableHeight / scale - 16),
            )
            .clamp(0.0, double.infinity);
        final edge = 8 * scale;
        final x = anchor.left.clamp(
          edge,
          math.max(edge, info.overlaySize.width - width * scale - edge),
        );
        final below = anchor.bottom + 4 * scale;
        final y =
            (below + height * scale <= availableHeight - edge
                    ? below
                    : anchor.top - height * scale - 4 * scale)
                .clamp(
                  edge,
                  math.max(edge, availableHeight - height * scale - edge),
                );
        return Stack(
          children: [
            if (_open)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTap: () => _change(false),
                ),
              ),
            Positioned(
              key: const ValueKey('symbol-picker-panel'),
              left: x.toDouble(),
              top: y.toDouble(),
              width: width * scale,
              height: height * scale,
              child: Offstage(
                offstage: !_open,
                child: TickerMode(
                  enabled: _open,
                  child: ExcludeFocus(
                    excluding: !_open,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: FocusScope(node: _scope, child: _panel!),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: Semantics(
        expanded: _open,
        child: widget.triggerContent == null
            ? KActionControl(
                label: widget.label,
                icon: widget.icon,
                iconOnly: true,
                focusNode: _focus,
                onPressed: widget.enabled ? () => _change(!_open) : null,
              )
            : TextButton(
                focusNode: _focus,
                onPressed: widget.enabled ? () => _change(!_open) : null,
                child: Semantics(
                  label: widget.label,
                  excludeSemantics: true,
                  child: widget.triggerContent,
                ),
              ),
      ),
    );
  }
}
