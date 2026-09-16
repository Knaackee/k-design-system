import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Action-only wrapping toolbar with one tab stop and horizontal arrow navigation.
class KToolbar extends StatefulWidget {
  const KToolbar({required this.label, required this.children, super.key});
  static KeyEventResult handleNavigation(
    BuildContext context,
    KeyEvent event,
  ) =>
      context.findAncestorStateOfType<_KToolbarState>()?._navigate(event) ??
      KeyEventResult.ignored;
  final String label;
  final List<Widget> children;
  @override
  State<KToolbar> createState() => _KToolbarState();
}

class _KToolbarState extends State<KToolbar> {
  final _root = FocusNode(canRequestFocus: false, skipTraversal: true);
  final Map<FocusNode, bool> _original = {};
  FocusNode? _active;
  List<FocusNode> get _controls =>
      _root.descendants.where((node) => node.canRequestFocus).toList();
  KeyEventResult _navigate(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final nodes = _controls;
    final index = nodes.indexWhere((n) => n.hasPrimaryFocus);
    if (index < 0) return KeyEventResult.ignored;
    final key = event.logicalKey;
    int? next;
    if (key == LogicalKeyboardKey.home) next = 0;
    if (key == LogicalKeyboardKey.end) next = nodes.length - 1;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      final direction = Directionality.of(context) == TextDirection.rtl
          ? -1
          : 1;
      final delta = (key == LogicalKeyboardKey.arrowRight ? 1 : -1) * direction;
      next = (index + delta + nodes.length) % nodes.length;
    }
    if (next == null) return KeyEventResult.ignored;
    _active = nodes[next];
    _active!.requestFocus();
    return KeyEventResult.handled;
  }

  void _sync() {
    if (!mounted) return;
    final nodes = _controls;
    if (nodes.isEmpty) return;
    _active =
        nodes.where((node) => node.hasPrimaryFocus).firstOrNull ??
        (nodes.contains(_active) ? _active : nodes.first);
    for (final node in nodes) {
      _original.putIfAbsent(node, () => node.skipTraversal);
      node.skipTraversal = node != _active;
    }
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_sync);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_sync);
    for (final entry in _original.entries) {
      if (entry.key.context != null) entry.key.skipTraversal = entry.value;
    }
    _root.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    return Semantics(
      label: widget.label,
      container: true,
      child: Focus(
        focusNode: _root,
        onKeyEvent: (_, event) => _navigate(event),
        child: Wrap(
          spacing: t.spaceContentActionGap,
          runSpacing: t.spaceContentActionGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: widget.children,
        ),
      ),
    );
  }
}
