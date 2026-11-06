import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../actions/k_menu_button.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../localization/k_localization.dart';
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
  Widget? _back;
  List<Widget> _actions = const [];

  String? get title => _title;
  GlobalKey? get anchor => _anchor;

  /// The page header's back control; the bar keeps it while scrolled.
  Widget? get back => _back;

  /// The page header's actions; the bar keeps them while scrolled.
  List<Widget> get actions => _actions;

  void register(
    String title,
    GlobalKey anchor, {
    Widget? back,
    List<Widget> actions = const [],
  }) {
    _title = title;
    _anchor = anchor;
    _back = back;
    _actions = actions;
    notifyListeners();
  }

  void unregister(GlobalKey anchor) {
    if (anchor != _anchor) return;
    _title = null;
    _anchor = null;
    _back = null;
    _actions = const [];
    notifyListeners();
  }
}

/// Reports the page title of a [KPageHeader] to the nearest bar.
class KTopBarTitleAnchor extends StatefulWidget {
  const KTopBarTitleAnchor({
    required this.title,
    required this.child,
    this.back,
    this.actions = const [],
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? back;
  final List<Widget> actions;

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
    if (oldWidget.title != widget.title ||
        oldWidget.back != widget.back ||
        oldWidget.actions != widget.actions) {
      _register();
    }
  }

  void _register() {
    final controller = _controller;
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.register(
          widget.title,
          _anchor,
          back: widget.back,
          actions: widget.actions,
        );
      }
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

/// Where a page's primary action goes on phones (Decision 0015).
enum KPrimaryActionPlacement {
  /// Material: extended floating action button; Apple and linear: an icon
  /// in the top bar.
  auto,

  /// An icon in the top bar (iOS navigation bar).
  bar,

  /// An extended floating action button above the tab bar (Material 3).
  fab,
}

/// The top bar of phone screens (Decision 0015), as the iOS navigation bar
/// and the Material 3 top app bar work:
///
/// - It always holds the page header's back control and actions, so they
///   never scroll away and never appear twice. The page header then shows
///   only the large title.
/// - At the top it is transparent; once content scrolls under it, it gets
///   glass (Apple) or a tonal surface, and the inline title fades in when
///   the large title has scrolled away.
/// - The page's primary action becomes an icon in the bar or an extended
///   floating action button ([placement]).
///
/// [KAppShell] places it on phones; screens outside the shell can wrap
/// their scroll view in it.
class KScrollTopBar extends StatefulWidget {
  const KScrollTopBar({
    required this.child,
    this.placement = KPrimaryActionPlacement.auto,
    super.key,
  });
  final Widget child;
  final KPrimaryActionPlacement placement;

  @override
  State<KScrollTopBar> createState() => _KScrollTopBarState();
}

class _KScrollTopBarState extends State<KScrollTopBar> {
  final _controller = KTopBarTitleController();
  final _bar = GlobalKey();
  bool _scrolled = false;
  bool _titleShown = false;
  bool _fabExtended = true;
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      final scrolled =
          notification.metrics.pixels > notification.metrics.minScrollExtent;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
      // Material: the extended FAB shrinks to its icon while scrolling down.
      if (notification is UserScrollNotification) {
        final extended =
            notification.direction != ScrollDirection.reverse || !scrolled;
        if (extended != _fabExtended) {
          setState(() => _fabExtended = extended);
        }
      }
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
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final title = _controller.title;
    final back = _controller.back;
    final placement = switch (widget.placement) {
      KPrimaryActionPlacement.auto =>
        style == KStyle.material
            ? KPrimaryActionPlacement.fab
            : KPrimaryActionPlacement.bar,
      final other => other,
    };
    final split = _splitActions(
      _controller.actions,
      KLocalization.of(context).text('moreActions'),
      fab: placement == KPrimaryActionPlacement.fab,
    );
    // The bar row takes space only when it holds controls; a top-level
    // screen keeps its large title right under the status bar.
    final hasControls = back != null || split.bar.isNotEmpty;
    final barHeight = t.componentTopBarHeight;
    final fab = split.primary;
    final fabReserve = fab == null
        ? 0.0
        : t.componentFabHeight + t.spaceLayoutGutter;

    final row = SizedBox(
      height: barHeight,
      child: Row(
        children: [
          if (back case final control?) ...[
            control,
            SizedBox(width: t.spaceTight),
          ],
          Expanded(
            child: ExcludeSemantics(
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
          ...split.bar,
        ],
      ),
    );
    Widget background = AnimatedOpacity(
      opacity: _scrolled ? 1 : 0,
      duration: motion.settle,
      curve: motion.curve,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Same glass as the tab bar.
          color: apple
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
        child: const SizedBox.expand(),
      ),
    );
    if (apple) {
      background = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _scrolled ? t.componentMobileAppBarGlassNativeBlur : 0,
            sigmaY: _scrolled ? t.componentMobileAppBarGlassNativeBlur : 0,
          ),
          child: background,
        ),
      );
    }
    final bar = KeyedSubtree(
      key: _bar,
      child: SizedBox(
        height: top + barHeight,
        child: Stack(
          children: [
            Positioned.fill(child: IgnorePointer(child: background)),
            Padding(
              padding: EdgeInsets.only(
                top: top,
                left: t.spaceLayoutGutter + media.padding.left,
                right: t.spaceLayoutGutter + media.padding.right,
              ),
              child: row,
            ),
          ],
        ),
      ),
    );
    return KTopBarTitleScope(
      controller: _controller,
      child: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              // Content starts below the bar's controls and ends above the
              // floating action button.
              data: media.copyWith(
                padding: media.padding.copyWith(
                  top: top + (hasControls ? barHeight : 0),
                  bottom: media.padding.bottom + fabReserve,
                ),
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: widget.child,
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: bar),
          if (fab case final action?)
            PositionedDirectional(
              end: t.spaceLayoutGutter + media.padding.right,
              bottom: t.spaceLayoutGutter + media.padding.bottom,
              child: _KExtendedFab(action: action, extended: _fabExtended),
            ),
        ],
      ),
    );
  }
}

