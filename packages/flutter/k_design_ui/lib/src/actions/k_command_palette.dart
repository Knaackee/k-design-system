import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../forms/k_input.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_surface.dart';
import 'k_command_palette_types.dart';
import 'k_icon_button.dart';

export 'k_command_palette_types.dart';

part 'k_command_palette_parts.dart';

typedef KCommandPaletteItemBuilder =
    Widget Function(
      BuildContext context,
      KCommandPaletteItem item,
      bool active,
    );

class KCommandPalette extends StatefulWidget {
  const KCommandPalette({
    required this.items,
    required this.onCommand,
    required this.onClose,
    this.labels = const KCommandPaletteLabels(),
    this.query,
    this.defaultQuery = '',
    this.onQueryChanged,
    this.onActiveItemChanged,
    this.onPageChanged,
    this.loading = false,
    this.loop = true,
    this.itemBuilder,
    super.key,
  });

  final List<KCommandPaletteItem> items;
  final KCommandPaletteCallback onCommand;
  final VoidCallback onClose;
  final KCommandPaletteLabels labels;
  final String? query;
  final String defaultQuery;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<String>? onActiveItemChanged;
  final ValueChanged<List<KCommandPaletteItem>>? onPageChanged;
  final bool loading;
  final bool loop;
  final KCommandPaletteItemBuilder? itemBuilder;

  static Future<KCommandPaletteItem?> show({
    required BuildContext context,
    required List<KCommandPaletteItem> items,
    required KCommandPaletteCallback onCommand,
    KCommandPaletteLabels labels = const KCommandPaletteLabels(),
    String defaultQuery = '',
    ValueChanged<String>? onQueryChanged,
    ValueChanged<String>? onActiveItemChanged,
    ValueChanged<List<KCommandPaletteItem>>? onPageChanged,
    bool loading = false,
    bool loop = true,
    KCommandPaletteItemBuilder? itemBuilder,
  }) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return showGeneralDialog<KCommandPaletteItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: labels.close,
      barrierColor: tokens.colorScrimModal,
      transitionDuration: tokens.motionStandard,
      pageBuilder: (routeContext, animation, secondaryAnimation) {
        final compact = MediaQuery.sizeOf(routeContext).width < 600;
        return SafeArea(
          child: Align(
            alignment: compact ? Alignment.center : const Alignment(0, -.2),
            child: Padding(
              padding: compact
                  ? EdgeInsets.zero
                  : EdgeInsets.all(tokens.spaceLayoutGutter),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact
                      ? double.infinity
                      : tokens.layoutContentWidth,
                  maxHeight: compact
                      ? double.infinity
                      : MediaQuery.sizeOf(routeContext).height * .8,
                ),
                child: KCommandPalette(
                  items: items,
                  onCommand: (item) async {
                    await onCommand(item);
                    if (item.closeOnInvoke && routeContext.mounted) {
                      Navigator.of(routeContext).pop(item);
                    }
                  },
                  onClose: () => Navigator.of(routeContext).pop(),
                  labels: labels,
                  defaultQuery: defaultQuery,
                  onQueryChanged: onQueryChanged,
                  onActiveItemChanged: onActiveItemChanged,
                  onPageChanged: onPageChanged,
                  loading: loading,
                  loop: loop,
                  itemBuilder: itemBuilder,
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: .98, end: 1.0).animate(animation),
              child: child,
            ),
          ),
    );
  }

  @override
  State<KCommandPalette> createState() => _KCommandPaletteState();
}

class _KCommandPaletteState extends State<KCommandPalette> {
  late final TextEditingController _queryController;
  late final FocusNode _queryFocus;
  final _pages = <KCommandPaletteItem>[];
  int _activeIndex = 0;
  String? _executingId;

