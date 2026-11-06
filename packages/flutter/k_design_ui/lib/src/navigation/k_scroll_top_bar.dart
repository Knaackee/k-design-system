import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../primitives/k_text.dart';

/// Lets a [KPageHeader] hand its title to the bar of the surrounding
/// [KScrollTopBar].
class KTopBarTitleScope extends InheritedWidget {
  const KTopBarTitleScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final KTopBarTitleController controller;

  static KTopBarTitleController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<KTopBarTitleScope>()
      ?.controller;

  @override
  bool updateShouldNotify(KTopBarTitleScope oldWidget) =>
      controller != oldWidget.controller;
}

/// The page title and where it is on screen.
class KTopBarTitleController extends ChangeNotifier {
  String? _title;
  GlobalKey? _anchor;

  String? get title => _title;
  GlobalKey? get anchor => _anchor;

  void register(String title, GlobalKey anchor) {
    if (title == _title && anchor == _anchor) return;
    _title = title;
    _anchor = anchor;
    notifyListeners();
  }

  void unregister(GlobalKey anchor) {
    if (anchor != _anchor) return;
    _title = null;
    _anchor = null;
    notifyListeners();
  }
}

/// Reports the page title of a [KPageHeader] to the nearest bar.
class KTopBarTitleAnchor extends StatefulWidget {
  const KTopBarTitleAnchor({
    required this.title,
    required this.child,
    super.key,
  });
  final String title;
  final Widget child;

  @override
  State<KTopBarTitleAnchor> createState() => _KTopBarTitleAnchorState();
}

class _KTopBarTitleAnchorState extends State<KTopBarTitleAnchor> {
  final _anchor = GlobalKey();
  KTopBarTitleController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = KTopBarTitleScope.maybeOf(context);
    if (controller != _controller) {
      _controller?.unregister(_anchor);
      _controller = controller;
    }
    _register();
  }

  @override
  void didUpdateWidget(KTopBarTitleAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) _register();
  }

  void _register() {
    final controller = _controller;
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.register(widget.title, _anchor);
    });
  }

  @override
  void dispose() {
    _controller?.unregister(_anchor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _anchor, child: widget.child);
}

/// The bar over scrolled content on phones (Decision 0015): invisible at the
/// top, it fades in under the status bar as soon as content scrolls under
/// it, and shows the page title once the large title has scrolled away
/// (iOS navigation bar, Material 3 top app bar on scroll).
///
/// [KAppShell] places it on phones; screens outside the shell can wrap
/// their scroll view in it.
class KScrollTopBar extends StatefulWidget {
  const KScrollTopBar({required this.child, super.key});
  final Widget child;

  @override
  State<KScrollTopBar> createState() => _KScrollTopBarState();
}

class _KScrollTopBarState extends State<KScrollTopBar> {
  final _controller = KTopBarTitleController();
  final _bar = GlobalKey();
  bool _scrolled = false;
  bool _titleShown = false;
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTitleChanged);
  }

  // Titles register while the tree builds or unmounts; measure after it.
  void _onTitleChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      _update();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final scrolled =
          notification.metrics.pixels > notification.metrics.minScrollExtent;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
      // Positions settle after this frame's layout.
      if (!_updateScheduled) {
        _updateScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateScheduled = false;
          _update();
        });
      }
    }
    return false;
  }

  void _update() {
    if (!mounted) return;
    final anchor = _controller.anchor?.currentContext?.findRenderObject();
    final bar = _bar.currentContext?.findRenderObject();
    var shown = false;
    if (_scrolled &&
        anchor is RenderBox &&
        anchor.attached &&
        bar is RenderBox &&
        bar.attached) {
      final titleBottom = anchor
          .localToGlobal(Offset(0, anchor.size.height))
          .dy;
      final barBottom = bar.localToGlobal(Offset(0, bar.size.height)).dy;
      shown = titleBottom <= barBottom;
    }
    if (shown != _titleShown && mounted) setState(() => _titleShown = shown);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final style = KAdaptive.maybeOf(context)?.style ?? KStyle.linear;
    final apple = style == KStyle.apple;
    final motion = t.motion(KMotionRole.control);
    final top = MediaQuery.paddingOf(context).top;
    final title = _controller.title;
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: apple
            // Same glass as the tab bar.
            ? t.colorSurfaceRaised.withValues(
                alpha: t.componentMobileAppBarOpacitySurface,
              )
            : t.colorSurfaceRaised,
        border: Border(
          bottom: BorderSide(
            color: t.colorBorderDefault,
            width: t.spaceHairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: top,
          left: t.spaceLayoutGutter,
          right: t.spaceLayoutGutter,
        ),
        child: SizedBox(
          height: t.componentTopBarHeight,
          child: AnimatedOpacity(
            opacity: _titleShown && title != null ? 1 : 0,
            duration: motion.settle,
            curve: motion.curve,
            child: Align(
              // iOS centres the inline title; Material starts it.
              alignment: apple
                  ? Alignment.center
                  : AlignmentDirectional.centerStart,
              child: KText(
                title ?? '',
                variant: KTextVariant.heading5,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
    if (apple) {
      surface = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: t.componentMobileAppBarGlassNativeBlur,
            sigmaY: t.componentMobileAppBarGlassNativeBlur,
          ),
          child: surface,
        ),
      );
    }
    return KTopBarTitleScope(
      controller: _controller,
      child: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.child,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_scrolled,
              child: AnimatedOpacity(
                opacity: _scrolled ? 1 : 0,
                duration: motion.settle,
                curve: motion.curve,
                // The page header keeps the title for assistive technology.
                child: ExcludeSemantics(
                  child: KeyedSubtree(key: _bar, child: surface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