/// A page action converted for the bar or the FAB.
class _BarAction {
  const _BarAction({required this.label, required this.onPressed, this.icon});
  final String label;
  final KIconName? icon;
  final VoidCallback? onPressed;
}

class _SplitActions {
  const _SplitActions(this.bar, this.primary);
  final List<Widget> bar;
  final _BarAction? primary;
}

/// Distributes the page header's actions (Decision 0015):
///
/// - the first primary [KButton] is the primary action: an extended FAB
///   when [fab], else an icon in the bar (its label becomes the tooltip);
/// - icon buttons stay in the bar, at most two;
/// - text buttons, further actions and the entries of a page's own overflow
///   menu share one More menu, so the bar never shows two of them.
_SplitActions _splitActions(
  List<Widget> actions,
  String moreLabel, {
  required bool fab,
}) {
  if (actions.isEmpty) return const _SplitActions([], null);
  final visible = <Widget>[];
  final menu = <KMenuAction>[];
  _BarAction? primary;
  KIconName? iconOf(KButton button) =>
      button.leading is KIcon ? (button.leading! as KIcon).name : null;
  for (final (index, action) in actions.indexed) {
    if (action is KButton &&
        primary == null &&
        action.variant == KButtonVariant.primary) {
      final icon = iconOf(action);
      if (fab) {
        primary = _BarAction(
          label: action.label,
          icon: icon,
          onPressed: action.onPressed,
        );
        continue;
      }
      if (icon != null && visible.length < 2) {
        visible.add(
          KIconButton(
            label: action.label,
            icon: icon,
            onPressed: action.onPressed,
          ),
        );
        continue;
      }
    }
    if (action is KIconButton && visible.length < 2) {
      visible.add(action);
    } else if (action is KIconButton) {
      menu.add(
        KMenuAction(
          id: '$index',
          label: action.label,
          icon: action.icon,
          onSelect: action.onPressed,
          disabled: action.onPressed == null,
        ),
      );
    } else if (action is KButton) {
      menu.add(
        KMenuAction(
          id: '$index',
          label: action.label,
          icon: iconOf(action),
          onSelect: action.onPressed,
          disabled: action.onPressed == null,
        ),
      );
    } else if (action is KMenuButton && action.overflow) {
      // The page's own More menu merges into the bar's.
      menu.addAll(action.actions);
    } else if (action is KOverflowMenu) {
      menu.addAll(action.actions);
    } else if (visible.length < 2) {
      visible.add(action);
    }
  }
  return _SplitActions([
    ...visible,
    if (menu.isNotEmpty)
      KMenuButton(label: moreLabel, overflow: true, actions: menu),
  ], primary);
}

/// Material 3 extended FAB; it shrinks to its icon while content scrolls
/// down and extends again on the way up.
class _KExtendedFab extends StatelessWidget {
  const _KExtendedFab({required this.action, required this.extended});
  final _BarAction action;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final motion = t.motion(KMotionRole.control);
    final showLabel = extended || action.icon == null;
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.componentFabRadius),
          boxShadow: t.elevationMedium,
        ),
        child: Material(
          color: t.componentFabBackground,
          borderRadius: BorderRadius.circular(t.componentFabRadius),
          child: InkWell(
            onTap: action.onPressed,
            borderRadius: BorderRadius.circular(t.componentFabRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: t.componentFabHeight,
                minWidth: t.componentFabHeight,
              ),
              child: AnimatedSize(
                duration: motion.settle,
                curve: motion.curve,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: showLabel ? t.spaceLayoutGutter : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (action.icon case final icon?)
                        KIcon(icon, color: t.componentFabForeground),
                      if (showLabel) ...[
                        if (action.icon != null) SizedBox(width: t.spaceTight),
                        KText(
                          action.label,
                          variant: KTextVariant.label,
                          maxLines: 1,
                          style: TextStyle(color: t.componentFabForeground),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