  String get _query => widget.query ?? _queryController.text;
  List<KCommandPaletteItem> get _currentItems =>
      _pages.isEmpty ? widget.items : _pages.last.children;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(
      text: widget.query ?? widget.defaultQuery,
    );
    _queryFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _queryFocus.requestFocus(),
    );
  }

  @override
  void didUpdateWidget(covariant KCommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != null && widget.query != _queryController.text) {
      _queryController.value = TextEditingValue(
        text: widget.query!,
        selection: TextSelection.collapsed(offset: widget.query!.length),
      );
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  List<KCommandPaletteItem> get _matches {
    final terms = _query.trim().toLowerCase().split(RegExp(r'\s+'));
    final result = _currentItems.where((item) {
      if (terms.length == 1 && terms.first.isEmpty) return true;
      final haystack = [
        item.label,
        item.description ?? '',
        ...item.keywords,
      ].join(' ').toLowerCase();
      return terms.every(haystack.contains);
    }).toList();
    result.sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

  void _setQuery(String value) {
    if (widget.query == null && _queryController.text != value) {
      _queryController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    setState(() => _activeIndex = 0);
    widget.onQueryChanged?.call(value);
    final matches = _matches;
    if (matches.isNotEmpty) widget.onActiveItemChanged?.call(matches.first.id);
  }

  void _move(int delta) {
    final matches = _matches;
    if (matches.isEmpty) return;
    var next = _activeIndex;
    do {
      next += delta;
      if (widget.loop) next = (next + matches.length) % matches.length;
      if (!widget.loop && (next < 0 || next >= matches.length)) return;
    } while (matches[next].disabled);
    setState(() => _activeIndex = next);
    widget.onActiveItemChanged?.call(matches[next].id);
  }

  void _back() {
    if (_pages.isEmpty) {
      widget.onClose();
      return;
    }
    setState(() {
      _pages.removeLast();
      _activeIndex = 0;
    });
    _setQuery('');
    widget.onPageChanged?.call(List.unmodifiable(_pages));
  }

  Future<void> _invoke(KCommandPaletteItem item) async {
    if (item.disabled || _executingId != null) return;
    if (item.children.isNotEmpty) {
      setState(() {
        _pages.add(item);
        _activeIndex = 0;
      });
      _setQuery('');
      widget.onPageChanged?.call(List.unmodifiable(_pages));
      return;
    }
    setState(() => _executingId = item.id);
    try {
      await widget.onCommand(item);
    } finally {
      if (mounted) setState(() => _executingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final matches = _matches;
    if (_activeIndex >= matches.length) _activeIndex = 0;
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Material(
      color: Colors.transparent,
      child: KSurface(
        radius: compact ? KSurfaceRadius.none : KSurfaceRadius.overlay,
        elevation: compact ? KSurfaceElevation.none : KSurfaceElevation.overlay,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
            const SingleActivator(LogicalKeyboardKey.escape): _back,
            const SingleActivator(LogicalKeyboardKey.enter): () {
              if (matches.isNotEmpty) unawaited(_invoke(matches[_activeIndex]));
            },
          },
          child: Column(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _Header(
                title: _pages.isEmpty ? widget.labels.title : _pages.last.label,
                closeLabel: widget.labels.close,
                onClose: widget.onClose,
              ),
              _Search(
                controller: _queryController,
                focusNode: _queryFocus,
                placeholder: widget.labels.searchPlaceholder,
                backLabel: widget.labels.back,
                showBack: _pages.isNotEmpty,
                loading: widget.loading,
                onBack: _back,
                onChanged: _setQuery,
              ),
              Flexible(
                child: widget.loading
                    ? _StateLabel(widget.labels.loading)
                    : matches.isEmpty
                    ? _StateLabel(widget.labels.empty)
                    : ListView.builder(
                        padding: EdgeInsets.all(t.spaceControlGap),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final item = matches[index];
                          final previousGroup = index == 0
                              ? null
                              : matches[index - 1].group;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.group != null &&
                                  item.group != previousGroup)
                                _GroupLabel(item.group!),
                              _CommandRow(
                                item: item,
                                active: index == _activeIndex,
                                executing: item.id == _executingId,
                                itemBuilder: widget.itemBuilder,
                                onHover: () {
                                  setState(() => _activeIndex = index);
                                  widget.onActiveItemChanged?.call(item.id);
                                },
                                onPressed: () => unawaited(_invoke(item)),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              if (!compact)
                _Footer(
                  navigate: widget.labels.navigate,
                  select: widget.labels.select,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
